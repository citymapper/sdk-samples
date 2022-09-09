package com.example.sdk.sample.tts

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import androidx.annotation.RequiresApi
import com.citymapper.sdk.navigation.CitymapperNavigationTracking
import com.citymapper.sdk.navigation.internal.events.GuidanceEvent
import com.citymapper.sdk.navigation.internal.events.GuidanceEventListener
import java.util.Locale
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

// The TTS volume tends to sound loud compared to other audio on the same
// volume stream. Avoid deafening people who are listening to their music
// or podcasts with voice enabled
private const val RELATIVE_TTS_VOLUME = 0.6f

class GuidanceTextToSpeech private constructor(private val context: Context) :
  GuidanceEventListener {

  private val textToSpeech = TextToSpeech(context, Locale.getDefault())
  private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

  private fun start() {
    CitymapperNavigationTracking.getInstance(context).registerGuidanceEventListener(this)
  }

  override fun onTriggerGuidanceEvent(guidanceEvent: GuidanceEvent) {
    scope.launch {
      textToSpeech.speak(
        SpokenMessage(
          messageId = guidanceEvent.id,
          message = guidanceEvent.createSpeechText(context)
        )
      )
    }
  }

  companion object {

    fun init(context: Context) {
      GuidanceTextToSpeech(context).start()
    }
  }
}

private class TextToSpeech constructor(private val context: Context, private val locale: Locale) {

  private val job = SupervisorJob()
  private val coroutineScope = CoroutineScope(job + Dispatchers.Default)
  private val messageChannel = Channel<SpokenMessage>(Channel.BUFFERED)
  private var textToSpeechEngine: TextToSpeech? = null
  private val audioManager by lazy { context.getSystemService(Context.AUDIO_SERVICE) as AudioManager }
  private var audioFocusRequest: AudioFocusRequest? = null
  private val state = MutableStateFlow<State>(State.Uninitialized)

  init {
    coroutineScope.launch {
      val (tts, error) = createTts()
      textToSpeechEngine = tts
      if (error != null) {
        setState(error)
        return@launch
      }

      for (msg in messageChannel) {
        handleMessage(tts, msg)
      }
    }
  }

  private suspend fun createTts(): Pair<TextToSpeech, State.InitializationError?> {
    val deferred = CompletableDeferred<Int>()
    val textToSpeechEngine = TextToSpeech(context) { result ->
      deferred.complete(result)
    }

    val ttsResult = deferred.await()
    val error = if (ttsResult == TextToSpeech.SUCCESS) {
      textToSpeechEngine.configure()
    } else {
      State.InitializationError("Init listener returned error")
    }
    return Pair(textToSpeechEngine, error)
  }

  suspend fun speak(message: SpokenMessage) {
    if (audioManager.mode == AudioManager.MODE_NORMAL) {
      messageChannel.send(message)
    }
  }

  private suspend fun handleMessage(tts: TextToSpeech, message: SpokenMessage) {
    setState(State.Speaking(message.messageId))
    tts.speak(
      message.message,
      TextToSpeech.QUEUE_FLUSH,
      Bundle().apply {
        putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, RELATIVE_TTS_VOLUME)
      },
      message.messageId
    )

    if (!message.isInterruptable) {
      awaitFinishedSpeaking(message)
    }
  }

  private suspend fun awaitFinishedSpeaking(message: SpokenMessage) {
    state.first { it !is State.Speaking || it.utteranceId != message.messageId }
  }

  private fun TextToSpeech.configure(): State.InitializationError? {
    val result = setLanguage(locale)
    if (result < TextToSpeech.LANG_AVAILABLE) {
      return State.InitializationError(
        when (result) {
          TextToSpeech.LANG_MISSING_DATA -> "Missing language data"
          TextToSpeech.LANG_NOT_SUPPORTED -> "Language not supported"
          else -> "Unknown setLanguage error $result"
        }
      )
    }

    setupUtteranceListener()
    setAudioAttributes(getAudioAttributes())
    return null
  }

  private fun getAudioAttributes(): AudioAttributes {
    return AudioAttributes.Builder()
      .setUsage(AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE)
      .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
      .build()
  }

  private fun TextToSpeech.setupUtteranceListener() {
    setOnUtteranceProgressListener(object : UtteranceProgressListener() {
      override fun onDone(utteranceId: String) {
        abandonAudioFocus()
        onUtteranceFinishedWithResult(utteranceId, LastUtteranceResult.Success)
      }

      override fun onError(utteranceId: String) {
        abandonAudioFocus()
        onUtteranceFinishedWithResult(utteranceId, LastUtteranceResult.Error)
      }

      override fun onStart(utteranceId: String) {
        takeAudioFocus()
      }
    })
  }

  private fun onUtteranceFinishedWithResult(utteranceId: String, result: LastUtteranceResult) {
    setState(
      State.Idle(result),
      ifCurrentState = { it is State.Speaking && it.utteranceId == utteranceId }
    )
  }

  fun stopSpeaking() {
    textToSpeechEngine?.stop()
    abandonAudioFocus()
  }

  fun shutdown() {
    coroutineScope.cancel()
    stopSpeaking()
    textToSpeechEngine?.shutdown()
    textToSpeechEngine = null
  }

  private inline fun setState(newState: State, ifCurrentState: (State) -> Boolean = { true }) =
    synchronized(state) {
      if (ifCurrentState(state.value)) {
        state.value = newState
      }
    }

  @RequiresApi(Build.VERSION_CODES.O)
  private fun getAudioFocusRequest(): AudioFocusRequest {
    if (audioFocusRequest == null) {
      audioFocusRequest =
        AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK).run {
          setAudioAttributes(getAudioAttributes())
          build()
        }
    }
    return audioFocusRequest!!
  }

  private fun takeAudioFocus() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      audioManager.requestAudioFocus(getAudioFocusRequest())
    } else {
      @Suppress("DEPRECATION")
      audioManager.requestAudioFocus(
        {},
        AudioManager.STREAM_NOTIFICATION,
        AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK
      )
    }
  }

  private fun abandonAudioFocus() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      audioManager.abandonAudioFocusRequest(getAudioFocusRequest())
    } else {
      @Suppress("DEPRECATION")
      audioManager.abandonAudioFocus {}
    }
  }

  private sealed class State {
    object Uninitialized : State()
    data class InitializationError(val message: String) : State()
    data class Idle(val lastUtteranceResult: LastUtteranceResult?) : State()
    data class Speaking(val utteranceId: String) : State()
  }

  private sealed class LastUtteranceResult {
    object Success : LastUtteranceResult()
    object Error : LastUtteranceResult()
  }
}

data class SpokenMessage(
  val message: String,
  val messageId: String,
  val isInterruptable: Boolean = true
)
