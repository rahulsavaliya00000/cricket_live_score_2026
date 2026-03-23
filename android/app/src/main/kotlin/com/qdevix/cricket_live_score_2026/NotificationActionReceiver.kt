package com.qdevix.cricket_live_score_2026

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences

class NotificationActionReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_SPIN_NOW    = "com.qdevix.cricketbuzz.ACTION_SPIN_NOW"
        const val ACTION_LIVE_MATCH  = "com.qdevix.cricketbuzz.ACTION_LIVE_MATCH"
        const val EXTRA_NOTIF_ID     = "notif_id"
        const val EXTRA_ROUTE        = "route"

        // SharedPreferences key — read by Flutter after launch
        const val PREFS_NAME         = "notification_prefs"
        const val KEY_PENDING_ROUTE  = "pending_notification_route"
    }

    override fun onReceive(context: Context, intent: Intent) {
        // Do NOT cancel the notification — it is sticky/ongoing and must stay visible
        // until the user actually spins (the Flutter side calls cancelSpinNotification).

        // Determine which route to open
        val route = when (intent.action) {
            ACTION_SPIN_NOW   -> "/spin-wheel"
            ACTION_LIVE_MATCH -> "/home"
            else              -> "/spin-wheel"
        }

        // ── Persist route to SharedPreferences so Flutter can read it reliably
        // on both cold-start (killed) and warm-start (backgrounded) scenarios.
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_PENDING_ROUTE, route)
            .apply()

        // Launch (or bring-to-front) the main Activity
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(EXTRA_ROUTE, route)
        }
        context.startActivity(launchIntent)
    }
}
