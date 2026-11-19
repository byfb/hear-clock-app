package com.byfb.hear_clock

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onStart() {
        super.onStart()
        ClockWidget.refresh(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.byfb.hear_clock/clock")
            .setMethodCallHandler { call, result ->
                when (call.method) {
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
                        else result.error("languages", getString(R.string.speech_error), null)
                    }
                    "speak" -> {
                        val preview = call.arguments as? Map<*, *>
                        val settings = preview?.let { ClockSettings.from(it) } ?: ClockSettings.load(this)
                        TimeSpeaker.read(this, settings) { error ->
                            if (error == null) result.success(null)
                            else result.error("speech", getString(error), null)
                        }
                    }
                    "pinWidget" -> result.success(ClockWidget.requestPin(this))
                    else -> result.notImplemented()
                }
            }
    }
}
