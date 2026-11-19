package com.byfb.hear_clock

import android.content.res.Configuration
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.filters.SdkSuppress
import androidx.test.platform.app.InstrumentationRegistry
import java.util.Locale
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class LanguageResourcesTest {
    private val context = InstrumentationRegistry.getInstrumentation().targetContext

    @Test fun widgetPickerUsesThePhonesChineseScript() {
        val expected = mapOf(
            "en" to "Tap to hear the local time. Touch and hold to resize.",
            "zh-CN" to "点一下即可听到当地时间。长按可调整大小。",
            "zh-HK" to "輕點即可聽到本地時間。長按可調整大小。",
            "zh-Hant" to "輕點即可聽到本地時間。長按可調整大小。",
        )
        for ((tag, description) in expected) {
            val config = Configuration(context.resources.configuration)
            config.setLocale(Locale.forLanguageTag(tag))
            assertEquals(tag, description, context.createConfigurationContext(config).getString(R.string.widget_description))
        }
    }

    @Test @SdkSuppress(maxSdkVersion = 32)
    fun legacyLanguageOverrideLocalizesFeedbackAndPreservesDeviceVoice() {
        val previous = AppLanguages.selected(context)
        val phoneLocale = AppLanguages.deviceLocale(context)
        try {
            AppLanguages.set(context, "zh-Hant")
            assertEquals("zh-Hant", AppLanguages.selected(context))
            assertEquals("秒針", AppLanguages.localized(context).getString(R.string.second_hand))
            assertEquals(phoneLocale, AppLanguages.deviceLocale(context))
            AppLanguages.set(context, "")
            assertEquals(context.getString(R.string.second_hand), AppLanguages.localized(context).getString(R.string.second_hand))
        } finally {
            AppLanguages.set(context, previous)
        }
    }
}
