import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:record/record.dart';

import 'package:echonotes/features/recording/data/adts.dart';
import 'package:echonotes/features/recording/data/recording_file_writer.dart';
import 'package:echonotes/features/recording/domain/audio_recorder_service.dart';

/// Records with the `record` package: mono AAC at 16 kHz and 32 kbps, about
/// 15 MB an hour, saved as ADTS frames (see `adts.dart`).
///
/// The package streams the encoded audio, and this class writes it to the
/// file itself. That keeps the file readable at every moment, and lets a
/// recording carry on in the same file after the package's recorder is
/// stopped and started again. It does that:
///
/// * on pause and resume: stopping lets go of the microphone, and every
///   start asks Android for audio focus again. Pausing and resuming the
///   package's recorder instead stops Android telling it about calls.
/// * when audio stops arriving without any event, as on iOS when
///   headphones or Bluetooth connect or disconnect.
class RecordAudioRecorderService implements AudioRecorderService {
  /// Only tests change [watchInterval].
  RecordAudioRecorderService({
    this._watchInterval = const Duration(milliseconds: 500),
  });

  static const _config = RecordConfig(
    encoder: AudioEncoder.aacLc,
    sampleRate: 16000,
    bitRate: 32000,
    numChannels: 1,
    // Pauses for a call or another app's audio, and carries on after.
    audioInterruption: AudioInterruptionMode.pauseResume,
    // The phone's own microphone, even with earbuds in: their microphones
    // only hear the wearer, and switch Bluetooth to low-quality call mode.
    androidConfig: AndroidRecordConfig(manageBluetooth: false),
    iosConfig: IosRecordConfig(
      categoryOptions: [
        IosAudioCategoryOption.defaultToSpeaker,
        IosAudioCategoryOption.allowBluetoothA2DP,
      ],
      // A ringing call doesn't interrupt; answering it does.
      allowHapticsAndSystemSoundsDuringRecording: true,
    ),
  );

  static const _levelInterval = Duration(milliseconds: 100);

  /// After how many checks without audio it restarts the recorder: three
  /// seconds.
  static const _quietChecksBeforeRestart = 6;

  /// Restarts in a row that brought no audio back before giving up.
  static const _maxRestarts = 3;

  /// "No space left on device", the same number on Android and iOS.
  static const _noSpaceErrorCode = 28;

  /// How often to check that audio is still arriving.
  final Duration _watchInterval;
  final _lengths = StreamController<Duration>.broadcast();
  final _levels = StreamController<double>.broadcast();
  final _events = StreamController<RecorderEvent>.broadcast();

  /// Made on first use, so nothing touches the microphone plugin before a
  /// recording starts.
  AudioRecorder? _recorder;
  StreamSubscription<RecordState>? _stateSubscription;
  StreamSubscription<Amplitude>? _levelSubscription;
  StreamSubscription<Uint8List>? _audioSubscription;

  var _wanted = _Wanted.stopped;

  /// The phone paused the recorder, for a call or another app.
  var _interrupted = false;
  RecordingFileWriter? _writer;
  var _splitter = AdtsFrameSplitter();
  var _length = Duration.zero;

  Timer? _watchdog;
  var _audioSinceLastCheck = false;
  var _quietChecks = 0;
  var _restarts = 0;
  var _restarting = false;

  /// The operations still to finish, one after the other.
  var _lock = Future<void>.value();

  @override
  String get fileExtension => 'aac';

  /// 32 kbps, plus 7 header bytes for each of about 16 frames a second.
  @override
  int get bytesPerSecond => 32000 ~/ 8 + 7 * 16;

  @override
  Stream<Duration> get recordedLength => _lengths.stream;

  @override
  Stream<double> get levels => _levels.stream;

  @override
  Stream<RecorderEvent> get events => _events.stream;

  @override
  Future<void> start(String path) => _oneAtATime(() => _start(path));

  @override
  Future<void> pause() => _oneAtATime(_pause);

  @override
  Future<void> resume() => _oneAtATime(_resume);

  @override
  Future<void> stop() => _oneAtATime(_stop);

  @override
  Future<void> dispose() async {
    await stop();
    await _lock;
    await _stateSubscription?.cancel();
    await _levelSubscription?.cancel();
    await _recorder?.dispose();
    await _lengths.close();
    await _levels.close();
    await _events.close();
  }

  /// Runs [action] once the ones before it have finished, so a stop can't
  /// land in the middle of a resume.
  Future<void> _oneAtATime(Future<void> Function() action) {
    final result = _lock.then((_) => action());
    _lock = result.catchError((Object _) {});
    return result;
  }

  Future<void> _start(String path) async {
    await _stop();
    _ensureRecorder();
    _writer = await RecordingFileWriter.open(
      path,
      append: false,
      onError: _onWriteFailed,
    );
    _splitter = AdtsFrameSplitter();
    _length = Duration.zero;
    _interrupted = false;
    _restarts = 0;

    try {
      await _startRecorder();
    } catch (_) {
      await _closeWriter();
      rethrow;
    }
    _wanted = _Wanted.recording;
    _lengths.add(_length);
    _startWatchdog();
  }

  Future<void> _pause() async {
    if (_wanted != _Wanted.recording) return;
    _wanted = _Wanted.paused;
    _interrupted = false;
    _stopWatchdog();
    await _stopRecorder();
  }

  Future<void> _resume() async {
    final isRunning = _wanted == _Wanted.recording && !_interrupted;
    if (_wanted == _Wanted.stopped || isRunning) return;

    // A fresh start, also after an interruption, so the phone hands over
    // the microphone (and Android its audio focus) again.
    await _stopRecorder();
    await _startRecorder();
    _wanted = _Wanted.recording;
    _interrupted = false;
    _restarts = 0;
    _startWatchdog();
  }

  Future<void> _stop() async {
    if (_wanted == _Wanted.stopped) return;
    _wanted = _Wanted.stopped;
    _interrupted = false;
    _stopWatchdog();
    await _stopRecorder();
    await _closeWriter();
  }

  void _ensureRecorder() {
    if (_recorder != null) return;
    final recorder = AudioRecorder();
    _recorder = recorder;
    _stateSubscription = recorder.onStateChanged().listen(
      _onRecorderState,
      onError: (Object error) => _log('The recorder reported an error', error),
    );
    _levelSubscription = recorder
        .onAmplitudeChanged(_levelInterval)
        .listen((amplitude) => _levels.add(amplitude.current));
  }

  Future<void> _startRecorder() async {
    final audio = await _recorder!.startStream(_config);
    _audioSubscription = audio.listen(_onAudio);
  }

  /// Stops the package's recorder. The file stays open.
  Future<void> _stopRecorder() async {
    try {
      await _recorder?.stop();
    } catch (error) {
      _log("Couldn't stop the recorder", error);
    }
    await _audioSubscription?.cancel();
    _audioSubscription = null;
  }

  Future<void> _closeWriter() async {
    final writer = _writer;
    _writer = null;
    try {
      await writer?.close();
    } catch (error) {
      _log("Couldn't finish writing the recording", error);
    }
  }

  void _onAudio(Uint8List bytes) {
    if (bytes.isEmpty) return;
    _audioSinceLastCheck = true;
    final frames = _splitter.add(bytes);
    if (frames.bytes.isEmpty) return;
    _writer?.write(frames.bytes);
    _length += frames.duration;
    _lengths.add(_length);
  }

  /// Events from the package, some of them late: only those that don't
  /// match what was asked for tell of an interruption.
  void _onRecorderState(RecordState state) {
    if (_wanted != _Wanted.recording || _restarting) return;
    if (state == RecordState.pause && !_interrupted) {
      _interrupted = true;
      _events.add(RecorderEvent.interrupted);
    } else if (state == RecordState.record && _interrupted) {
      _interrupted = false;
      _quietChecks = 0;
      _events.add(RecorderEvent.resumed);
    }
  }

  void _onWriteFailed(Object error) {
    _log("Couldn't write the recording", error);
    if (_wanted == _Wanted.stopped) return;
    final isFull =
        error is FileSystemException &&
        error.osError?.errorCode == _noSpaceErrorCode;
    unawaited(stop());
    _events.add(isFull ? RecorderEvent.outOfSpace : RecorderEvent.writeFailed);
  }

  void _startWatchdog() {
    _stopWatchdog();
    _audioSinceLastCheck = false;
    _quietChecks = 0;
    _watchdog = Timer.periodic(_watchInterval, (_) => _checkAudioArrives());
  }

  void _stopWatchdog() {
    _watchdog?.cancel();
    _watchdog = null;
  }

  void _checkAudioArrives() {
    if (_wanted != _Wanted.recording || _interrupted || _restarting) return;
    if (_audioSinceLastCheck) {
      _audioSinceLastCheck = false;
      _quietChecks = 0;
      _restarts = 0;
      return;
    }
    if (++_quietChecks >= _quietChecksBeforeRestart) {
      // Set now, so the next check doesn't line up a second restart.
      _restarting = true;
      unawaited(_oneAtATime(_restartRecorder));
    }
  }

  /// Starts the package's recorder again after audio stopped arriving,
  /// adding to the same file. After a few tries without audio it gives up
  /// and reports an interruption, so the user can resume by hand.
  Future<void> _restartRecorder() async {
    _quietChecks = 0;
    try {
      // Paused, stopped or interrupted while this waited its turn.
      if (_wanted != _Wanted.recording || _interrupted) return;
      if (++_restarts > _maxRestarts) throw StateError('No audio arrives.');
      _log('No audio for a while, so restarting the recorder');
      await _stopRecorder();
      if (_wanted != _Wanted.recording) return;
      await _startRecorder();
    } catch (error) {
      _log("Couldn't restart the recorder", error);
      if (_wanted == _Wanted.recording) {
        _interrupted = true;
        _events.add(RecorderEvent.interrupted);
      }
    } finally {
      _restarting = false;
    }
  }

  void _log(String message, [Object? error]) {
    developer.log(message, name: 'echonotes.recording', error: error);
  }
}

enum _Wanted { stopped, recording, paused }
