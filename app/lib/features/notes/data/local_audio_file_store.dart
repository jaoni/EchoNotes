import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:echonotes/features/notes/domain/audio_file_store.dart';

/// Keeps recordings in a `recordings` folder inside the app's Application
/// Support folder: private to the app and included in backups.
class LocalAudioFileStore implements AudioFileStore {
  /// [baseDirectory] finds the folder `recordings` sits in. Only tests
  /// change it.
  LocalAudioFileStore({this._baseDirectory = getApplicationSupportDirectory});

  static const _folderName = 'recordings';

  final Future<Directory> Function() _baseDirectory;

  @override
  Future<String> pathOf(String fileName) async {
    // A name like "../echonotes.sqlite" would reach outside the folder.
    final isPlainName =
        fileName.isNotEmpty &&
        fileName != '.' &&
        fileName != '..' &&
        p.basename(fileName) == fileName;
    if (!isPlainName) {
      throw ArgumentError.value(
        fileName,
        'fileName',
        'Must be a file name without a folder',
      );
    }
    final base = await _baseDirectory();
    return p.join(base.path, _folderName, fileName);
  }

  @override
  Future<String> pathForNewRecording(String fileName) async {
    final path = await pathOf(fileName);
    await Directory(p.dirname(path)).create(recursive: true);
    return path;
  }

  @override
  Future<void> delete(String fileName) async {
    try {
      await File(await pathOf(fileName)).delete();
    } on PathNotFoundException {
      // Already gone, which is all we wanted.
    }
  }
}
