package com.example.sdk.sample.ui.home

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.AlertDialog
import androidx.compose.material.Text
import androidx.compose.material.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.citymapper.sdk.core.ApiResult
import com.citymapper.sdk.navigation.StartNavigationResult
import com.citymapper.sdk.navigation.StartNavigationResult.FailureReason.RouteNotSupported
import com.citymapper.sdk.navigation.ui.getPathSegments
import com.example.sdk.sample.ui.common.SampleLoading
import com.example.sdk.sample.ui.common.demoColors
import com.example.sdk.sample.ui.map.MapView
import com.example.sdk.sample.ui.map.renderMarker
import com.example.sdk.sample.ui.map.renderRoute
import com.example.sdk.sample.utils.asCoords
import com.example.sdk.sample.utils.asLatLng
import com.example.sdk.sample.utils.checkLocationPermission
import com.example.sdk.sample.utils.getLastLocation
import com.example.sdk.sample.utils.toPx
import com.google.android.gms.maps.model.BitmapDescriptorFactory

@Composable
fun HomeScreen() {
  val viewModel = viewModel<HomeViewModel>()

  val state = viewModel.viewState

  val context = LocalContext.current
  val scope = rememberCoroutineScope()

  viewModel.setLocationPermission(checkLocationPermission(context))

  MapView(
    position = state.getCameraPosition(),
    mapContent = state,
    onMapClick = { endLocation ->
      if (!state.isNavigationActive) {
        getLastLocation(scope, context) { userLocation ->
          if (userLocation != null) {
            viewModel.setStart(userLocation.asCoords())
            viewModel.setEnd(endLocation.asCoords())
          }
        }
      }
    },
    setupMap = {
      isMyLocationEnabled = state.hasLocationPermission == true
      uiSettings.isMyLocationButtonEnabled = true
      uiSettings.isMapToolbarEnabled = false
    },
    renderContent = { context, viewState ->
      val bottomPadding = when {
        viewState.isNavigationActive -> 234.toPx(context)
        viewState.directions is ApiResult.Success -> 112.toPx(context)
        else -> 0
      }
      setPadding(0, 0, 0, bottomPadding)
      renderRoute(context, viewState.route?.getPathSegments(), demoColors)
      renderMarker(viewState.end?.asLatLng(), BitmapDescriptorFactory.HUE_BLUE)
    }
  )

  TopBar(
    isNavigationActive = state.isNavigationActive,
    currentProfile = state.profile,
    currentApi = state.availableApi,
    profileCallback = { viewModel.setProfile(it) },
    apiCallCallback = { viewModel.setAvailableApi(it) }
  )

  if (state.hasLocationPermission != null && !state.hasLocationPermission) {
    EnableLocationSnackBar { hasPermission ->
      viewModel.setLocationPermission(hasPermission)
    }
  }

  when {
    state.isLoading -> SampleLoading()
    state.isNavigationActive -> GuidanceContainer(state.legProgress) {
      viewModel.endGo()
    }
    state.directions is ApiResult.Failure -> ErrorDialog(state.directions.exception?.message) {
      viewModel.consumeApiError()
    }
    state.directions is ApiResult.Success && state.route != null -> PreviewContainer(state.route) {
      viewModel.startGo()
    }
  }

  if (state.startNavigationFailure != null) {
    StartNavigationFailureDialog(
      startNavigationFailure = state.startNavigationFailure,
      onDismiss = viewModel::dismissStartNavigationFailure
    )
  }
}

@Composable
private fun StartNavigationFailureDialog(
  startNavigationFailure: StartNavigationResult.Failure,
  onDismiss: () -> Unit
) {
  AlertDialog(
    onDismissRequest = onDismiss,
    buttons = {
      Column(
        modifier = Modifier
          .fillMaxWidth()
          .padding(4.dp)
      ) {
        TextButton(
          onClick = onDismiss,
          modifier = Modifier.align(Alignment.End)
        ) {
          Text(text = "Dismiss")
        }
      }
    },
    text = {
      val message = when (startNavigationFailure.reason) {
        RouteNotSupported -> "Route not supported"
      }

      Text(text = message)
    }
  )
}
