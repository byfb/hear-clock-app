package com.byfb.hear_clock

import android.content.Context
import android.media.AudioAttributes
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import java.text.Collator
import java.util.Date
import java.util.Locale

/** Owns the current clock reading until playback finishes or another tap replaces it. */
internal object TimeSpeaker {
    private val main = Handler(Looper.getMainLooper())
    private var current: Request? = null

    fun languages(context: Context, done: (List<Map<String, String>>?) -> Unit) {
        var engine: TextToSpeech? = null
        var complete = false
        fun finish(languages: List<Map<String, String>>?) {
            if (complete) return
            complete = true
            engine?.shutdown()
            done(languages)
        }
        val timeout = Runnable { finish(null) }
        main.postDelayed(timeout, 8000)
        try {
            engine = TextToSpeech(context.applicationContext) { status -> main.post {
                main.removeCallbacks(timeout)
                if (complete) return@post
                val tts = engine
                if (status != TextToSpeech.SUCCESS || tts == null) {
                    finish(null)
                    return@post
                }
                val result = runCatching {
                    val voices = tts.voices.orEmpty()
                    val locales = if (voices.isEmpty()) tts.availableLanguages.orEmpty()
                        else voices.filterNot { TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED in it.features.orEmpty() }
                            .map { it.locale }
                    val names = Collator.getInstance(AppLanguages.localized(context).resources.configuration.locales[0])
                    locales.filter { it.language.isNotEmpty() && it.toLanguageTag() != "und" }
                        .distinctBy { it.toLanguageTag() }
                        .sortedWith(compareBy(names) { it.getDisplayName(it) })
                        .map { mapOf("tag" to it.toLanguageTag(), "label" to it.getDisplayName(it)) }
                }
                finish(result.getOrNull())
            } }
        } catch (_: RuntimeException) {
            main.removeCallbacks(timeout)
            finish(null)
        }
    }

    fun stop() { current?.finish(null) }

    fun read(context: Context, settings: ClockSettings, done: (Int?) -> Unit) {
        stop()
        if (!settings.speakOnTap) { done(null); return }
        val app = context.applicationContext
        val locale = if (settings.language.isEmpty()) AppLanguages.deviceLocale(app)
            else Locale.forLanguageTag(settings.language)
        val timeAtTap = Date()
        val request = Request(done)
        current = request
        main.postDelayed(request.timeout, 8500)
        try {
            request.engine = TextToSpeech(app) { status ->
                main.post {
                    if (current !== request) return@post
                    val engine = request.engine
                    if (status != TextToSpeech.SUCCESS || engine == null) {
                        request.finish(R.string.speech_error)
                        return@post
                    }
                    var spokenLocale = locale
                    if (engine.setLanguage(locale) < TextToSpeech.LANG_AVAILABLE) {
                        if (settings.language.isNotEmpty()) {
                            request.finish(R.string.voice_unavailable)
                            return@post
                        }
                        spokenLocale = engine.voice?.locale ?: locale
                    }
                    if (engine.setSpeechRate(settings.speechRate / 100f) == TextToSpeech.ERROR) {
                        request.finish(R.string.speech_error)
                        return@post
                    }
                    val words = settings.spokenReading(timeAtTap, spokenLocale, AppLanguages.deviceUses24Hours(app))
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
                            main.post { request.finish(if (success) null else R.string.speech_error) }
                        }
                    })
                    if (engine.speak(words, TextToSpeech.QUEUE_FLUSH, null, "local_time") == TextToSpeech.ERROR) {
                        request.finish(R.string.speech_error)
                        return@post
                    }
                    // A full date at the slowest speech rate can outlast engine initialization.
                    main.removeCallbacks(request.timeout)
                    main.postDelayed(request.timeout, 60_000)
                }
            }
        } catch (_: RuntimeException) {
            request.finish(R.string.speech_error)
        }
    }

    private class Request(private val done: (Int?) -> Unit) {
        var engine: TextToSpeech? = null
        val timeout = Runnable { finish(R.string.speech_error) }

        fun finish(error: Int?) {
            if (current !== this) return
            current = null
            main.removeCallbacks(timeout)
            engine?.stop()
            engine?.shutdown()
            done(error)
        }
    }
}
