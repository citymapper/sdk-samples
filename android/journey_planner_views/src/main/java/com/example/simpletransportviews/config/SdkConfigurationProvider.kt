package com.example.simpletransportviews.config

import android.content.Context
import com.citymapper.sdk.configuration.CitymapperSdkConfiguration
import com.example.simpletransportviews.BuildConfig

@Suppress("unused")
class SdkConfigurationProvider: CitymapperSdkConfiguration.Provider {
  override fun provideCitymapperSdkConfiguration(context: Context): CitymapperSdkConfiguration {
    return CitymapperSdkConfiguration(apiKey = BuildConfig.CITYMAPPER_API_KEY)
  }
}
