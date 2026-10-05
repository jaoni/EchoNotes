import 'package:echonotes/features/recording/domain/background_recording.dart';

/// iOS: its audio background mode, set in Info.plist, keeps the recording
/// going while the app is in the background or the screen is locked, as
/// long as the recording started in the app. Nothing more is needed while
/// it runs, and there's no notification: iOS shows the microphone in use by
/// itself.
class AudioModeBackgroundRecording implements BackgroundRecording {
  @override
  bool get hasBatterySettings => false;

  @override
  Future<void> askToShowNotifications() async {}

  @override
  Future<bool> isLimitedByBattery() async => false;

  @override
  Future<void> openBatterySettings() async {}

  @override
  Future<void> start({Duration elapsed = Duration.zero}) async {}

  @override
  Future<void> update({
    required bool isPaused,
    required Duration elapsed,
  }) async {}

  @override
  Future<void> stop({String? endedBecause}) async {}

  @override
  Stream<BackgroundRecordingEvent> get events => const Stream.empty();
}
