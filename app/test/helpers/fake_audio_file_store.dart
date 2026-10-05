import 'package:echonotes/features/notes/domain/audio_file_store.dart';

/// Remembers which recordings were deleted, without touching any files.
class FakeAudioFileStore implements AudioFileStore {
  /// The file names deleted so far, in order.
  final deleted = <String>[];

  /// When set, deleting throws this instead.
  Object? deleteError;

  @override
  Future<String> pathOf(String fileName) async => '/recordings/$fileName';

  @override
  Future<String> pathForNewRecording(String fileName) => pathOf(fileName);

  @override
  Future<void> delete(String fileName) async {
    if (deleteError case final error?) throw error;
    deleted.add(fileName);
  }
}
