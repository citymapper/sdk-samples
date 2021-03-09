package com.example.sdk.sample.ui.home

import android.Manifest
import android.app.Application
import androidx.annotation.RequiresPermission
import androidx.compose.runtime.ExperimentalComposeApi
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.runtime.snapshots.Snapshot.Companion.withMutableSnapshot
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.citymapper.sdk.core.ApiResult
import com.citymapper.sdk.core.disposable.Disposable
import com.citymapper.sdk.core.geo.Coords
import com.citymapper.sdk.core.transit.DirectionsResults
import com.citymapper.sdk.core.transit.Profile
import com.citymapper.sdk.core.transit.Route
import com.citymapper.sdk.directions.CitymapperDirections
import com.citymapper.sdk.navigation.CitymapperNavigationTracking
import com.citymapper.sdk.navigation.StartNavigationResult
import com.citymapper.sdk.navigation.TrackingConfiguration
import com.citymapper.sdk.navigation.progress.RouteProgress
import com.example.sdk.sample.ui.common.defaultCameraPosition
import com.example.sdk.sample.ui.map.MapCameraPosition
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.transformLatest
import kotlinx.coroutines.launch

@OptIn(ExperimentalComposeApi::class)
class HomeViewModel(application: Application) : AndroidViewModel(application) {

  private val navigation = CitymapperNavigationTracking.getInstance(application)
  private val routeProgressDisposable: Disposable

  var viewState by mutableStateOf(HomeViewState())

  init {
    val directions = CitymapperDirections.getInstance(application)

    viewModelScope.launch {
      snapshotFlow { viewState }
        .distinctUntilChanged { old, new ->
          old.start == new.start && old.end == new.end && old.profile == new.profile && old.availableApi == new.availableApi
        }
        .transformLatest { viewState ->
          if (viewState.start != null && viewState.end != null) {
            emit(viewState.copy(isLoading = true))
            val result = when (viewState.availableApi) {
              AvailableApi.Bikeride -> directions.planBikeRoutes(
                viewState.start,
                viewState.end,
                listOf(viewState.profile)
              ).execute()
              AvailableApi.Scooterride -> directions.planScooterRoute(
                viewState.start,
                viewState.end
              ).execute()
            }
            emit(
              viewState.copy(
                directions = result,
                isLoading = false
              )
            )
          }
        }
        .collect {
          viewState = it
        }
    }

    // TODO we'll probably want a more focused listener for whether navigation is active
    routeProgressDisposable = navigation.registerRouteProgressListener {
      viewState = viewState.copy(
        routeProgress = it
      )
    }
  }

  fun setStart(endpoint: Coords) = withMutableSnapshot {
    viewState = viewState.copy(
      start = endpoint
    )
  }

  fun setEnd(endpoint: Coords) = withMutableSnapshot {
    viewState = viewState.copy(
      end = endpoint
    )
  }

  fun setLocationPermission(hasLocationPermission: Boolean) = withMutableSnapshot {
    viewState = viewState.copy(
      hasLocationPermission = hasLocationPermission
    )
  }

  fun setProfile(profile: Profile) = withMutableSnapshot {
    viewState = viewState.copy(
      profile = profile
    )
  }

  fun setAvailableApi(availableApi: AvailableApi) = withMutableSnapshot {
    viewState = viewState.copy(
      availableApi = availableApi
    )
  }

  fun consumeApiError() = withMutableSnapshot {
    viewState = viewState.copy(
      directions = null,
      start = null,
      end = null
    )
  }

  fun dismissStartNavigationFailure() {
    viewState = viewState.copy(
      startNavigationFailure = null
    )
  }

  @RequiresPermission(Manifest.permission.ACCESS_FINE_LOCATION)
  fun startGo() {
    val route = viewState.route
      ?: return

    val trackingConfiguration = TrackingConfiguration(enableOnDeviceLogging = true)
    navigation.startNavigation(route, trackingConfiguration) { startNavigationResult ->
      // No need to handle the success case here, as the route progress listener will be called
      viewState = viewState.copy(
        startNavigationFailure = startNavigationResult as? StartNavigationResult.Failure
      )
    }
  }

  fun endGo() {
    navigation.endNavigation()
  }
}

private fun ApiResult<DirectionsResults>.firstRoute(): Route? {
  return (this as? ApiResult.Success)?.data?.routes?.firstOrNull()
}

data class HomeViewState(
  val start: Coords? = null,
  val end: Coords? = null,
  val directions: ApiResult<DirectionsResults>? = null,
  val profile: Profile = Profile.Regular,
  val isLoading: Boolean = false,
  val hasLocationPermission: Boolean? = null,
  val routeProgress: RouteProgress? = null,
  val startNavigationFailure: StartNavigationResult.Failure? = null,
  val availableApi: AvailableApi = AvailableApi.Bikeride
) {

  val isNavigationActive get() = routeProgress != null

  val route = routeProgress?.route ?: directions?.firstRoute()

  val legProgress = routeProgress?.legProgress

  fun getCameraPosition(): MapCameraPosition? {
    return when {
      isNavigationActive && start != null -> MapCameraPosition.LatLngZoom(
        latitude = start.latitude,
        longitude = start.longitude,
        zoom = 15f
      )
      directions is ApiResult.Success -> null
      else -> defaultCameraPosition()
    }
  }
}

enum class AvailableApi(val route: String) {
  Bikeride("/bikeride"), Scooterride("/scooterride")
}
