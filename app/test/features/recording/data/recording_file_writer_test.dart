import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:echonotes/features/recording/data/recording_file_writer.dart';

void main() {
  late Directory folder;
  late String path;

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('echonotes_writer_test');
    path = p.join(folder.path, 'recording.aac');
  });

  tearDown(() => folder.delete(recursive: true));

  Future<RecordingFileWriter> open({bool append = false}) {
    return RecordingFileWriter.open(
      path,
      append: append,
      onError: (error) => fail('Unexpected write error: $error'),
    );
  }

  test('writes every piece, in order', () async {
    final writer = await open();
    for (var i = 0; i < 100; i++) {
      writer.write(Uint8List.fromList([i]));
    }
    await writer.close();

    expect(await File(path).readAsBytes(), List.generate(100, (i) => i));
  });

  test('a new recording replaces the file; carrying on adds to it', () async {
    await File(path).writeAsBytes([9, 9, 9]);

    final first = await open();
    first.write(Uint8List.fromList([1, 2]));
    await first.close();
    final more = await open(append: true);
    more.write(Uint8List.fromList([3]));
    await more.close();

    expect(await File(path).readAsBytes(), [1, 2, 3]);
  });

  test(
    'closing twice is fine, and writing after closing does nothing',
    () async {
      final writer = await open();
      writer.write(Uint8List.fromList([1]));
      await writer.close();
      await writer.close();
      writer.write(Uint8List.fromList([2]));

      expect(await File(path).readAsBytes(), [1]);
    },
  );
}
