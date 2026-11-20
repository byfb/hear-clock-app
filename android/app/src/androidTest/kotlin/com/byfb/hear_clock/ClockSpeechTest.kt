package com.byfb.hear_clock

import androidx.test.ext.junit.runners.AndroidJUnit4
import java.text.DateFormat
import java.util.Calendar
import java.util.GregorianCalendar
import java.util.Locale
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ClockSpeechTest {
    @Test fun dateFollowsTheVoiceLanguageAndTheLocalDayAtTheTap() {
        val timeOnly = ClockSettings.from(mapOf("format" to "h24", "seconds" to true))
        val withDate = ClockSettings.from(timeOnly.toMap() + ("speech.includeDate" to true))
        val clock = GregorianCalendar().apply {
            clear()
            set(2026, Calendar.DECEMBER, 31, 23, 59, 58)
        }
        for (expectedTime in listOf("23:59:58", "00:00:01")) {
            val at = clock.time
            assertEquals(expectedTime, timeOnly.spokenReading(at, Locale.UK, system24 = false))
            for (locale in listOf(Locale.UK, Locale.FRANCE, Locale.SIMPLIFIED_CHINESE, Locale.forLanguageTag("zh-HK"))) {
                val time = timeOnly.spokenReading(at, locale, system24 = false)
                val day = DateFormat.getDateInstance(DateFormat.FULL, locale).format(at)
                assertEquals("$time\n$day", withDate.spokenReading(at, locale, system24 = false))
            }
            clock.add(Calendar.SECOND, 3)
        }
    }
}
