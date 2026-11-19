package com.byfb.hear_clock

import android.app.AlarmManager
import android.app.KeyguardManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.widget.RemoteViews

/** Android 8–11 lack the public AnalogClock hand setters available to newer launchers. */
internal object LegacyDialUpdates {
    const val TICK = "com.byfb.hear_clock.DIAL_MINUTE"

    fun ids(context: Context): IntArray = AppWidgetManager.getInstance(context)
        .getAppWidgetIds(ComponentName(context, ClockWidget::class.java))

    private fun minuteIntent(context: Context) = PendingIntent.getBroadcast(context, 1,
        Intent(context, ClockWidget::class.java).setAction(TICK), PendingIntent.FLAG_IMMUTABLE)

    fun sync(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) return
        val settings = ClockSettings.load(context)
        if (settings.variant != "analog" || ids(context).isEmpty()) {
            stop(context)
            return
        }
        val alarms = context.getSystemService(AlarmManager::class.java)
        val service = Intent(context, LegacySecondsService::class.java)
        if (settings.seconds) {
            alarms.cancel(minuteIntent(context))
            context.startForegroundService(service)
        } else {
            context.stopService(service)
            val next = (System.currentTimeMillis() / 60000 + 1) * 60000
            // RTC leaves a sleeping phone asleep. A pending tick catches up on wake.
            alarms.setExact(AlarmManager.RTC, next, minuteIntent(context))
        }
    }

    fun stop(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) return
        context.getSystemService(AlarmManager::class.java).cancel(minuteIntent(context))
        context.stopService(Intent(context, LegacySecondsService::class.java))
    }

    fun publish(context: Context, ids: IntArray, art: DialArtwork) {
        if (ids.isEmpty()) return
        val views = RemoteViews(context.packageName, R.layout.clock_analog)
        views.setImageViewBitmap(R.id.legacy_dial, art.snapshot())
        AppWidgetManager.getInstance(context).partiallyUpdateAppWidget(ids, views)
    }
}

/** The user-enabled second hand needs a live process on Android 8–11 only. */
class LegacySecondsService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var ids = intArrayOf()
    private var art: DialArtwork? = null
    private val tick = Runnable { update() }
    private val visibility = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) = update()
    }

    override fun onCreate() {
        super.onCreate()
        val manager = getSystemService(NotificationManager::class.java)
        val channel = "second_hand"
        manager.createNotificationChannel(NotificationChannel(channel, getString(R.string.second_hand), NotificationManager.IMPORTANCE_LOW))
        val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
        startForeground(1, Notification.Builder(this, channel)
            .setContentTitle(getString(R.string.app_name)).setContentText(getString(R.string.legacy_seconds))
            .setSmallIcon(R.drawable.clock_mark).setContentIntent(open).setOnlyAlertOnce(true).setOngoing(true).build())
        registerReceiver(visibility, IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
            addAction(Intent.ACTION_TIME_CHANGED)
            addAction(Intent.ACTION_TIMEZONE_CHANGED)
        })
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val settings = ClockSettings.load(this)
        ids = LegacyDialUpdates.ids(this)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S || settings.variant != "analog" || !settings.seconds || ids.isEmpty()) {
            stopSelf()
            return START_NOT_STICKY
        }
        art = DialArtwork(settings)
        update()
        return START_STICKY
    }

    private fun update() {
        handler.removeCallbacks(tick)
        val drawing = art ?: return
        if (!getSystemService(PowerManager::class.java).isInteractive || getSystemService(KeyguardManager::class.java).isKeyguardLocked) return
        LegacyDialUpdates.publish(this, ids, drawing)
        handler.postDelayed(tick, 1000 - System.currentTimeMillis() % 1000)
    }

    override fun onDestroy() {
        handler.removeCallbacks(tick)
        unregisterReceiver(visibility)
        super.onDestroy()
    }
    override fun onBind(intent: Intent?): IBinder? = null
}
