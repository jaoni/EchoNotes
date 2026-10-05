package com.jon.echonotes

import android.Manifest
import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.text.format.DateUtils
import android.util.Log
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat

/**
 * Keeps a recording going while EchoNotes is in the background or the screen
 * is locked: a foreground service of type microphone, with an ongoing
 * notification that shows the time recorded, and Pause/Resume and Stop.
 *
 * The recording itself runs in Flutter, with the record package. This service
 * lets the app keep using the microphone from the background, and keeps the
 * processor awake while recording. RecordingPlugin starts, updates and stops
 * it for the Dart side.
 */
class RecordingService : Service() {

    companion object {
        /**
         * True from the moment a start is asked for until the service stops.
         * While it is, MainActivity keeps the Flutter engine, and with it the
         * recording, alive after the app's screen closes.
         */
        @Volatile
        var isRunning = false

        /** Hears the notification's buttons: "pause", "resume" or "stop". */
        var onButtonPressed: ((String) -> Unit)? = null

        /** Hears that Android wouldn't let the service run in the foreground. */
        var onUnavailable: (() -> Unit)? = null

        const val ACTION_START = "com.jon.echonotes.recording.START"
        const val ACTION_UPDATE = "com.jon.echonotes.recording.UPDATE"
        const val ACTION_STOP = "com.jon.echonotes.recording.STOP"
        const val EXTRA_PAUSED = "paused"
        const val EXTRA_ELAPSED_MS = "elapsedMs"
        const val EXTRA_ENDED_BECAUSE = "endedBecause"

        // One action per button, so their pending intents never replace each
        // other.
        private const val ACTION_PAUSE_PRESSED = "com.jon.echonotes.recording.PAUSE_PRESSED"
        private const val ACTION_RESUME_PRESSED = "com.jon.echonotes.recording.RESUME_PRESSED"
        private const val ACTION_STOP_PRESSED = "com.jon.echonotes.recording.STOP_PRESSED"

        private const val RECORDING_CHANNEL = "recording"
        private const val STOPPED_CHANNEL = "recording_stopped"
        private const val RECORDING_NOTIFICATION = 1
        private const val STOPPED_NOTIFICATION = 2

        /**
         * A safety net: the wake lock lets go by itself after this long, even
         * if nothing releases it. Longer than the longest recording.
         */
        private const val WAKE_LOCK_TIMEOUT_MS = 4 * 60 * 60 * 1000L

        private const val TAG = "EchoNotesRecording"
    }

    private var wakeLock: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> start(intent.getLongExtra(EXTRA_ELAPSED_MS, 0))
            ACTION_UPDATE -> update(
                paused = intent.getBooleanExtra(EXTRA_PAUSED, false),
                elapsedMs = intent.getLongExtra(EXTRA_ELAPSED_MS, 0),
            )
            ACTION_STOP -> stop(intent.getStringExtra(EXTRA_ENDED_BECAUSE))
            ACTION_PAUSE_PRESSED -> onButtonPressed?.invoke("pause")
            ACTION_RESUME_PRESSED -> onButtonPressed?.invoke("resume")
            ACTION_STOP_PRESSED -> onButtonPressed?.invoke("stop")
            // Restarted by Android without a recording to keep going.
            else -> if (!isRunning) stopSelf()
        }
        // A recording can't be picked up again after the app was killed, so
        // Android shouldn't restart the service: recovery handles it instead.
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        isRunning = false
        holdWakeLock(false)
        super.onDestroy()
    }

    private fun start(elapsedMs: Long) {
        isRunning = true
        createChannels()
        try {
            ServiceCompat.startForeground(
                this,
                RECORDING_NOTIFICATION,
                recordingNotification(paused = false, elapsedMs = elapsedMs),
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
                } else {
                    0
                },
            )
        } catch (error: Exception) {
            // The recording carries on while the app is open.
            Log.w(TAG, "Android won't keep the recording going in the background", error)
            isRunning = false
            onUnavailable?.invoke()
            stopSelf()
            return
        }
        holdWakeLock(true)
    }

    private fun update(paused: Boolean, elapsedMs: Long) {
        if (!isRunning) return
        // The processor may sleep while nothing is recorded.
        holdWakeLock(!paused)
        show(RECORDING_NOTIFICATION, recordingNotification(paused, elapsedMs))
    }

    private fun stop(endedBecause: String?) {
        val wasRunning = isRunning
        isRunning = false
        holdWakeLock(false)
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        if (wasRunning && endedBecause != null) {
            show(STOPPED_NOTIFICATION, stoppedNotification(endedBecause))
        }
        stopSelf()
    }

    private fun holdWakeLock(hold: Boolean) {
        if (hold) {
            val lock = wakeLock ?: (getSystemService(Context.POWER_SERVICE) as PowerManager)
                .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "EchoNotes:recording")
                .apply { setReferenceCounted(false) }
                .also { wakeLock = it }
            lock.acquire(WAKE_LOCK_TIMEOUT_MS)
        } else {
            wakeLock?.takeIf { it.isHeld }?.release()
        }
    }

    private fun recordingNotification(paused: Boolean, elapsedMs: Long): Notification {
        val builder = NotificationCompat.Builder(this, RECORDING_CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_recording)
            .setContentIntent(openApp())
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
        if (paused) {
            builder
                .setContentTitle(getString(R.string.recording_paused_title))
                .setContentText(
                    getString(
                        R.string.recording_paused_text,
                        DateUtils.formatElapsedTime(elapsedMs / 1000),
                    ),
                )
                .setShowWhen(false)
                .addAction(0, getString(R.string.recording_resume), button(ACTION_RESUME_PRESSED))
        } else {
            // Android counts the time itself, so it needs no updates.
            builder
                .setContentTitle(getString(R.string.recording_title))
                .setContentText(getString(R.string.recording_text))
                .setUsesChronometer(true)
                .setShowWhen(true)
                .setWhen(System.currentTimeMillis() - elapsedMs)
                .addAction(0, getString(R.string.recording_pause), button(ACTION_PAUSE_PRESSED))
        }
        return builder
            .addAction(0, getString(R.string.recording_stop), button(ACTION_STOP_PRESSED))
            .build()
    }

    private fun stoppedNotification(endedBecause: String): Notification {
        return NotificationCompat.Builder(this, STOPPED_CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_recording)
            .setContentTitle(getString(R.string.recording_stopped_title))
            .setContentText(endedBecause)
            .setStyle(NotificationCompat.BigTextStyle().bigText(endedBecause))
            .setContentIntent(openApp())
            .setAutoCancel(true)
            .build()
    }

    private fun openApp(): PendingIntent {
        val intent = Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        return PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private fun button(action: String): PendingIntent {
        val intent = Intent(this, RecordingService::class.java).setAction(action)
        return PendingIntent.getService(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    /** Shows [notification], unless the user hasn't allowed notifications. */
    private fun show(id: Int, notification: Notification) {
        val allowed = Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        if (allowed) NotificationManagerCompat.from(this).notify(id, notification)
    }

    private fun createChannels() {
        val manager = NotificationManagerCompat.from(this)
        manager.createNotificationChannel(
            NotificationChannelCompat.Builder(RECORDING_CHANNEL, NotificationManagerCompat.IMPORTANCE_LOW)
                .setName(getString(R.string.recording_channel))
                .setDescription(getString(R.string.recording_channel_description))
                .setShowBadge(false)
                .build(),
        )
        manager.createNotificationChannel(
            NotificationChannelCompat.Builder(STOPPED_CHANNEL, NotificationManagerCompat.IMPORTANCE_DEFAULT)
                .setName(getString(R.string.recording_stopped_channel))
                .setDescription(getString(R.string.recording_stopped_channel_description))
                .build(),
        )
    }
}
