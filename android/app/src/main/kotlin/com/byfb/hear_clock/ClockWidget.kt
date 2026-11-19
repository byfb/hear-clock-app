package com.byfb.hear_clock

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.widget.RemoteViews
import android.widget.Toast

class ClockWidget : AppWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == LegacyDialUpdates.TICK || intent.action == Intent.ACTION_TIME_CHANGED ||
            intent.action == Intent.ACTION_TIMEZONE_CHANGED || intent.action == Intent.ACTION_LOCALE_CHANGED) {
            refresh(context)
            return
        }
        if (intent.action != SPEAK) {
            super.onReceive(context, intent)
            return
        }
        val pending = goAsync()
        TimeSpeaker.read(context) { error ->
            if (error != null) Toast.makeText(context, error, Toast.LENGTH_LONG).show()
            pending.finish()
        }
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val settings = ClockSettings.load(context)
        for (id in ids) update(context, manager, id, manager.getAppWidgetOptions(id), settings)
        LegacyDialUpdates.sync(context)
    }

    override fun onDisabled(context: Context) = LegacyDialUpdates.stop(context)
    override fun onDeleted(context: Context, appWidgetIds: IntArray) = LegacyDialUpdates.sync(context)

    override fun onAppWidgetOptionsChanged(
        context: Context, manager: AppWidgetManager, id: Int, options: Bundle,
    ) = update(context, manager, id, options, ClockSettings.load(context))

    companion object {
        internal const val SPEAK = "com.byfb.hear_clock.SPEAK"

        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, ClockWidget::class.java))
            ClockWidget().onUpdate(context, manager, ids)
        }

        private fun update(
            context: Context, manager: AppWidgetManager, id: Int, options: Bundle,
            settings: ClockSettings,
        ) {
            val faces = WidgetFaces(context, settings)
            if (settings.variant == "analog") {
                // The dial fits its host in either orientation without a size-specific layout.
                manager.updateAppWidget(id, faces.views(0f, 0f))
                return
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                @Suppress("DEPRECATION")
                val sizes = options.getParcelableArrayList<SizeF>(AppWidgetManager.OPTION_APPWIDGET_SIZES)
                if (!sizes.isNullOrEmpty() && sizes.distinct().size <= 16) {
                    manager.updateAppWidget(id, RemoteViews(sizes.associateWith { faces.views(it.width, it.height) }))
                    return
                }
            }
            fun dimension(key: String, fallback: Int): Float =
                options.getInt(key).takeIf { it > 0 }?.toFloat() ?: fallback.toFloat()
            val portrait = faces.views(
                dimension(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 180),
                dimension(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 90),
            )
            val landscape = faces.views(
                dimension(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 180),
                dimension(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 90),
            )
            manager.updateAppWidget(id, RemoteViews(landscape, portrait))
        }

    }
}
