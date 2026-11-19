package com.byfb.hear_clock

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
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
                    "speak" -> TimeSpeaker.read(this, call.arguments as? String) { spoken ->
                        if (spoken) result.success(null)
                        else result.error("speech", getString(R.string.speech_error), null)
                    }
                    "pinWidget" -> {
                        val manager = AppWidgetManager.getInstance(this)
                        result.success(manager.isRequestPinAppWidgetSupported && manager.requestPinAppWidget(
                            ComponentName(this, ClockWidget::class.java), null, null,
                        ))
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
