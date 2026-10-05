import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// With the scene lifecycle, the Flutter engine starts after launch, with
  /// the app's first scene, so plugins and channels are set up here instead.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerDeviceChannel(messenger: engineBridge.applicationRegistrar.messenger())
  }

  /// The app's own small bridge to iOS: see device_channel.dart.
  private func registerDeviceChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "echonotes/device", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "freeBytes":
        // The space available for things the user asked for: it counts
        // files iOS can clear by itself to make room.
        let home = URL(fileURLWithPath: NSHomeDirectory())
        do {
          let values = try home.resourceValues(
            forKeys: [.volumeAvailableCapacityForImportantUsageKey])
          result(values.volumeAvailableCapacityForImportantUsage.map { NSNumber(value: $0) })
        } catch {
          result(FlutterError(code: "unavailable", message: error.localizedDescription, details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
