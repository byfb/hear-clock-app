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
import android.widget.RemoteViews
import kotlin.math.roundToInt

internal class WidgetFaces(private val context: Context, private val settings: ClockSettings) {
    private val dial = if (settings.variant == "analog") DialArtwork(settings) else null
    private val locale = context.resources.configuration.locales[0]
    private val speak = PendingIntent.getBroadcast(context, 0,
        Intent(context, ClockWidget::class.java).setAction(ClockWidget.SPEAK),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)

    fun views(width: Float, height: Float): RemoteViews {
        val layout = when (settings.variant) {
            "stacked" -> R.layout.clock_stacked
            "analog" -> R.layout.clock_analog
            else -> R.layout.clock_widget
        }
        val view = RemoteViews(context.packageName, layout)
        val surface = if (settings.variant == "digital") R.id.widget_clock else R.id.widget_surface
        view.setInt(surface, "setBackgroundColor", settings.face)
        val short = settings.pattern(locale, false)
        val long = settings.pattern(locale, true)
        // The transparent TextClock over a composed face is its one live, accessible action.
        view.setCharSequence(R.id.widget_clock, "setFormat12Hour", short)
        view.setCharSequence(R.id.widget_clock, "setFormat24Hour", long)
        view.setOnClickPendingIntent(R.id.widget_clock, speak)
        when (settings.variant) {
            "analog" -> dial!!.apply(view)
            "stacked" -> {
                styleLine(view, R.id.stack_hour, settings.pattern(locale, false, true),
                    settings.pattern(locale, true, true), settings.digits, width, height / 2)
                styleLine(view, R.id.stack_minute, "mm", "mm", settings.minutes, width, height / 2)
            }
            else -> styleLine(view, R.id.widget_clock, short, long, settings.digits, width, height)
        }
        return view
    }

    private fun styleLine(view: RemoteViews, id: Int, short: String, long: String,
        color: Int, width: Float, height: Float) {
        view.setCharSequence(id, "setFormat12Hour", styled(short))
        view.setCharSequence(id, "setFormat24Hour", styled(long))
        view.setTextColor(id, color)
        val inset = when (settings.size) { "small" -> .22f; "medium" -> .13f; else -> .045f }
        val density = context.resources.displayMetrics.density
        val x = (width * inset * density).roundToInt()
        val y = (height * inset * density).roundToInt()
        view.setViewPadding(id, x, y, x, y)
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
