package com.byfb.hear_clock

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.drawable.Icon
import android.os.Build
import android.widget.RemoteViews
import java.util.Calendar
import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.sin

/** Both widget implementations use the same dial and hand geometry as the Flutter face. */
internal class DialArtwork(private val settings: ClockSettings, private val side: Int = 320) {
    private val center = side / 2f
    private val radius = side * .44f
    private val dial = bitmap(side, side).also { drawMarks(Canvas(it)) }

    private fun bitmap(width: Int, height: Int) =
        Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888).apply {
            // AnalogClock scales down to fit. Give its layers a common intrinsic extent
            // large enough for a tablet without sending tablet-sized bitmaps over Binder.
            density = 32
        }

    private fun drawMarks(canvas: Canvas) {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = settings.marks; strokeCap = Paint.Cap.ROUND }
        for (tick in 0 until 60) {
            canvas.save()
            canvas.rotate(tick * 6f, center, center)
            val major = tick % 5 == 0
            paint.strokeWidth = radius * if (major) .032f else .012f
            canvas.drawLine(center, center - radius, center, center - radius * if (major) .89f else .95f, paint)
            canvas.restore()
        }
        if (settings.labels == "ticks") return
        paint.typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
        paint.textSize = radius * .23f
        paint.textAlign = Paint.Align.CENTER
        val baselineOffset = -(paint.ascent() + paint.descent()) / 2
        for (hour in 1..12) {
            if (settings.labels != "numbers" && hour % 3 != 0) continue
            val angle = Math.PI * hour / 6
            canvas.drawText(hour.toString(), center + sin(angle).toFloat() * radius * .72f,
                center - cos(angle).toFloat() * radius * .72f + baselineOffset, paint)
        }
    }

    private fun pen(hand: HandStyle) = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = hand.color
        strokeCap = Paint.Cap.ROUND
        val width = when (hand.weight) { "slim" -> .05f; "bold" -> .14f; else -> .09f }
        strokeWidth = radius * hand.length / 100 * width
    }

    private fun drawHand(canvas: Canvas, x: Float, hand: HandStyle, paint: Paint) {
        canvas.drawLine(x, center, x, center - radius * hand.length / 100, paint)
    }

    private fun handIcon(name: String): Icon {
        val hand = settings.hand(name)
        val paint = pen(hand)
        val halfWidth = ceil(paint.strokeWidth / 2).toInt() + 1
        val image = bitmap(halfWidth * 2, side)
        drawHand(Canvas(image), halfWidth.toFloat(), hand, paint)
        return Icon.createWithBitmap(image)
    }

    // Reuse the same bitmaps for every size in a responsive RemoteViews update.
    private val dialIcon by lazy { Icon.createWithBitmap(dial) }
    private val hourIcon by lazy { handIcon("hour") }
    private val minuteIcon by lazy { handIcon("minute") }
    private val secondIcon by lazy { handIcon("second") }

    fun apply(view: RemoteViews) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            view.setIcon(R.id.widget_dial, "setDial", dialIcon)
            view.setIcon(R.id.widget_dial, "setHourHand", hourIcon)
            view.setIcon(R.id.widget_dial, "setMinuteHand", minuteIcon)
            view.setIcon(R.id.widget_dial, "setSecondHand", if (settings.seconds) secondIcon else null)
        } else {
            view.setImageViewBitmap(R.id.widget_dial, snapshot())
        }
    }

    fun snapshot(time: Calendar = Calendar.getInstance()): Bitmap {
        val image = dial.copy(Bitmap.Config.ARGB_8888, true)
        val canvas = Canvas(image)
        fun draw(name: String, degrees: Float) {
            val hand = settings.hand(name)
            canvas.save()
            canvas.rotate(degrees, center, center)
            drawHand(canvas, center, hand, pen(hand))
            canvas.restore()
        }
        val minute = time[Calendar.MINUTE]
        draw("hour", time[Calendar.HOUR] * 30f + minute / 2f)
        draw("minute", minute * 6f)
        if (settings.seconds) draw("second", time[Calendar.SECOND] * 6f)
        return image
    }
}
