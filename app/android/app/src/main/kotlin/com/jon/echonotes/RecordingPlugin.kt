package com.jon.echonotes

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The `echonotes/recording` channel between Dart and RecordingService: see
 * foreground_service_background_recording.dart.
 *
 * From Dart: `start` and `update` (with `elapsedMs`, and `paused`), `stop`
 * (with `endedBecause` when the recording stopped by itself) and
 * `isBackgroundRestricted`. To Dart: `buttonPressed` ("pause", "resume" or
 * "stop") and `unavailable`.
 *
 * Attached to the Flutter engine, not to a screen, so it keeps working after
 * the app is swiped away.
 */
class RecordingPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private var channel: MethodChannel? = null
    private var context: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        val channel = MethodChannel(binding.binaryMessenger, "echonotes/recording")
        channel.setMethodCallHandler(this)
        this.channel = channel
        RecordingService.onButtonPressed = { button -> channel.invokeMethod("buttonPressed", button) }
        RecordingService.onUnavailable = { channel.invokeMethod("unavailable", null) }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        RecordingService.onButtonPressed = null
        RecordingService.onUnavailable = null
        // The recording ran in this engine, so it's over: don't leave its
        // notification behind. Recovery saves what was recorded.
        context?.let { if (RecordingService.isRunning) send(it, RecordingService.ACTION_STOP) }
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val context = context ?: return result.error("detached", "No app to work for.", null)
        try {
            when (call.method) {
                "start" -> {
                    RecordingService.isRunning = true
                    val intent = Intent(context, RecordingService::class.java)
                        .setAction(RecordingService.ACTION_START)
                        .putExtra(RecordingService.EXTRA_ELAPSED_MS, call.elapsedMs())
                    // Throws when the app isn't on screen (Android 12+).
                    ContextCompat.startForegroundService(context, intent)
                }
                "update" -> if (RecordingService.isRunning) {
                    send(context, RecordingService.ACTION_UPDATE) {
                        putExtra(RecordingService.EXTRA_PAUSED, call.argument<Boolean>("paused") == true)
                        putExtra(RecordingService.EXTRA_ELAPSED_MS, call.elapsedMs())
                    }
                }
                "stop" -> if (RecordingService.isRunning) {
                    send(context, RecordingService.ACTION_STOP) {
                        putExtra(RecordingService.EXTRA_ENDED_BECAUSE, call.argument<String>("endedBecause"))
                    }
                }
                "isBackgroundRestricted" -> {
                    // "Restricted" in the app's battery settings: Android stops
                    // its foreground services when it leaves the screen.
                    val restricted = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
                        context.getSystemService(ActivityManager::class.java).isBackgroundRestricted
                    return result.success(restricted)
                }
                else -> return result.notImplemented()
            }
            result.success(null)
        } catch (error: Exception) {
            if (call.method == "start") RecordingService.isRunning = false
            Log.w("EchoNotesRecording", "Couldn't ${call.method} the recording service", error)
            result.error("unavailable", error.message, null)
        }
    }

    private fun send(context: Context, action: String, extras: Intent.() -> Unit = {}) {
        val intent = Intent(context, RecordingService::class.java).setAction(action).apply(extras)
        context.startService(intent)
    }

    private fun MethodCall.elapsedMs(): Long = argument<Number>("elapsedMs")?.toLong() ?: 0L
}
