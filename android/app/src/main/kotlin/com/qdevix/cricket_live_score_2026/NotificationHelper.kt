package com.qdevix.cricket_live_score_2026

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.RectF
import android.os.Build
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * Builds and posts a custom-layout spin notification using [RemoteViews].
 * Called from Flutter via the MethodChannel "com.qdevix.cricketbuzz/notification".
 */
object NotificationHelper {

    private const val CHANNEL_ID   = "free_spin_reminder"
    private const val CHANNEL_NAME = "Free Spin Reminder"
    const val NOTIF_ID             = 888

    fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Get notified when your daily free spin is ready"
                setShowBadge(true)
            }
            val nm = context.getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }
    }

    /**
     * Builds and returns the spin notification without posting it.
     * Used by [StickyNotificationService.onStartCommand] so it can call
     * [Service.startForeground] with the notification directly.
     *
     * This makes the notification a **foreground-service** notification,
     * which Android marks as non-dismissable for as long as the service runs.
     */
    fun buildSpinNotification(
        context: Context,
        title: String,
        body: String,
        colorHex: Int,
    ): Notification {
        createChannel(context)

        // Rounded app icon for RemoteViews
        val rawIcon = BitmapFactory.decodeResource(context.resources, R.mipmap.launcher_icon)
        val roundedIcon = roundBitmap(rawIcon, 10f, context)

        val white = 0xFFFFFFFF.toInt()

        // ── RemoteViews (collapsed) ────────────────────────────────────────
        val collapsed = RemoteViews(context.packageName, R.layout.notification_spin_collapsed)
        collapsed.setTextViewText(R.id.notif_title_collapsed, title)
        collapsed.setTextColor(R.id.notif_title_collapsed, white)
        collapsed.setTextColor(R.id.notif_body_collapsed, white)
        collapsed.setImageViewBitmap(R.id.notif_icon_collapsed, roundedIcon)

        // ── RemoteViews (expanded — the custom layout with buttons) ────────
        val expanded = RemoteViews(context.packageName, R.layout.notification_spin)
        expanded.setTextViewText(R.id.notif_title, title)
        expanded.setTextColor(R.id.notif_title, white)
        expanded.setTextViewText(R.id.notif_body, body)
        expanded.setTextColor(R.id.notif_body, white)
        expanded.setTextColor(R.id.notif_app_name, white)
        expanded.setTextColor(R.id.notif_time, white)
        expanded.setImageViewBitmap(R.id.notif_icon, roundedIcon)

        // PendingIntent for "Spin Now" button → directly launches MainActivity
        val spinIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            action = NotificationActionReceiver.ACTION_SPIN_NOW
            putExtra(NotificationActionReceiver.EXTRA_ROUTE, "/spin-wheel")
            putExtra(NotificationActionReceiver.EXTRA_NOTIF_ID, NOTIF_ID)
        }
        val spinPi = PendingIntent.getActivity(
            context, 1001, spinIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        expanded.setOnClickPendingIntent(R.id.btn_spin_now, spinPi)

        // PendingIntent for "Live Match" button → directly launches MainActivity
        val liveIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            action = NotificationActionReceiver.ACTION_LIVE_MATCH
            putExtra(NotificationActionReceiver.EXTRA_ROUTE, "/home")
            putExtra(NotificationActionReceiver.EXTRA_NOTIF_ID, NOTIF_ID)
        }
        val livePi = PendingIntent.getActivity(
            context, 1002, liveIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        expanded.setOnClickPendingIntent(R.id.btn_live_match, livePi)

        // Body tap → Spin Wheel
        val bodyIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(NotificationActionReceiver.EXTRA_ROUTE, "/spin-wheel")
        }
        val bodyPi = PendingIntent.getActivity(
            context, 1000, bodyIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // ── Build notification ─────────────────────────────────────────────
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notif)
            .setColor(colorHex)
            .setContentTitle(title)
            .setContentText(body)
            .setContentIntent(bodyPi)
            .setCustomContentView(collapsed)
            .setCustomBigContentView(expanded)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setColorized(true)
            .build()

        notification.flags = notification.flags or Notification.FLAG_NO_CLEAR
        return notification
    }

    /** Convenience: build + post the notification directly (used for quick one-shot calls). */
    fun showSpinNotification(
        context: Context,
        title: String,
        body: String,
        colorHex: Int,
    ) {
        val notification = buildSpinNotification(context, title, body, colorHex)
        try {
            NotificationManagerCompat.from(context).notify(NOTIF_ID, notification)
        } catch (e: SecurityException) {
            // POST_NOTIFICATIONS not granted yet
        }
    }

    fun cancelSpinNotification(context: Context) {
        NotificationManagerCompat.from(context).cancel(NOTIF_ID)
    }

    /** Returns a rounded-corner version of the given bitmap. */
    private fun roundBitmap(bitmap: Bitmap, radiusDp: Float, context: Context): Bitmap {
        val density = context.resources.displayMetrics.density
        val radiusPx = radiusDp * density
        val output = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val rect = RectF(0f, 0f, bitmap.width.toFloat(), bitmap.height.toFloat())
        canvas.drawRoundRect(rect, radiusPx, radiusPx, paint)
        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        canvas.drawBitmap(bitmap, 0f, 0f, paint)
        return output
    }
}
