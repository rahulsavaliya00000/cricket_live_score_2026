package com.qdevix.cricketbuzz

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import fl.pip.FlPiPActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlPiPActivity() {

    private val NOTIF_CHANNEL = "com.qdevix.cricketbuzz/notification"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Notification channel (Flutter → Kotlin to show/cancel) ─────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIF_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Start the foreground service — notification is truly sticky
                    "showSpinNotification" -> {
                        val title    = call.argument<String>("title") ?: "🎁 Free Spin Ready!"
                        val body     = call.argument<String>("body")  ?: "Tap to claim your reward"
                        val colorHex = (call.argument<Number>("color"))?.toInt() ?: 0xFF00A86B.toInt()
                        StickyNotificationService.start(applicationContext, title, body, colorHex)
                        result.success(null)
                    }
                    // Stop the foreground service — clears the flag + notification
                    "cancelSpinNotification" -> {
                        StickyNotificationService.stop(applicationContext)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Save route from Intent (cold/killed start) to SharedPreferences.
        // Flutter reads it via shared_preferences package in navigateFromLaunch().
        saveRouteFromIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // Use commit() (synchronous) so the write is flushed to disk BEFORE
        // Flutter's didChangeAppLifecycleState(resumed) fires and reads it.
        saveRouteFromIntent(intent, sync = true)
    }

    private fun saveRouteFromIntent(intent: Intent, sync: Boolean = false) {
        val route = intent.getStringExtra(NotificationActionReceiver.EXTRA_ROUTE) ?: return
        Log.d("MainActivity", "💾 saveRouteFromIntent: $route (sync=$sync)")
        val editor = getSharedPreferences(NotificationActionReceiver.PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(NotificationActionReceiver.KEY_PENDING_ROUTE, route)
        if (sync) editor.commit() else editor.apply()
    }
}
