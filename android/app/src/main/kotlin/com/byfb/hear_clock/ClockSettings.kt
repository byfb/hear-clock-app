package com.byfb.hear_clock

import android.content.Context
import android.text.format.DateFormat
import java.util.Locale

internal data class ClockSettings(
    val digits: Int,
    val face: Int,
    val font: String,
    val size: String,
    val bold: Boolean,
    val format: String,
    val language: String,
    val speechRate: Int,
) {
    fun toMap(): Map<String, Any> = mapOf(
        "digits" to digits, "face" to face, "font" to font,
        "size" to size, "bold" to bold, "format" to format,
        "speech.language" to language, "speech.rate" to speechRate,
        "speech.label" to Locale.forLanguageTag(language).displayName,
    )

    fun save(context: Context) {
        store(context).edit()
            .putInt("digits", digits).putInt("face", face)
            .putString("font", font).putString("size", size)
            .putBoolean("bold", bold).putString("format", format)
            .putString("speech.language", language).putInt("speech.rate", speechRate)
            .apply()
    }

    fun uses24Hours(context: Context): Boolean = when (format) {
        "h24" -> true
        "h12" -> false
        else -> DateFormat.is24HourFormat(context)
    }

    fun pattern(locale: Locale, system24: Boolean): String {
        val use24 = format == "h24" || (format == "device" && system24)
        return DateFormat.getBestDateTimePattern(locale, if (use24) "Hm" else "hm")
    }

    companion object {
        private fun store(context: Context) =
            context.getSharedPreferences("clock_appearance", Context.MODE_PRIVATE)

        fun load(context: Context) = from(store(context).all)

        fun from(values: Map<*, *>): ClockSettings {
            fun color(key: String, fallback: Int): Int =
                (values[key] as? Number)?.toInt()?.takeIf { it in 0..0xFFFFFF } ?: fallback

            fun choice(key: String, fallback: String, vararg options: String): String =
                (values[key] as? String)?.takeIf { it in options } ?: fallback

            return ClockSettings(
                digits = color("digits", 0xFFF4DB),
                face = color("face", 0x22221F),
                font = choice("font", "mono", "mono", "sans", "serif"),
                size = choice("size", "large", "small", "medium", "large"),
                bold = values["bold"] as? Boolean ?: false,
                format = choice("format", "device", "device", "h12", "h24"),
                language = values["speech.language"] as? String ?: "",
                speechRate = (values["speech.rate"] as? Number)?.toInt()?.takeIf { it in 50..200 } ?: 100,
            )
        }
    }
}
