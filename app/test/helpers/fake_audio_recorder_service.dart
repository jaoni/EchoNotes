import 'dart:async';

import 'package:echonotes/features/recording/domain/audio_recorder_service.dart';

/// Pretends to record, and lets a test say what the microphone does.
///
/// With a [tick], it pretends time passes while it records: each tick adds
/// that much audio and a voice level. Without one, nothing happens until
/// the test calls [addAudio], [addLevel] or [send].
class FakeAudioRecorderService implements AudioRecorderService {
  FakeAudioRecorderService({this.tick});

  final Duration? tick;

  final _lengths = StreamController<Duration>.broadcast();
  final _levels = StreamController<double>.broadcast();
  final _events = StreamController<RecorderEvent>.broadcast();
  Timer? _ticker;

  /// Where the last recording went.
  String? path;
  var isRecording = false;
  var isDisposed = false;
  var length = Duration.zero;

  /// Every call, in order: `start`, `pause`, `resume` and `stop`.
  final calls = <String>[];

  /// When set, starting or resuming throws this instead.
  Object? startError;
  Object? resumeError;

  @override
  String get fileExtension => 'aac';

  @override
  int get bytesPerSecond => 4000;

  @override
  Stream<Duration> get recordedLength => _lengths.stream;

  @override
  Stream<double> get levels => _levels.stream;

  @override
  Stream<RecorderEvent> get events => _events.stream;

  @override
  Future<void> start(String path) async {
    calls.add('start');
    if (startError case final error?) throw error;
    this.path = path;
    length = Duration.zero;
    _record();
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    _stopRecording();
  }

  @override
  Future<void> resume() async {
    calls.add('resume');
    if (resumeError case final error?) throw error;
    _record();
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    _stopRecording();
  }

  @override
  Future<void> dispose() async {
    isDisposed = true;
    _stopRecording();
    await _lengths.close();
    await _levels.close();
    await _events.close();
  }

  /// Pretends [duration] more audio was recorded.
  void addAudio(Duration duration) {
    length += duration;
    _lengths.add(length);
  }

  /// Pretends the microphone heard [decibels].
  void addLevel(double decibels) => _levels.add(decibels);

  /// Pretends [event] happened. An interruption stops the pretend audio
  /// until it's resumed.
  void send(RecorderEvent event) {
    switch (event) {
      case RecorderEvent.interrupted:
      case RecorderEvent.outOfSpace:
      case RecorderEvent.writeFailed:
        _stopRecording();
      case RecorderEvent.resumed:
        _record();
    }
    _events.add(event);
  }

  void _record() {
    isRecording = true;
    final tick = this.tick;
    if (tick == null) return;
    _ticker?.cancel();
    _ticker = Timer.periodic(tick, (_) {
      addAudio(tick);
      addLevel(-20);
    });
  }

  void _stopRecording() {
    isRecording = false;
    _ticker?.cancel();
    _ticker = null;
  }
}
