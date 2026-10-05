import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:record_platform_interface/record_platform_interface.dart';

import 'package:echonotes/features/recording/data/record_audio_recorder_service.dart';
import 'package:echonotes/features/recording/domain/audio_recorder_service.dart';

import '../../../helpers/adts_frames.dart';
import '../../../helpers/fake_record_platform.dart';

void main() {
  const frameLength = Duration(milliseconds: 64);
  const watchInterval = Duration(milliseconds: 10);

  late Directory folder;
  late String path;
  late FakeRecordPlatform platform;
  late RecordAudioRecorderService recorder;
  late List<Duration> lengths;
  late List<RecorderEvent> events;

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('echonotes_recorder_test');
    path = p.join(folder.path, 'note.aac');
    platform = FakeRecordPlatform();
    RecordPlatform.instance = platform;
    recorder = RecordAudioRecorderService(watchInterval: watchInterval);
    lengths = [];
    events = [];
    recorder.recordedLength.listen(lengths.add);
    recorder.events.listen(events.add);
  });

  tearDown(() async {
    await recorder.dispose();
    await folder.delete(recursive: true);
  });

  /// Lets the pretend audio reach the file.
  Future<void> settle() => pumpEventQueue();

  test('records mono AAC at 16 kHz and 32 kbps', () async {
    await recorder.start(path);

    final config = platform.config!;
    expect(config.encoder, AudioEncoder.aacLc);
    expect(config.sampleRate, 16000);
    expect(config.bitRate, 32000);
    expect(config.numChannels, 1);
    expect(config.audioInterruption, AudioInterruptionMode.pauseResume);
    expect(recorder.fileExtension, 'aac');
  });

  test('writes the audio to the file as it arrives, and counts it', () async {
    await recorder.start(path);

    // Android's setup data first, then real frames split across events.
    platform.sendAudio(adtsFrame(audioBytes: 2));
    final frames = adtsFrames(3);
    platform.sendAudio(frames.sublist(0, 30));
    platform.sendAudio(frames.sublist(30));
    await settle();

    expect(lengths.last, frameLength * 3);
    // Readable before stopping, as after a crash.
    expect(await File(path).readAsBytes(), frames);

    await recorder.stop();
    expect(await File(path).readAsBytes(), frames);
  });

  test(
    'pausing lets go of the microphone; resuming adds to the same file',
    () async {
      await recorder.start(path);
      platform.sendAudio(adtsFrames(2));
      await settle();

      await recorder.pause();
      expect(platform.isStreaming, isFalse);

      await recorder.resume();
      expect(platform.starts, 2);
      platform.sendAudio(adtsFrames(1));
      await settle();
      await recorder.stop();

      expect(lengths.last, frameLength * 3);
      expect(await File(path).readAsBytes(), adtsFrames(3));
    },
  );

  test('a new recording starts an empty file', () async {
    await File(path).writeAsBytes(adtsFrames(5));

    await recorder.start(path);
    platform.sendAudio(adtsFrames(1));
    await settle();
    await recorder.stop();

    expect(await File(path).readAsBytes(), adtsFrames(1));
  });

  test('tells of an interruption and of carrying on after it', () async {
    await recorder.start(path);

    platform.sendState(RecordState.pause);
    await settle();
    platform.sendState(RecordState.record);
    await settle();

    expect(events, [RecorderEvent.interrupted, RecorderEvent.resumed]);
  });

  test("the user's own pause is no interruption", () async {
    await recorder.start(path);

    await recorder.pause();
    platform.sendState(RecordState.pause);
    platform.sendState(RecordState.record);
    await settle();

    expect(events, isEmpty);
  });

  test('resuming after an interruption starts the recorder afresh', () async {
    await recorder.start(path);
    platform.sendState(RecordState.pause);
    await settle();

    await recorder.resume();

    expect(platform.starts, 2);
  });

  test('restarts the recorder when audio stops arriving', () async {
    await recorder.start(path);
    platform.sendAudio(adtsFrames(1));
    await settle();

    platform.goSilent();
    await Future<void>.delayed(watchInterval * 10);
    await settle();

    expect(platform.starts, 2);
    platform.sendAudio(adtsFrames(1));
    await settle();
    await recorder.stop();
    expect(await File(path).readAsBytes(), adtsFrames(2));
    expect(events, isEmpty);
  });

  test('reports an interruption when restarting keeps failing', () async {
    await recorder.start(path);
    platform
      ..startError = Exception('The microphone is busy')
      ..goSilent();

    await Future<void>.delayed(watchInterval * 10);
    await settle();

    expect(events, [RecorderEvent.interrupted]);
  });

  test('gives up after a few restarts that bring no audio back', () async {
    await recorder.start(path);

    platform.goSilent();
    for (var i = 0; i < 40 && events.isEmpty; i++) {
      await Future<void>.delayed(watchInterval * 2);
      // Each restart streams again, but nothing comes.
      if (platform.isStreaming) platform.goSilent();
    }

    expect(events, [RecorderEvent.interrupted]);
    expect(platform.starts, 4);
  });

  test('passes on why it could not start, and records nothing', () async {
    platform.startError = Exception('The microphone is busy');

    await expectLater(recorder.start(path), throwsException);

    platform.startError = null;
    await recorder.stop();
    expect(platform.stops, 0);
  });

  test('stopping twice, or before starting, is fine', () async {
    await recorder.stop();
    await recorder.start(path);
    await recorder.stop();
    await recorder.stop();

    expect(platform.stops, 1);
  });
}
