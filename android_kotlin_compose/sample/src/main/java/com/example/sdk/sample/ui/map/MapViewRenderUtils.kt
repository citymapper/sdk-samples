package com.example.sdk.sample.ui.map

import android.content.Context
import androidx.compose.material.Colors
import androidx.compose.ui.graphics.toArgb
import androidx.core.graphics.ColorUtils
import com.citymapper.sdk.navigation.ui.PathGeometrySegment
import com.example.sdk.sample.utils.asLatLng
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.model.BitmapDescriptorFactory
import com.google.android.gms.maps.model.Dot
import com.google.android.gms.maps.model.Gap
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.MarkerOptions
import com.google.android.gms.maps.model.PolylineOptions

fun GoogleMap.renderMarker(
  latLng: LatLng?,
  color: Float
) {
  if (latLng != null) {
    addMarker(
      MarkerOptions()
        .position(latLng)
        .icon(BitmapDescriptorFactory.defaultMarker(color))
    )
  }
}

fun GoogleMap.renderRoute(
  context: Context,
  pathSegments: List<PathGeometrySegment>?,
  colors: Colors
) {
  if (pathSegments == null) {
    return
  }

  for (segment in pathSegments) {
    val baseColor = colors.primary.toArgb()
    val color = if (segment.pastOrFuture == PathGeometrySegment.PastOrFuture.Past) {
      ColorUtils.setAlphaComponent(baseColor, 0x7f)
    } else {
      baseColor
    }

    val pattern = if (segment.travelMode == PathGeometrySegment.TravelMode.Walk) {
      listOf(Dot(), Gap(4 * context.resources.displayMetrics.density))
    } else {
      null
    }

    addPolyline(
      PolylineOptions().apply {
        addAll(segment.geometry.map { it.asLatLng() })
        color(color)
        width(4 * context.resources.displayMetrics.density)
        if (pattern != null) {
          pattern(pattern)
        }
      }
    )
  }
}
