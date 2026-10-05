import 'package:permission_handler/permission_handler.dart';

import 'package:echonotes/features/recording/domain/microphone_permission.dart';

/// Microphone access through the `permission_handler` package.
///
/// Android only knows that asking is blocked after asking, so [check] may
/// say [MicrophoneAccess.denied] where [request] then says
/// [MicrophoneAccess.blocked].
class PermissionHandlerMicrophonePermission implements MicrophonePermission {
  @override
  Future<MicrophoneAccess> check() async {
    return _accessOf(await Permission.microphone.status);
  }

  @override
  Future<MicrophoneAccess> request() async {
    return _accessOf(await Permission.microphone.request());
  }

  @override
  Future<void> openSettings() => openAppSettings();

  static MicrophoneAccess _accessOf(PermissionStatus status) {
    return switch (status) {
      PermissionStatus.granted ||
      PermissionStatus.limited ||
      PermissionStatus.provisional => MicrophoneAccess.granted,
      PermissionStatus.denied => MicrophoneAccess.denied,
      // Restricted: turned off by parental controls or a company profile.
      PermissionStatus.permanentlyDenied ||
      PermissionStatus.restricted => MicrophoneAccess.blocked,
    };
  }
}
