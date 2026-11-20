package com.byfb.hear_clock

import android.content.Context
import android.graphics.Color
import android.text.format.DateFormat
import java.util.Locale

internal data class HandStyle(val color: Int, val length: Int, val weight: String)

internal class ClockSettings private constructor(private val values: Map<*, *>) {
    private fun color(key: String, fallback: Int): Int =
        ((values[key] as? Number)?.toLong()?.takeIf { it in 0L..0xffffffL }?.toInt() ?: fallback) or Color.BLACK

    private fun amount(key: String, range: IntRange, fallback: Int): Int =
        (values[key] as? Number)?.toInt()?.takeIf { it in range } ?: fallback

    val variant = when (values["variant"]) {
        "stacked" -> "stacked"
        "analog" -> "analog"
        else -> "digital"
    }
    private val prefix = if (variant == "stacked") "stack." else ""
    val face = color(if (variant == "analog") "dial.face" else prefix + "face", 0x22221F)
    val digits = color(prefix + "digits", 0xFFF4DB)
    val minutes = color("stack.minutes", 0xA4DCFF)
    val font = values[prefix + "font"] as? String ?: "mono"
    val size = values[prefix + "size"] as? String ?: "large"
    val bold = values[prefix + "bold"] == true
    val padHour = values[prefix + "padHour"] == true
    val marks = color("dial.marks", 0xC0BCAF)
    val labels = values["dial.labels"] as? String ?: "quarters"
    val seconds = when (variant) {
        "analog" -> values["dial.seconds"] == true
        "stacked" -> false
        else -> values["seconds"] == true
    }
    val speakOnTap = values["speech.enabled"] != false
    val language = values["speech.language"] as? String ?: ""
    val speechRate = amount("speech.rate", 50..200, 100)
    private val format = values["format"] as? String ?: "device"

    fun hand(name: String): HandStyle {
        val default = when (name) {
            "hour" -> HandStyle(0xFFF4DB, 55, "bold")
            "minute" -> HandStyle(0xFFA66B, 80, "regular")
            else -> HandStyle(0xA4DCFF, 90, "slim")
        }
        return HandStyle(color("$name.color", default.color), amount("$name.length", 35..95, default.length),
            values["$name.weight"] as? String ?: default.weight)
    }

    fun toMap(): Map<String, Any> = buildMap {
        for ((key, value) in this@ClockSettings.values) if (key is String && value != null) put(key, value)
        val voiceLocale = Locale.forLanguageTag(language)
        put("speech.label", voiceLocale.getDisplayName(voiceLocale))
    }

    fun save(context: Context) {
        val editor = store(context).edit()
        // The unprefixed digital fields retain the schema used by version 0.1.
        for ((key, value) in values) {
            if (key !is String) continue
            when (value) {
                is String -> editor.putString(key, value)
                is Number -> editor.putInt(key, value.toInt())
                is Boolean -> editor.putBoolean(key, value)
            }
        }
        editor.apply()
    }

    fun uses24Hours(context: Context): Boolean = use24(AppLanguages.deviceUses24Hours(context))

    private fun use24(system24: Boolean): Boolean = when (format) {
        "h12" -> false
        "h24" -> true
        else -> system24
    }

    fun pattern(locale: Locale, system24: Boolean, hourOnly: Boolean = false, spoken: Boolean = false): String {
        val cycle = if (use24(system24)) "H" else "h"
        val precision = when {
            hourOnly -> ""
            seconds -> "ms"
            else -> "m"
        }
        val pattern = DateFormat.getBestDateTimePattern(locale, cycle + precision)
        return if (!spoken && !use24(system24) && padHour && variant != "analog") {
            pattern.replace(Regex("h+"), "hh")
        } else pattern
    }

    companion object {
        private fun store(context: Context) = context.getSharedPreferences("clock_appearance", Context.MODE_PRIVATE)
        fun load(context: Context) = ClockSettings(store(context).all)
        fun from(values: Map<*, *>) = ClockSettings(values)
    }
}
