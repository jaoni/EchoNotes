/// Whether the app may use the microphone.
enum MicrophoneAccess {
  granted,

  /// Not allowed yet, but the app can ask again.
  denied,

  /// Turned off in the phone's settings, or never asked for again, so only
  /// the settings can change it.
  blocked,
}

/// Checks for and asks for microphone access.
abstract interface class MicrophonePermission {
  /// The current access, without asking.
  Future<MicrophoneAccess> check();

  /// Asks the user, when the phone still allows asking, and gives the
  /// result.
  Future<MicrophoneAccess> request();

  /// Opens this app's page in the phone's settings.
  Future<void> openSettings();
}
