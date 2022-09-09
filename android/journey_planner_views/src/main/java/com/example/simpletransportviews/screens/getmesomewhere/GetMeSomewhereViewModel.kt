package com.example.simpletransportviews.screens.getmesomewhere

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.viewModelScope
import com.citymapper.sdk.ui.search.CitymapperSearchState
import com.citymapper.sdk.ui.search.ExperimentalSearchUi
import com.citymapper.sdk.ui.search.google.googleSearchProviderFactory
import com.example.simpletransportviews.BuildConfig

class GetMeSomewhereViewModel(
  application: Application,
  savedStateHandle: SavedStateHandle
) : AndroidViewModel(application) {

  @OptIn(ExperimentalSearchUi::class)
  val searchState = CitymapperSearchState.create(
    application,
    viewModelScope,
    savedStateHandle = savedStateHandle,
    searchProviderFactory = googleSearchProviderFactory(BuildConfig.PLACES_API_KEY)
  )

}