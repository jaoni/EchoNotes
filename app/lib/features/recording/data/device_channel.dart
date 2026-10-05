import 'package:flutter/services.dart';

/// The app's own small bridge to Android and iOS, for what no package does
/// simply: `MainActivity.kt` and `AppDelegate.swift` answer it.
///
/// * `freeBytes`: free space where the app keeps its files, as an int.
///
/// Background recording on Android has its own channel,
/// `echonotes/recording`.
const deviceChannel = MethodChannel('echonotes/device');
