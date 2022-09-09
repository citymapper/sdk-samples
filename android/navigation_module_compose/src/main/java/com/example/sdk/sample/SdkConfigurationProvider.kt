package com.example.sdk.sample

import android.content.Context
import com.citymapper.sdk.configuration.CitymapperSdkConfiguration

@Suppress("unused")
class SdkConfigurationProvider : CitymapperSdkConfiguration.Provider {

  override fun provideCitymapperSdkConfiguration(context: Context): CitymapperSdkConfiguration {
    return CitymapperSdkConfiguration(
      apiKey = BuildConfig.CITYMAPPER_API_KEY
    )
  }
}
