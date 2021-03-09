package com.example.sdk.sample.utils

import android.location.Location
import com.citymapper.sdk.core.geo.Coords
import com.google.android.gms.maps.model.LatLng

fun LatLng.asCoords() = Coords(latitude = latitude, longitude = longitude)

fun Location.asCoords() = Coords(latitude = latitude, longitude = longitude)

fun String.asCoords() = this.split(",").let {
  Coords(latitude = it[0].toDouble(), longitude = it[1].toDouble())
}

fun Coords.asLatLng() = LatLng(latitude, longitude)
