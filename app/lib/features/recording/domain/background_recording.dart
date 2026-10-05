/// Keeps a recording going while EchoNotes is in the background or the
/// screen is locked, and shows it outside the app.
///
/// Android needs a foreground service for that, with a notification that has
/// Pause and Stop buttons. iOS needs only its audio background mode, set in
/// Info.plist, so there most of this does nothing.
abstract interface class BackgroundRecording {
  /// Whether the phone has battery settings that can stop EchoNotes in the
  /// background, so it's worth pointing the user to them.
  bool get hasBatterySettings;

  /// Asks to show the recording notification, where the phone needs asking
  /// (Android 13 and later). Recording works the same either way.
  Future<void> askToShowNotifications();

  /// Whether the phone's battery settings stop EchoNotes in the background
  /// right now, so a recording would stop when the app is left.
  Future<bool> isLimitedByBattery();

  /// Opens EchoNotes' page in the phone's settings, where its battery use
  /// can be changed.
  Future<void> openBatterySettings();

  /// Starts keeping the recording going. Only works while the app is on
  /// screen: throws when the phone won't allow it.
  Future<void> start({Duration elapsed = Duration.zero});

  /// Shows whether it's recording or paused, and how much is recorded. While
  /// paused, the phone may sleep.
  Future<void> update({required bool isPaused, required Duration elapsed});

  /// Stops keeping the recording going, and lets the phone sleep.
  ///
  /// [endedBecause] says why the recording stopped by itself, for a user
  /// who can't see the app: Android leaves it in a notification.
  Future<void> stop({String? endedBecause});

  /// What happened outside the app: see [BackgroundRecordingEvent].
  Stream<BackgroundRecordingEvent> get events;
}

/// Something that happened to a recording outside the app.
enum BackgroundRecordingEvent {
  /// Pause pressed in the notification.
  pause,

  /// Resume pressed in the notification.
  resume,

  /// Stop pressed in the notification.
  stop,

  /// The phone won't keep the recording going in the background, so it
  /// stops if the app is left.
  unavailable,
}
