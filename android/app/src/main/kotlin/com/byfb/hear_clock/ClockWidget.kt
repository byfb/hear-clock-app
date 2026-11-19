package com.byfb.hear_clock

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Typeface
import android.os.Build
import android.os.Bundle
import android.text.SpannableString
import android.text.Spanned
import android.text.style.RelativeSizeSpan
import android.text.style.StyleSpan
import android.text.style.TypefaceSpan
import android.util.SizeF
import android.widget.RemoteViews
import android.widget.Toast
import kotlin.math.roundToInt

class ClockWidget : AppWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != SPEAK) {
            super.onReceive(context, intent)
            return
        }
        val pending = goAsync()
        TimeSpeaker.read(context) { spoken ->
            if (!spoken) Toast.makeText(context, R.string.speech_error, Toast.LENGTH_LONG).show()
            pending.finish()
        }
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val settings = ClockSettings.load(context)
        for (id in ids) update(context, manager, id, manager.getAppWidgetOptions(id), settings)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context, manager: AppWidgetManager, id: Int, options: Bundle,
    ) = update(context, manager, id, options, ClockSettings.load(context))

    companion object {
        private const val SPEAK = "com.byfb.hear_clock.SPEAK"

        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, ClockWidget::class.java))
            ClockWidget().onUpdate(context, manager, ids)
        }

        private fun update(
            context: Context, manager: AppWidgetManager, id: Int, options: Bundle,
            settings: ClockSettings,
        ) {
            fun views(width: Float, height: Float): RemoteViews {
                val view = RemoteViews(context.packageName, R.layout.clock_widget)
                val clock = R.id.widget_clock
                val locale = context.resources.configuration.locales[0]
                view.setCharSequence(clock, "setFormat12Hour", styled(settings.pattern(locale, false), settings))
                view.setCharSequence(clock, "setFormat24Hour", styled(settings.pattern(locale, true), settings))
                view.setInt(clock, "setBackgroundColor", android.graphics.Color.BLACK or settings.face)
                view.setTextColor(clock, android.graphics.Color.BLACK or settings.digits)
                // The available box sets the user's scale. TextClock fits its actual
                // localized text inside it after every resize or minute change.
                val inset = when (settings.size) { "small" -> .22f; "medium" -> .13f; else -> .045f }
                val density = context.resources.displayMetrics.density
                val horizontal = (width * inset * density).roundToInt()
                val vertical = (height * inset * density).roundToInt()
                view.setViewPadding(clock, horizontal, vertical, horizontal, vertical)
                val intent = Intent(context, ClockWidget::class.java).setAction(SPEAK)
                view.setOnClickPendingIntent(clock, PendingIntent.getBroadcast(
                    context, 0, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                ))
                return view
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                @Suppress("DEPRECATION")
                val sizes = options.getParcelableArrayList<SizeF>(AppWidgetManager.OPTION_APPWIDGET_SIZES)
                if (!sizes.isNullOrEmpty() && sizes.distinct().size <= 16) {
                    manager.updateAppWidget(id, RemoteViews(sizes.associateWith { views(it.width, it.height) }))
                    return
                }
            }
            fun dimension(key: String, fallback: Int): Float =
                options.getInt(key).takeIf { it > 0 }?.toFloat() ?: fallback.toFloat()
            val portrait = views(
                dimension(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 180),
                dimension(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 90),
            )
            val landscape = views(
                dimension(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 180),
                dimension(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 90),
            )
            manager.updateAppWidget(id, RemoteViews(landscape, portrait))
        }

        private fun styled(pattern: String, settings: ClockSettings): SpannableString =
            SpannableString(pattern).apply {
                val flags = Spanned.SPAN_INCLUSIVE_INCLUSIVE
                val family = when (settings.font) { "sans" -> "sans-serif"; "serif" -> "serif"; else -> "monospace" }
                setSpan(TypefaceSpan(family), 0, length, flags)
                if (settings.bold) setSpan(StyleSpan(Typeface.BOLD), 0, length, flags)
                val period = pattern.indexOf('a')
                if (period >= 0) setSpan(RelativeSizeSpan(.50f), period, period + 1, flags)
            }
    }
}
