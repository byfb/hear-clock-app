package com.byfb.hear_clock

import android.appwidget.AppWidgetHostView
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.view.View
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class WidgetLayoutTest {
    @Test fun digitsFitTheHostAndTheWholeFaceRemainsTappable() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        val provider = ComponentName(context, ClockWidget::class.java)
        val info = AppWidgetManager.getInstance(context).installedProviders.single { it.provider == provider }
        instrumentation.runOnMainSync {
            val host = AppWidgetHostView(context)
            host.setAppWidget(AppWidgetManager.INVALID_APPWIDGET_ID, info)
            host.setPadding(0, 0, 0, 0)

            fun show(variant: String, size: String) {
                val settings = ClockSettings.from(mapOf("variant" to variant, "size" to size, "stack.size" to size))
                host.updateAppWidget(WidgetFaces(context, settings).views())
            }

            fun expectBounds(width: Int, height: Int, fraction: Double, rows: Int) {
                host.measure(View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY),
                    View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY))
                host.layout(0, 0, width, height)
                val ids = if (rows == 1) listOf(R.id.digital_digits) else listOf(R.id.stack_hour, R.id.stack_minute)
                for (id in ids) {
                    val digits = host.findViewById<View>(id)
                    assertEquals(View.VISIBLE, digits.visibility)
                    assertEquals(width * fraction, (digits.width - digits.paddingLeft - digits.paddingRight).toDouble(), 2.0)
                    assertEquals(height * fraction / rows, (digits.height - digits.paddingTop - digits.paddingBottom).toDouble(), 2.0)
                }
                val action = host.findViewById<View>(R.id.widget_clock)
                assertTrue(action.isClickable)
                assertEquals(width, action.width)
                assertEquals(height, action.height)
                assertEquals(View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS,
                    host.findViewById<View>(R.id.digit_width).importantForAccessibility)
            }

            show("digital", "small")
            expectBounds(240, 120, .56, 1)
            show("digital", "large")
            expectBounds(240, 120, .91, 1)
            // A launcher can resize an existing view without sending new size options.
            expectBounds(120, 240, .91, 1)
            show("stacked", "medium")
            expectBounds(120, 240, .74, 2)
        }
    }
}
