package com.example.sdk.sample.utils

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleObserver
import androidx.lifecycle.OnLifecycleEvent

private const val PERMISSIONS_REQUEST_CODE = 100

fun checkLocationPermission(context: Context): Boolean {
  return ContextCompat.checkSelfPermission(
    context,
    Manifest.permission.ACCESS_FINE_LOCATION
  ) == PackageManager.PERMISSION_GRANTED
}

fun requestLocationPermission(lifecycle: Lifecycle, context: Context, result: (Boolean) -> Unit) {
  if (checkLocationPermission(context)) {
    result(true)
    return
  }
  val activity = context as? Activity ?: return

  lifecycle.addObserver(PermissionLifecycleObserver)
  PermissionLifecycleObserver.onResume = {
    lifecycle.removeObserver(PermissionLifecycleObserver)
    result(checkLocationPermission(context))
  }

  ActivityCompat.requestPermissions(
    activity,
    arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
    PERMISSIONS_REQUEST_CODE
  )
}

private object PermissionLifecycleObserver : LifecycleObserver {

  var onResume: () -> Unit = {}

  @OnLifecycleEvent(Lifecycle.Event.ON_RESUME)
  fun resume() {
    onResume()
  }
}
