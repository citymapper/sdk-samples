package com.example.simpletransportviews.screens.getmesomewhere

import android.app.Application
import androidx.core.graphics.PathUtils.flatten
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.citymapper.sdk.core.ApiResult
import com.citymapper.sdk.core.transit.DepartOrArriveConstraint
import com.citymapper.sdk.core.transit.DirectionsResults
import com.citymapper.sdk.core.transit.Route
import com.citymapper.sdk.directions.CitymapperDirections
import com.citymapper.sdk.directions.results.DirectionsError
import com.citymapper.sdk.ui.search.CitymapperSearchState
import com.citymapper.sdk.ui.search.ExperimentalSearchUi
import com.citymapper.sdk.ui.search.RoutePlanningSpec
import com.citymapper.sdk.ui.search.provider.SearchResult
import com.example.simpletransportviews.util.Async
import com.example.simpletransportviews.util.Failure
import com.example.simpletransportviews.util.Loading
import com.example.simpletransportviews.util.Success
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

@OptIn(ExperimentalSearchUi::class, ExperimentalCoroutinesApi::class)
class RouteResultsViewModel(
  application: Application
) : AndroidViewModel(application) {

  private val directions = CitymapperDirections.getInstance(application)

  private var planJob: Job? = null
  private var currentResolvedSpec: RoutePlanningSpec? = null
  private val searchState = MutableStateFlow<CitymapperSearchState?>(null)

  private val _results = MutableStateFlow<Async<List<Route>, Any>>(Loading)

  val results = _results.asStateFlow()

  init {
    viewModelScope.launch {
      searchState.filterNotNull()
        .flatMapLatest { it.resolvedState.filterNotNull() }
        .distinctUntilChanged { old, new -> new.requiresReplan(old) }
        .collect {
          currentResolvedSpec = it
          planRoutes()
        }
    }
  }

  fun setSearchState(searchState: CitymapperSearchState) {
    this.searchState.value = searchState
  }

  fun refresh() {
    planRoutes()
  }

  private fun planRoutes() {
    planJob?.cancel()
    val spec = currentResolvedSpec
      ?: return

    viewModelScope.launch {
      _results.value = Loading
      _results.value =
        when (val result = planRoutesInternal(spec.start, spec.end, spec.timeConstraint)) {
          is ApiResult.Success -> Success(result.data)
          is ApiResult.Failure -> Failure()
        }
    }
  }

  private suspend fun planRoutesInternal(
    start: SearchResult,
    end: SearchResult,
    timeConstraint: DepartOrArriveConstraint
  ): ApiResult<List<Route>, DirectionsError> {
    return coroutineScope {
      val walk = async { directions.planWalkRoutes(start.coords, end.coords).execute() }
      val bike = async { directions.planBikeRoutes(start.coords, end.coords).execute() }
      val transit =
        async { directions.planTransitRoutes(start.coords, end.coords, timeConstraint).execute() }

      flatten(awaitAll(walk, bike, transit))
    }
  }

  private fun flatten(allResults: List<ApiResult<DirectionsResults, DirectionsError>>) =
    if (allResults.all { it is ApiResult.Failure }) {
      allResults.first() as ApiResult.Failure<DirectionsError>
    } else {
      ApiResult.success(
        allResults.flatMap {
          it.getSuccessDataOrNull()?.routes ?: emptyList()
        }
      )
    }
}