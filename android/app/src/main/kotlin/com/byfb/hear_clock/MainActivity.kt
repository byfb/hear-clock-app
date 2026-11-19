package com.byfb.hear_clock

import android.database.ContentObserver
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var clockChannel: MethodChannel? = null
    private val timeFormatObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
        override fun onChange(selfChange: Boolean) {
            clockChannel?.invokeMethod("timeFormatChanged", AppLanguages.deviceUses24Hours(this@MainActivity))
        }
    }

    override fun onStart() {
        super.onStart()
        contentResolver.registerContentObserver(Settings.System.getUriFor(Settings.System.TIME_12_24), false, timeFormatObserver)
        ClockWidget.refresh(this)
    }

    override fun onStop() {
        contentResolver.unregisterContentObserver(timeFormatObserver)
        super.onStop()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        clockChannel?.setMethodCallHandler(null)
        clockChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        clockChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.byfb.hear_clock/clock")
        clockChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "displayPreferences" -> result.success(mapOf(
                    "language" to AppLanguages.selected(this),
                    "device24" to AppLanguages.deviceUses24Hours(this),
                ))
                "setAppLanguage" -> {
                    val tag = call.arguments as? String
                    if (tag == null || tag !in AppLanguages.supported) {
                        result.error("language", null, null)
                    } else {
                        AppLanguages.set(this, tag)
                        ClockWidget.refresh(this)
                        result.success(null)
                    }
                }
                "load" -> result.success(ClockSettings.load(this).toMap())
                "save" -> {
                    val values = call.arguments as? Map<*, *>
                    if (values == null) {
                        result.error("settings", "Expected clock settings", null)
                    } else {
                        ClockSettings.from(values).save(this)
                        ClockWidget.refresh(this)
                        result.success(null)
                    }
                }
                "languages" -> TimeSpeaker.languages(this) { languages ->
                    if (languages != null) result.success(languages)
                    else result.error("languages", AppLanguages.localized(this).getString(R.string.speech_error), null)
                }
                "speak" -> {
                    val preview = call.arguments as? Map<*, *>
                    val settings = preview?.let { ClockSettings.from(it) } ?: ClockSettings.load(this)
                    TimeSpeaker.read(this, settings) { error ->
                        if (error == null) result.success(null)
                        else result.error("speech", AppLanguages.localized(this).getString(error), null)
                    }
                }
                "pinWidget" -> result.success(ClockWidget.requestPin(this))
                else -> result.notImplemented()
            }
        }
    }
}
