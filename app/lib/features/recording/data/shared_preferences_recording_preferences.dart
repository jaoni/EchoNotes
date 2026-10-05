import 'package:shared_preferences/shared_preferences.dart';

import 'package:echonotes/features/recording/domain/recording_preferences.dart';

/// Keeps the recording preferences with `shared_preferences`.
class SharedPreferencesRecordingPreferences implements RecordingPreferences {
  SharedPreferencesRecordingPreferences({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _consentReminderSeenKey = 'recording.consentReminderSeen';
  static const _askedToShowNotificationsKey =
      'recording.askedToShowNotifications';
  static const _noteRecordingInBackgroundKey =
      'recording.noteRecordingInBackground';

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> hasSeenConsentReminder() async {
    return await _preferences.getBool(_consentReminderSeenKey) ?? false;
  }

  @override
  Future<void> markConsentReminderSeen() {
    return _preferences.setBool(_consentReminderSeenKey, true);
  }

  @override
  Future<bool> hasAskedToShowNotifications() async {
    return await _preferences.getBool(_askedToShowNotificationsKey) ?? false;
  }

  @override
  Future<void> markAskedToShowNotifications() {
    return _preferences.setBool(_askedToShowNotificationsKey, true);
  }

  @override
  Future<String?> noteRecordingInBackground() {
    return _preferences.getString(_noteRecordingInBackgroundKey);
  }

  @override
  Future<void> setNoteRecordingInBackground(String? noteId) {
    return noteId == null
        ? _preferences.remove(_noteRecordingInBackgroundKey)
        : _preferences.setString(_noteRecordingInBackgroundKey, noteId);
  }
}
