import 'dart:async';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:echonotes/features/recording/domain/background_recording.dart';

/// Android: keeps recording going with `RecordingService`, the app's own
/// foreground service of type microphone, through the `echonotes/recording`
/// channel (see `RecordingPlugin.kt`).
///
/// The service shows the notification, with a timer and Pause/Resume and
/// Stop, and holds a wake lock while recording. While a recording runs,
/// `MainActivity` also keeps the Flutter engine alive, so swiping the app
/// away doesn't stop it.
class ForegroundServiceBackgroundRecording implements BackgroundRecording {
  ForegroundServiceBackgroundRecording() {
    _channel.setMethodCallHandler(_onCall);
  }

  static const _channel = MethodChannel('echonotes/recording');

  final _events = StreamController<BackgroundRecordingEvent>.broadcast();

  @override
  bool get hasBatterySettings => true;

  @override
  Future<void> askToShowNotifications() async {
    // Granted already before Android 13, which doesn't ask.
    await Permission.notification.request();
  }

  @override
  Future<bool> isLimitedByBattery() async {
    return await _channel.invokeMethod<bool>('isBackgroundRestricted') ?? false;
  }

  @override
  Future<void> openBatterySettings() async {
    // The app's page, which leads to its battery use.
    await openAppSettings();
  }

  @override
  Future<void> start({Duration elapsed = Duration.zero}) {
    return _channel.invokeMethod<void>('start', {
      'elapsedMs': elapsed.inMilliseconds,
    });
  }

  @override
  Future<void> update({required bool isPaused, required Duration elapsed}) {
    return _channel.invokeMethod<void>('update', {
      'paused': isPaused,
      'elapsedMs': elapsed.inMilliseconds,
    });
  }

  @override
  Future<void> stop({String? endedBecause}) {
    return _channel.invokeMethod<void>('stop', {'endedBecause': endedBecause});
  }

  @override
  Stream<BackgroundRecordingEvent> get events => _events.stream;

  Future<void> _onCall(MethodCall call) async {
    final event = switch ((call.method, call.arguments)) {
      ('buttonPressed', 'pause') => BackgroundRecordingEvent.pause,
      ('buttonPressed', 'resume') => BackgroundRecordingEvent.resume,
      ('buttonPressed', 'stop') => BackgroundRecordingEvent.stop,
      ('unavailable', _) => BackgroundRecordingEvent.unavailable,
      _ => null,
    };
    if (event != null) _events.add(event);
  }
}
