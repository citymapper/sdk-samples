package com.example.sdk.sample

import android.app.Application
import com.example.sdk.sample.tts.GuidanceTextToSpeech

class DemoApplication : Application() {

  override fun onCreate() {
    super.onCreate()
    GuidanceTextToSpeech.init(this)
  }
}
