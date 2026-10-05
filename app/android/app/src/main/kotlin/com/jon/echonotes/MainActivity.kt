package com.jon.echonotes

import android.content.Context
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        /**
         * An engine that a recording kept running after its screen closed,
         * for the next screen to take over.
         *
         * The engine runs the app's Dart code, and with it the recording.
         * Android normally closes it along with the screen, for example when
         * the app is swiped away from the recent apps. While a recording
         * runs it lives on instead, so the recording keeps going, and
         * reopening the app shows it again. Only ever one screen at a time
         * uses an engine.
         */
        private var keptEngine: FlutterEngine? = null
    }

    override fun provideFlutterEngine(context: Context): FlutterEngine? =
        keptEngine.also { keptEngine = null }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // A kept engine is set up already.
        if (flutterEngine.plugins.has(RecordingPlugin::class.java)) return

        flutterEngine.plugins.add(RecordingPlugin())
        registerDeviceChannel(flutterEngine, applicationContext)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        // This screen is closing. If a recording runs, its engine stays (see
        // shouldDestroyEngineWithHost) for the next screen.
        if (RecordingService.isRunning) keptEngine = flutterEngine
    }

    override fun shouldDestroyEngineWithHost(): Boolean = !RecordingService.isRunning

    /** The app's own small bridge to Android: see device_channel.dart. */
    private fun registerDeviceChannel(flutterEngine: FlutterEngine, context: Context) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "echonotes/device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Free space where path_provider's Application Support
                    // folder, and so the recordings, live.
                    "freeBytes" -> result.success(StatFs(context.filesDir.path).availableBytes)
                    else -> result.notImplemented()
                }
            }
    }
}
