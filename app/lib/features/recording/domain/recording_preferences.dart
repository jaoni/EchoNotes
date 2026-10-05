/// What the app remembers about recording between launches.
abstract interface class RecordingPreferences {
  /// Whether the user has seen the reminder to tell people they're being
  /// recorded. It's shown once, before the first recording.
  Future<bool> hasSeenConsentReminder();

  Future<void> markConsentReminderSeen();

  /// Whether the app has asked to show its recording notification. It asks
  /// once, so a "no" is never asked again.
  Future<bool> hasAskedToShowNotifications();

  Future<void> markAskedToShowNotifications();

  /// The note that was recording when the app last left the screen, or
  /// null. If the app is killed then, recovery finds it here and can tell
  /// that the phone stopped the recording in the background.
  Future<String?> noteRecordingInBackground();

  Future<void> setNoteRecordingInBackground(String? noteId);
}
