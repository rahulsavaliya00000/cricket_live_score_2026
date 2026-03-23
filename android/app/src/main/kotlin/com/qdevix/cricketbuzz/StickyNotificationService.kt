package com.qdevix.cricketbuzz

import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log

/**
 * A foreground service that keeps the sticky spin notification alive.
 *
 * WHY a foreground service:
 *  - Foreground service notifications are NON-DISMISSABLE by the user (no swipe).
 *  - The service survives app kill when stopWithTask="false" in the manifest.
 *  - START_STICKY ensures Android restarts the service if it kills it for memory.
 *  - We persist an "active" flag to SharedPreferences so the BootReceiver and
 *    onTaskRemoved can restart the service without needing Flutter/Dart at all.
 */
class StickyNotificationService : Service() {

    companion object {
        private const val TAG = "StickyNotifService"

        const val EXTRA_TITLE     = "extra_title"
        const val EXTRA_BODY      = "extra_body"
        const val EXTRA_COLOR_HEX = "extra_color_hex"

        // SharedPreferences keys — Flutter-independent persistence
        private const val PREFS_NAME   = "sticky_notif_prefs"
        private const val KEY_ACTIVE   = "sticky_active"
        private const val KEY_TITLE    = "sticky_title"
        private const val KEY_BODY     = "sticky_body"
        private const val KEY_COLOR    = "sticky_color"

        /** Starts the service from any Context (Activity, Receiver, Service). */
        fun start(context: Context, title: String, body: String, colorHex: Int) {
            // Persist so we can restart without Flutter
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit()
                .putBoolean(KEY_ACTIVE, true)
                .putString(KEY_TITLE, title)
                .putString(KEY_BODY, body)
                .putInt(KEY_COLOR, colorHex)
                .apply()

            val intent = Intent(context, StickyNotificationService::class.java).apply {
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_BODY, body)
                putExtra(EXTRA_COLOR_HEX, colorHex)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        /** Stops the service from any Context. */
        fun stop(context: Context) {
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit()
                .putBoolean(KEY_ACTIVE, false)
                .apply()
            context.stopService(Intent(context, StickyNotificationService::class.java))
        }

        /** Returns true if the service should be running (persisted flag). */
        fun shouldBeActive(context: Context): Boolean {
            return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .getBoolean(KEY_ACTIVE, false)
        }

        /** Restarts the service using the last saved title/body/color — NO Flutter needed. */
        fun restartIfNeeded(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            if (!prefs.getBoolean(KEY_ACTIVE, false)) return
            val title    = prefs.getString(KEY_TITLE, "🎁 Free Spin Available!") ?: "🎁 Free Spin Available!"
            val body     = prefs.getString(KEY_BODY, "Tap Spin Now to win coins, balls & bats!") ?: "Tap Spin Now to win coins, balls & bats!"
            val colorHex = prefs.getInt(KEY_COLOR, 0xFF00A86B.toInt())
            start(context, title, body, colorHex)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand")

        // On START_STICKY restart, intent is null — read from saved prefs
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val title    = intent?.getStringExtra(EXTRA_TITLE)
            ?: prefs.getString(KEY_TITLE, "🎁 Free Spin Available!")!!
        val body     = intent?.getStringExtra(EXTRA_BODY)
            ?: prefs.getString(KEY_BODY, "Tap Spin Now to win coins, balls & bats!")!!
        val colorHex = if (intent != null && intent.hasExtra(EXTRA_COLOR_HEX))
            intent.getIntExtra(EXTRA_COLOR_HEX, 0xFF00A86B.toInt())
        else
            prefs.getInt(KEY_COLOR, 0xFF00A86B.toInt())

        // Save latest values (handles first-time start from Flutter)
        prefs.edit()
            .putBoolean(KEY_ACTIVE, true)
            .putString(KEY_TITLE, title)
            .putString(KEY_BODY, body)
            .putInt(KEY_COLOR, colorHex)
            .apply()

        val notification = NotificationHelper.buildSpinNotification(
            applicationContext, title, body, colorHex
        )

        // Android 12+ (API 31+) restricts starting foreground services from background.
        // Android 14+ (API 34+) requires foregroundServiceType (set in Manifest).
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // For Android 10+, specifying type is good practice, matches manifest.
                // We use 0 as the type for now as 'specialUse' (0x40000000) might not be 
                // easily accessible without extra imports, but the manifest handles it.
                startForeground(NotificationHelper.NOTIF_ID, notification)
            } else {
                startForeground(NotificationHelper.NOTIF_ID, notification)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start foreground service: ${e.message}")
            // If we can't start as foreground, we must stop the service to avoid ANR/Crash
            stopSelf()
        }

        return START_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // User swiped the app from recents — manifest has stopWithTask="false"
        // so this service keeps running. But some OEM ROMs still kill it here.
        // Schedule a restart via a PendingIntent as a safety net.
        Log.d(TAG, "onTaskRemoved — scheduling restart")
        val restartIntent = Intent(applicationContext, StickyNotificationService::class.java)
        val pi = android.app.PendingIntent.getService(
            applicationContext, 1,
            restartIntent,
            android.app.PendingIntent.FLAG_ONE_SHOT or android.app.PendingIntent.FLAG_IMMUTABLE
        )
        val am = getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
        am.set(
            android.app.AlarmManager.ELAPSED_REALTIME,
            android.os.SystemClock.elapsedRealtime() + 1000,
            pi
        )
        super.onTaskRemoved(rootIntent)
    }
}
