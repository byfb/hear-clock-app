package com.byfb.hear_clock

import android.app.LocaleManager
import android.content.Context
import android.content.res.Configuration
import android.os.Build
import android.os.LocaleList
import android.text.format.DateFormat
import java.util.Locale

internal object AppLanguages {
    private const val KEY = "language"
    val supported = setOf("", "en", "zh-Hans", "zh-Hant")
    private fun legacy(context: Context) =
        context.getSharedPreferences("app_language", Context.MODE_PRIVATE)

    fun selected(context: Context): String {
        val preferences = legacy(context)
        if (Build.VERSION.SDK_INT < 33) return preferences.getString(KEY, "").orEmpty()
        val manager = context.getSystemService(LocaleManager::class.java)
        // Carry the pre-Android 13 choice across an OS upgrade once.
        if (preferences.contains(KEY)) {
            val saved = preferences.getString(KEY, "").orEmpty()
            if (manager.applicationLocales.isEmpty && saved.isNotEmpty()) {
                manager.applicationLocales = LocaleList.forLanguageTags(saved)
            }
            preferences.edit().remove(KEY).apply()
        }
        return manager.applicationLocales.takeUnless { it.isEmpty }?.get(0)?.toLanguageTag().orEmpty()
    }

    fun set(context: Context, tag: String) {
        if (Build.VERSION.SDK_INT >= 33) {
            context.getSystemService(LocaleManager::class.java).applicationLocales = LocaleList.forLanguageTags(tag)
            legacy(context).edit().remove(KEY).apply()
        } else {
            legacy(context).edit().putString(KEY, tag).apply()
        }
    }

    fun localized(context: Context): Context {
        if (Build.VERSION.SDK_INT >= 33) return context
        val tag = selected(context)
        if (tag.isEmpty()) return context
        val config = Configuration(context.resources.configuration)
        config.setLocale(Locale.forLanguageTag(tag))
        return context.createConfigurationContext(config)
    }

    fun deviceLocale(context: Context): Locale =
        if (Build.VERSION.SDK_INT >= 33) context.getSystemService(LocaleManager::class.java).systemLocales[0]
        else context.resources.configuration.locales[0]

    fun deviceUses24Hours(context: Context): Boolean {
        val device = deviceLocale(context)
        if (context.resources.configuration.locales[0] == device) return DateFormat.is24HourFormat(context)
        val config = Configuration(context.resources.configuration)
        config.setLocale(device)
        return DateFormat.is24HourFormat(context.createConfigurationContext(config))
    }
}
