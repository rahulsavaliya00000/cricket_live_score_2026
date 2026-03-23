package com.qdevix.cricketbuzz

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Restarts [StickyNotificationService] after device reboot.
 *
 * Registered in AndroidManifest.xml for BOOT_COMPLETED + QUICKBOOT_POWERON.
 * Does nothing if the user had previously cancelled the notification (flag = false).
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == "com.htc.intent.action.QUICKBOOT_POWERON"
        ) {
            Log.d("BootReceiver", "Boot completed — checking sticky flag")
            StickyNotificationService.restartIfNeeded(context)
        }
    }
}
