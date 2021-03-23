package com.example.sdk.sample.ui.home

import android.Manifest
import androidx.annotation.RequiresPermission
import androidx.compose.runtime.ExperimentalComposeApi
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.citymapper.sdk.core.ApiResult
import com.citymapper.sdk.core.disposable.Disposable
import com.citymapper.sdk.core.geo.Coords
import com.citymapper.sdk.core.transit.DirectionsResults
import com.citymapper.sdk.core.transit.HiredVehicleLeg
import com.citymapper.sdk.core.transit.Profile
import com.citymapper.sdk.core.transit.Route
import com.citymapper.sdk.directions.CitymapperDirections
import com.citymapper.sdk.navigation.CitymapperNavigationTracking
import com.citymapper.sdk.navigation.StartNavigationResult
import com.citymapper.sdk.navigation.TrackingConfiguration
import com.citymapper.sdk.navigation.VehicleLockState
import com.citymapper.sdk.navigation.progress.RouteProgress
import com.citymapper.sdk.navigation.ui.getPathSegments
import com.example.sdk.sample.ui.common.defaultCameraPosition
import com.example.sdk.sample.ui.map.MapCameraPosition
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.mapNotNull
import kotlinx.coroutines.flow.transformLatest
import kotlinx.coroutines.launch

@OptIn(ExperimentalComposeApi::class)
class HomeViewModel(
  private val navigation: CitymapperNavigationTracking,
  directions: CitymapperDirections,
  dataStore: DataStore<Preferences>
) : ViewModel() {

  private val routeProgressDisposable: Disposable

  var viewState by mutableStateOf(HomeViewState())

  private val brandIdPreference = stringPreferencesKey("brand_id")
  private val currentApiPreference = stringPreferencesKey("current_api")

  init {

    viewModelScope.launch {
      val brandId = dataStore.data.mapNotNull { it[brandIdPreference] }.first()
      viewState = viewState.copy(
        brandId = brandId
      )
    }

    viewModelScope.launch {
      val availableApi = dataStore.data.mapNotNull { it[currentApiPreference] }.first()
      viewState = viewState.copy(
        availableApi = AvailableApi.valueOf(availableApi)
      )
    }

    viewModelScope.launch {
      snapshotFlow { viewState }
        .mapNotNull { it.brandId }
        .distinctUntilChanged()
        .collect { brandId ->
          dataStore.edit { it[brandIdPreference] = brandId }
        }
    }

    viewModelScope.launch {
      snapshotFlow { viewState }
        .mapNotNull { it.availableApi }
        .distinctUntilChanged()
        .collect { availableApi ->
          dataStore.edit { it[currentApiPreference] = availableApi.name }
        }
    }

    viewModelScope.launch {
      snapshotFlow { viewState }
        .distinctUntilChanged { old, new ->
          old.start == new.start && old.end == new.end && old.profile == new.profile && old.availableApi == new.availableApi && old.customVehicleLocation == new.customVehicleLocation
        }
        .transformLatest { viewState ->
          if (viewState.start != null && viewState.end != null) {
            emit(viewState.copy(isLoading = true))
            val result = when (viewState.availableApi) {
              AvailableApi.Walk -> directions.planWalkRoutes(
                viewState.start,
                viewState.end
              ).execute()
              AvailableApi.Bikeride -> directions.planBikeRoutes(
                viewState.start,
                viewState.end,
                listOf(viewState.profile)
              ).execute()
              AvailableApi.Scooterride -> directions.planScooterRoute(
                viewState.start,
                viewState.end
              ).execute()
              AvailableApi.Scooter -> directions.planScooterHireRoute(
                viewState.start,
                viewState.end,
                viewState.brandId,
                viewState.customVehicleLocation
              ).execute()
              AvailableApi.Bike -> directions.planBikeHireRoute(
                viewState.start,
                viewState.end,
                viewState.brandId,
                viewState.customVehicleLocation
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

  fun setStart(endpoint: Coords) {
    viewState = viewState.copy(
      start = endpoint
    )
  }

  fun setEnd(endpoint: Coords) {
    viewState = viewState.copy(
      end = endpoint
    )
  }

  fun setLocationPermission(hasLocationPermission: Boolean) {
    viewState = viewState.copy(
      hasLocationPermission = hasLocationPermission
    )
  }

  fun setProfile(profile: Profile) {
    viewState = viewState.copy(
      profile = profile
    )
  }

  fun setAvailableApi(availableApi: AvailableApi) {
    viewState = viewState.copy(
      availableApi = availableApi,
      customVehicleLocation = null
    )
  }

  fun setCustomVehicleLocation(customVehicleLocation: Coords?) {
    if (!viewState.isNavigationActive) {
      viewState = viewState.copy(
        customVehicleLocation = customVehicleLocation
      )
    }
  }

  fun setBrandId(brandId: String) {
    viewState = viewState.copy(
      brandId = brandId
    )
  }

  fun setVehicleLockState(vehicleLockState: VehicleLockState) {
    navigation.setVehicleLockState(vehicleLockState)
    viewState = viewState.copy(
      vehicleLockState = vehicleLockState
    )
  }

  fun consumeApiError() {
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
    viewState = viewState.copy(vehicleLockState = null)
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
  val availableApi: AvailableApi = AvailableApi.Bikeride,
  val customVehicleLocation: Coords? = null,
  val brandId: String = "",
  private val vehicleLockState: VehicleLockState? = null
) {

  val isNavigationActive get() = routeProgress != null

  val route = routeProgress?.route ?: directions?.firstRoute()

  val routePathSegments = routeProgress?.pathGeometrySegments ?: route?.getPathSegments()

  val actionableVehicleLockState: VehicleLockState? get() {
    return when {
      vehicleLockState is VehicleLockState.Unlocked -> {
        vehicleLockState
      }
      routeProgress?.nextLeg is HiredVehicleLeg -> {
        VehicleLockState.Locked
      }
      else -> null
    }
  }

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
  Walk("planWalkRoutes()"),
  Bikeride("planBikeRoutes()"),
  Scooterride("planScooterRoute()"),
  Scooter("planScooterHireRoute()"),
  Bike("planBikeHireRoute()");

  companion object {
    val useCustomVehicle = listOf(Bike, Scooter)
    val needBrand = listOf(Bike, Scooter)
    val needProfile = listOf(Bike, Bikeride)
  }
}

private val RouteProgress.nextLeg get() = legProgress?.legIndex?.let {
  route.legs.getOrNull(it + 1)
}
