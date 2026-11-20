package com.byfb.hear_clock

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.Toast

class ClockWidget : AppWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == PINNED || intent.action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            intent.action == LegacyDialUpdates.TICK || intent.action == Intent.ACTION_TIME_CHANGED ||
            intent.action == Intent.ACTION_TIMEZONE_CHANGED || intent.action == Intent.ACTION_LOCALE_CHANGED) {
            refresh(context)
            return
        }
        if (intent.action != SPEAK) {
            super.onReceive(context, intent)
            return
        }
        val settings = ClockSettings.load(context)
        if (!settings.speakOnTap) return
        val pending = goAsync()
        TimeSpeaker.read(context, settings) { error ->
            if (error != null) Toast.makeText(context, AppLanguages.localized(context).getString(error), Toast.LENGTH_LONG).show()
            pending.finish()
        }
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        publish(context, manager, ids)
        LegacyDialUpdates.sync(context)
    }

    override fun onDisabled(context: Context) = LegacyDialUpdates.stop(context)
    override fun onDeleted(context: Context, appWidgetIds: IntArray) = LegacyDialUpdates.sync(context)

    override fun onAppWidgetOptionsChanged(
        context: Context, manager: AppWidgetManager, id: Int, options: Bundle,
    ) = publish(context, manager, intArrayOf(id))

    companion object {
        internal const val SPEAK = "com.byfb.hear_clock.SPEAK"
        private const val PINNED = "com.byfb.hear_clock.WIDGET_PINNED"

        fun requestPin(context: Context): Boolean {
            val manager = AppWidgetManager.getInstance(context)
            if (!manager.isRequestPinAppWidgetSupported) return false
            val pinned = PendingIntent.getBroadcast(context, 0,
                Intent(context, ClockWidget::class.java).setAction(PINNED),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
            val extras = Bundle().apply {
                putParcelable(AppWidgetManager.EXTRA_APPWIDGET_PREVIEW,
                    WidgetFaces(context, ClockSettings.load(context)).views())
            }
            return manager.requestPinAppWidget(ComponentName(context, ClockWidget::class.java), extras, pinned)
        }

        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, ClockWidget::class.java))
            if (ids.isNotEmpty()) ClockWidget().onUpdate(context, manager, ids)
        }

        private fun publish(context: Context, manager: AppWidgetManager, ids: IntArray) {
            manager.updateAppWidget(ids, WidgetFaces(context, ClockSettings.load(context)).views())
        }
    }
}
