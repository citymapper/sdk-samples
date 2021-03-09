package com.example.sdk.sample.utils

import android.content.Context
import android.location.Location
import com.google.android.gms.location.LocationServices
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

internal fun getLastLocation(
  scope: CoroutineScope,
  context: Context,
  locationCallback: (Location?) -> Unit
) {
  if (checkLocationPermission(context)) {
    scope.launch {
      val lastLocation =
        LocationServices.getFusedLocationProviderClient(context).lastLocation?.await()
      locationCallback(lastLocation)
    }
  }
}
