import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:echonotes/features/playback/data/just_audio_playback.dart';
import 'package:echonotes/features/recording/data/adts.dart';
import 'package:echonotes/features/recording/data/channel_storage_space.dart';
import 'package:echonotes/features/recording/data/record_audio_recorder_service.dart';

/// Records a few seconds with the real microphone and checks the file, and
/// checks the app's own bridge to the platform.
///
/// Runs on a phone or simulator, not with `flutter test`:
///
///     fvm flutter test integration_test -d <device>
///
/// The microphone must be allowed first. On a simulator:
/// `xcrun simctl privacy booted grant microphone com.jon.echonotes`.
/// How much audio an AAC encoder can add to each recording run: its start-up
/// samples and the last part-filled frame.
const _encoderSlack = Duration(milliseconds: 300);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('records playable AAC, and carries on after a pause', (
    tester,
  ) async {
    final folder = await getTemporaryDirectory();
    final path = p.join(folder.path, 'smoke.aac');
    final recorder = RecordAudioRecorderService();
    final lengths = <Duration>[];
    final levels = <double>[];
    recorder.recordedLength.listen(lengths.add);
    recorder.levels.listen(levels.add);

    final clock = Stopwatch()..start();
    await recorder.start(path);
    await Future<void>.delayed(const Duration(seconds: 3));
    await recorder.pause();
    final pausedAt = clock.elapsed;
    await Future<void>.delayed(const Duration(seconds: 1));
    final resumingAt = clock.elapsed;
    await recorder.resume();
    await Future<void>.delayed(const Duration(seconds: 2));
    await recorder.stop();
    final stoppedAt = clock.elapsed;
    await recorder.dispose();

    final bytes = await File(path).readAsBytes();
    final first = AdtsHeader.parse(bytes, 0)!;
    expect(first.sampleRate, 16000);
    // Real audio from the start: Android's setup data was left out.
    expect(first.holdsAudio, isTrue);

    // Everything while recording is kept: at least the five seconds waited
    // with the recorder running. A phone can start capturing before
    // `start` returns (record 7 on Android does), so more is fine...
    final length = await repairAdtsFile(path);
    expect(length.inMilliseconds, greaterThanOrEqualTo(4000));
    // ...but never the pause: the audio fits in the time the recorder ran,
    // plus the encoder's start-up samples for each of the two runs.
    final running = pausedAt + (stoppedAt - resumingAt);
    expect(length, lessThanOrEqualTo(running + _encoderSlack * 2));
    expect(lengths.last, length);
    // Nothing was cut off: the file was whole when it stopped.
    expect(await File(path).length(), bytes.length);
    // About 4 KB a second at 32 kbps.
    final bytesPerSecond = bytes.length / length.inMilliseconds * 1000;
    expect(bytesPerSecond, inInclusiveRange(2000, 6000));
    expect(levels, isNotEmpty);
    // ignore: avoid_print
    print('Recorded $length in ${bytes.length} bytes: $bytesPerSecond B/s');

    // The phone's own player opens it.
    final playback = JustAudioPlayback();
    await playback.load(path);
    await playback.play();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await playback.pause();
    await playback.dispose();
  });

  testWidgets("the app's own bridge reports the free space", (tester) async {
    // MainActivity.kt and AppDelegate.swift answer it, each where its
    // platform makes the engine. If that setup breaks, nothing else fails:
    // the check before recording treats an unanswered call as "unknown".
    final freeBytes = await ChannelStorageSpace().freeBytes();
    expect(freeBytes, isNotNull);
    expect(freeBytes, greaterThan(0));
  });
}
