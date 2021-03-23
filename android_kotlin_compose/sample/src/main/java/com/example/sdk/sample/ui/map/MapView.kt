package com.example.sdk.sample.ui.map

import android.annotation.SuppressLint
import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.ui.viewinterop.AndroidView
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.MapView
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.LatLngBounds

private const val InitialZoom = 5f

@Composable
fun <T> MapView(
  position: MapCameraPosition?,
  mapContent: T,
  onMapClick: (LatLng) -> Unit = {},
  onMapLongClick: (LatLng) -> Unit = {},
  setupMap: GoogleMap.() -> Unit = {},
  renderContent: GoogleMap.(Context, T) -> Unit
) {
  // The MapView lifecycle is handled by this composable. As the MapView also needs to be updated
  // with input from Compose UI, those updates are encapsulated into the MapViewContainer
  // composable. In this way, when an update to the MapView happens, this composable won't
  // recompose and the MapView won't need to be recreated.
  val mapView = rememberMapViewWithLifecycle()
  MapViewContainer(mapView, position, mapContent, onMapClick, onMapLongClick, setupMap, renderContent)
}

@SuppressLint("MissingPermission")
@Composable
private fun <T> MapViewContainer(
  map: MapView,
  position: MapCameraPosition?,
  mapContent: T,
  onMapClick: (LatLng) -> Unit,
  onMapLongClick: (LatLng) -> Unit,
  setupMap: GoogleMap.() -> Unit,
  renderContent: GoogleMap.(Context, T) -> Unit
) {
  AndroidView({ map }) { mapView ->
    mapView.getMapAsync { googleMap ->
      setupMap(googleMap)
      googleMap.setOnMapLongClickListener { onMapLongClick(it) }
      googleMap.setOnMapClickListener { onMapClick(it) }
    }
  }
  if (position != null) {
    MapPosition(mapView = map, pos = position)
  }
  MapContent(mapView = map, content = mapContent, renderContent = renderContent)
}

@Composable
private fun MapPosition(mapView: MapView, pos: MapCameraPosition) {
  DisposableEffect(mapView, pos) {
    mapView.getMapAsync {
      val cameraUpdate = when (pos) {
        is MapCameraPosition.LatLngZoom -> {
          CameraUpdateFactory.newLatLngZoom(LatLng(pos.latitude, pos.longitude), pos.zoom)
        }
        is MapCameraPosition.Bounds -> {
          CameraUpdateFactory.newLatLngBounds(pos.bounds, 16)
        }
      }

      it.moveCamera(cameraUpdate)
    }

    onDispose { }
  }
}

@Composable
private fun <T> MapContent(
  mapView: MapView,
  content: T,
  renderContent: GoogleMap.(Context, T) -> Unit
) {
  DisposableEffect(mapView, content) {
    mapView.getMapAsync {
      it.clear()
      it.renderContent(mapView.context, content)
    }

    onDispose { }
  }
}

sealed class MapCameraPosition {
  data class LatLngZoom(
    val latitude: Double,
    val longitude: Double,
    val zoom: Float = InitialZoom
  ) : MapCameraPosition()

  data class Bounds(val bounds: LatLngBounds) : MapCameraPosition()
}
