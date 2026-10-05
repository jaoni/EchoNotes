/// How much room is left on the phone for recordings.
abstract interface class StorageSpace {
  /// Free bytes where recordings are saved, or null when the phone can't
  /// say.
  Future<int?> freeBytes();
}
