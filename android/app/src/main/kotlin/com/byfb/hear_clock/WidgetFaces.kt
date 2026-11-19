package com.byfb.hear_clock

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Typeface
import android.text.SpannableString
import android.text.Spanned
import android.text.style.RelativeSizeSpan
import android.text.style.StyleSpan
import android.text.style.TypefaceSpan
import android.view.View
import android.widget.RemoteViews

internal class WidgetFaces(private val context: Context, private val settings: ClockSettings) {
    private val dial = if (settings.variant == "analog") DialArtwork(settings) else null
    private val locale = context.resources.configuration.locales[0]
    private val speak = PendingIntent.getBroadcast(context, 0,
        Intent(context, ClockWidget::class.java).setAction(ClockWidget.SPEAK),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)

    fun views(): RemoteViews {
        val (layout, fraction) = when {
            dial != null -> R.layout.clock_analog to 1f
            settings.size == "small" -> R.layout.clock_widget_small to .56f
            settings.size == "medium" -> R.layout.clock_widget_medium to .74f
            else -> R.layout.clock_widget to .91f
        }
        val view = RemoteViews(context.packageName, layout)
        view.setInt(R.id.widget_surface, "setBackgroundColor", settings.face)
        view.setOnClickPendingIntent(R.id.widget_surface, speak)
        val short = settings.pattern(locale, false)
        val long = settings.pattern(locale, true)
        // The transparent TextClock over a composed face is its one live, accessible action.
        view.setCharSequence(R.id.widget_clock, "setFormat12Hour", short)
        view.setCharSequence(R.id.widget_clock, "setFormat24Hour", long)
        view.setOnClickPendingIntent(R.id.widget_clock, speak)
        if (dial != null) {
            dial.apply(view)
            return view
        }
        // Let the host measure the digits against the space it actually gives this widget.
        view.setFloat(R.id.digit_width, "setWeightSum", 1f / fraction)
        view.setFloat(R.id.digit_height, "setWeightSum", 1f / fraction)
        val stacked = settings.variant == "stacked"
        view.setViewVisibility(R.id.digital_digits, if (stacked) View.GONE else View.VISIBLE)
        view.setViewVisibility(R.id.stack_hour, if (stacked) View.VISIBLE else View.GONE)
        view.setViewVisibility(R.id.stack_minute, if (stacked) View.VISIBLE else View.GONE)
        if (stacked) {
            styleLine(view, R.id.stack_hour, settings.pattern(locale, false, true),
                settings.pattern(locale, true, true), settings.digits)
            styleLine(view, R.id.stack_minute, "mm", "mm", settings.minutes)
        } else {
            styleLine(view, R.id.digital_digits, short, long, settings.digits)
        }
        return view
    }

    private fun styleLine(view: RemoteViews, id: Int, short: String, long: String,
        color: Int) {
        view.setCharSequence(id, "setFormat12Hour", styled(short))
        view.setCharSequence(id, "setFormat24Hour", styled(long))
        view.setTextColor(id, color)
    }

    private fun styled(pattern: String) = SpannableString(pattern).apply {
        val flags = Spanned.SPAN_INCLUSIVE_INCLUSIVE
        val family = when (settings.font) { "sans" -> "sans-serif"; "serif" -> "serif"; else -> "monospace" }
        setSpan(TypefaceSpan(family), 0, length, flags)
        if (settings.bold) setSpan(StyleSpan(Typeface.BOLD), 0, length, flags)
        val period = pattern.indexOf('a')
        if (period >= 0) setSpan(RelativeSizeSpan(.5f), period, period + 1, flags)
    }
}
