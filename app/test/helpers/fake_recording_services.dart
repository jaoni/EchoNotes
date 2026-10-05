import 'dart:async';

import 'package:echonotes/features/recording/domain/background_recording.dart';
import 'package:echonotes/features/recording/domain/microphone_permission.dart';
import 'package:echonotes/features/recording/domain/recording_preferences.dart';
import 'package:echonotes/features/recording/domain/storage_space.dart';

/// Gives [access] until a request, which gives [afterRequest].
class FakeMicrophonePermission implements MicrophonePermission {
  FakeMicrophonePermission({
    this.access = MicrophoneAccess.granted,
    MicrophoneAccess? afterRequest,
  }) : afterRequest = afterRequest ?? access;

  MicrophoneAccess access;
  MicrophoneAccess afterRequest;
  var requests = 0;
  var settingsOpened = 0;

  @override
  Future<MicrophoneAccess> check() async => access;

  @override
  Future<MicrophoneAccess> request() async {
    requests++;
    return access = afterRequest;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}

class FakeStorageSpace implements StorageSpace {
  FakeStorageSpace([this.bytes = 10 * 1000 * 1000 * 1000]);

  /// Null when the phone can't say.
  int? bytes;

  @override
  Future<int?> freeBytes() async => bytes;
}

/// Pretends to keep recordings going in the background, like Android's
/// foreground service, and remembers what it was told.
class FakeBackgroundRecording implements BackgroundRecording {
  FakeBackgroundRecording({this.hasBatterySettings = true});

  final _events = StreamController<BackgroundRecordingEvent>.broadcast();

  @override
  final bool hasBatterySettings;

  var isRunning = false;
  var isPaused = false;
  Duration? elapsed;

  /// What the last stop said about why the recording ended.
  String? endedBecause;
  var stops = 0;
  var notificationRequests = 0;
  var batterySettingsOpened = 0;

  /// Like Android's battery setting "Restricted".
  var isLimited = false;

  /// When set, starting throws this instead.
  Object? startError;

  /// What the Android service does: it keeps the phone awake only while it
  /// runs and isn't paused.
  bool get holdsWakeLock => isRunning && !isPaused;

  /// Pretends [event] happened, such as a notification button pressed.
  void send(BackgroundRecordingEvent event) => _events.add(event);

  @override
  Future<void> askToShowNotifications() async => notificationRequests++;

  @override
  Future<bool> isLimitedByBattery() async => isLimited;

  @override
  Future<void> openBatterySettings() async => batterySettingsOpened++;

  @override
  Future<void> start({Duration elapsed = Duration.zero}) async {
    if (startError case final error?) throw error;
    isRunning = true;
    isPaused = false;
    this.elapsed = elapsed;
  }

  @override
  Future<void> update({
    required bool isPaused,
    required Duration elapsed,
  }) async {
    if (!isRunning) return;
    this.isPaused = isPaused;
    this.elapsed = elapsed;
  }

  @override
  Future<void> stop({String? endedBecause}) async {
    stops++;
    isRunning = false;
    isPaused = false;
    this.endedBecause = endedBecause;
  }

  @override
  Stream<BackgroundRecordingEvent> get events => _events.stream;
}

class FakeRecordingPreferences implements RecordingPreferences {
  FakeRecordingPreferences({
    this.seenConsentReminder = true,
    this.askedToShowNotifications = true,
    this.noteInBackground,
  });

  bool seenConsentReminder;
  bool askedToShowNotifications;
  String? noteInBackground;

  @override
  Future<bool> hasSeenConsentReminder() async => seenConsentReminder;

  @override
  Future<void> markConsentReminderSeen() async => seenConsentReminder = true;

  @override
  Future<bool> hasAskedToShowNotifications() async => askedToShowNotifications;

  @override
  Future<void> markAskedToShowNotifications() async {
    askedToShowNotifications = true;
  }

  @override
  Future<String?> noteRecordingInBackground() async => noteInBackground;

  @override
  Future<void> setNoteRecordingInBackground(String? noteId) async {
    noteInBackground = noteId;
  }
}
