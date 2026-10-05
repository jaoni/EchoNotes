import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:echonotes/features/recording/data/adts.dart';

import '../../../helpers/adts_frames.dart';

void main() {
  const frameLength = Duration(milliseconds: 64);

  group('a header', () {
    test('says how long its frame is and how much audio it holds', () {
      final header = AdtsHeader.parse(adtsFrame(audioBytes: 100), 0)!;

      expect(header.headerLength, 7);
      expect(header.frameLength, 107);
      expect(header.sampleRate, 16000);
      expect(header.duration, frameLength);
      expect(header.holdsAudio, isTrue);
    });

    test('is not found where the bytes are something else', () {
      final frame = adtsFrame();

      expect(AdtsHeader.parse(Uint8List(10), 0), isNull);
      expect(AdtsHeader.parse(frame, 1), isNull);
      // Too few bytes to tell.
      expect(AdtsHeader.parse(Uint8List.sublistView(frame, 0, 6), 0), isNull);
    });
  });

  group('the splitter', () {
    test('gives whole frames, however the bytes arrive', () {
      final splitter = AdtsFrameSplitter();
      final bytes = adtsFrames(3);

      final first = splitter.add(Uint8List.sublistView(bytes, 0, 40));
      final rest = splitter.add(Uint8List.sublistView(bytes, 40));

      expect(first.duration, frameLength);
      expect(first.bytes, adtsFrame());
      expect(rest.duration, frameLength * 2);
      expect([...first.bytes, ...rest.bytes], bytes);
      expect(splitter.consumedBytes, bytes.length);
    });

    test("leaves out Android's setup data, which holds no audio", () {
      final splitter = AdtsFrameSplitter();

      final frames = splitter.add(
        Uint8List.fromList([...adtsFrame(audioBytes: 2), ...adtsFrame()]),
      );

      expect(frames.bytes, adtsFrame());
      expect(frames.duration, frameLength);
    });

    test('skips bytes that belong to no frame', () {
      final splitter = AdtsFrameSplitter();

      final frames = splitter.add(
        Uint8List.fromList([1, 2, 3, ...adtsFrame(), 0xFF, ...adtsFrame()]),
      );

      expect(frames.duration, frameLength * 2);
      expect(frames.bytes, [...adtsFrame(), ...adtsFrame()]);
    });
  });

  group('repairing a file', () {
    late Directory folder;

    setUp(() async {
      folder = await Directory.systemTemp.createTemp('echonotes_adts_test');
    });

    tearDown(() => folder.delete(recursive: true));

    test('cuts off a half-written last frame and measures the rest', () async {
      final file = File(p.join(folder.path, 'cut.aac'));
      final whole = adtsFrames(50);
      await file.writeAsBytes([...whole, ...adtsFrame().take(12)]);

      final length = await repairAdtsFile(file.path);

      expect(length, frameLength * 50);
      expect(await file.readAsBytes(), whole);
    });

    test('leaves a whole file as it is', () async {
      final file = File(p.join(folder.path, 'whole.aac'));
      await file.writeAsBytes(adtsFrames(10));

      expect(await repairAdtsFile(file.path), frameLength * 10);
      expect(await file.length(), adtsFrames(10).length);
    });

    test('finds no audio in an empty or missing file', () async {
      final empty = File(p.join(folder.path, 'empty.aac'));
      await empty.create();

      expect(await repairAdtsFile(empty.path), Duration.zero);
      expect(
        await repairAdtsFile(p.join(folder.path, 'missing.aac')),
        Duration.zero,
      );
    });
  });
}
