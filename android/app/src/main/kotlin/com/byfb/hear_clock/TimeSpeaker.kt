package com.byfb.hear_clock

import android.content.Context
import android.media.AudioAttributes
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import java.text.SimpleDateFormat
import java.util.Date

/** Owns one short utterance, including the lifetime of a launcher broadcast. */
internal object TimeSpeaker {
    private val main = Handler(Looper.getMainLooper())
    private var current: Request? = null

    fun read(context: Context, previewFormat: String? = null, done: (Boolean) -> Unit) {
        current?.finish(true)
        val app = context.applicationContext
        val locale = app.resources.configuration.locales[0]
        val saved = ClockSettings.load(app)
        val settings = if (previewFormat in listOf("device", "h12", "h24")) {
            saved.copy(format = requireNotNull(previewFormat))
        } else saved
        val pattern = settings.pattern(locale, settings.uses24Hours(app))
        val timeAtTap = SimpleDateFormat(pattern, locale).format(Date())
        val request = Request(done)
        current = request
        main.postDelayed(request.timeout, 8500)
        try {
            request.engine = TextToSpeech(app) { status ->
                main.post {
                    if (current !== request) return@post
                    val engine = request.engine
                    if (status != TextToSpeech.SUCCESS || engine == null) {
                        request.finish(false)
                        return@post
                    }
                    // Fall back to the engine's preferred voice when this locale is unavailable.
                    if (engine.isLanguageAvailable(locale) >= TextToSpeech.LANG_AVAILABLE) {
                        engine.language = locale
                    }
                    engine.setAudioAttributes(
                        AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build(),
                    )
                    engine.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                        override fun onStart(id: String?) = Unit
                        override fun onDone(id: String?) = postResult(true)
                        @Deprecated("Required by Android's listener")
                        override fun onError(id: String?) = postResult(false)
                        override fun onError(id: String?, errorCode: Int) = postResult(false)
                        private fun postResult(success: Boolean) {
                            main.post { request.finish(success) }
                        }
                    })
                    if (engine.speak(timeAtTap, TextToSpeech.QUEUE_FLUSH, null, "local_time") ==
                        TextToSpeech.ERROR) request.finish(false)
                }
            }
        } catch (_: RuntimeException) {
            request.finish(false)
        }
    }

    private class Request(private val done: (Boolean) -> Unit) {
        var engine: TextToSpeech? = null
        val timeout = Runnable { finish(false) }

        fun finish(success: Boolean) {
            if (current !== this) return
            current = null
            main.removeCallbacks(timeout)
            engine?.stop()
            engine?.shutdown()
            done(success)
        }
    }
}
