package com.example.sdk.sample.ui.home

import android.net.Uri
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.AlertDialog
import androidx.compose.material.Button
import androidx.compose.material.DrawerValue
import androidx.compose.material.DropdownMenu
import androidx.compose.material.DropdownMenuItem
import androidx.compose.material.MaterialTheme
import androidx.compose.material.ModalDrawer
import androidx.compose.material.Snackbar
import androidx.compose.material.Text
import androidx.compose.material.TextButton
import androidx.compose.material.TextField
import androidx.compose.material.rememberDrawerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.app.ShareCompat
import androidx.core.content.FileProvider
import com.citymapper.sdk.core.geo.Distance
import com.citymapper.sdk.core.geo.totalDistance
import com.citymapper.sdk.core.transit.HiredVehicleLeg
import com.citymapper.sdk.core.transit.Instruction
import com.citymapper.sdk.core.transit.Leg
import com.citymapper.sdk.core.transit.OwnVehicleLeg
import com.citymapper.sdk.core.transit.Profile
import com.citymapper.sdk.core.transit.Route
import com.citymapper.sdk.core.transit.VehicleType
import com.citymapper.sdk.core.transit.WalkLeg
import com.citymapper.sdk.navigation.CitymapperNavigationTracking
import com.citymapper.sdk.navigation.VehicleLockState
import com.example.sdk.sample.ui.common.SampleButton
import com.example.sdk.sample.ui.common.SampleCard
import com.example.sdk.sample.utils.requestLocationPermission
import java.util.Locale
import java.util.concurrent.TimeUnit
import kotlin.math.ceil
import kotlin.math.roundToInt
import kotlin.time.Duration
import kotlin.time.minutes
import kotlinx.coroutines.launch

@Composable
fun PreviewContainer(route: Route, startGo: () -> Unit) {
  Column(
    modifier = Modifier.fillMaxSize(),
    verticalArrangement = Arrangement.Bottom,
    horizontalAlignment = Alignment.End
  ) {
    SampleButton(
      modifier = Modifier.padding(end = 16.dp),
      text = "Start GO",
      action = startGo
    )
    SampleCard(height = 128.dp) {
      Row(
        modifier = Modifier
          .fillMaxWidth()
          .padding(8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
      ) {
        Column(
          modifier = Modifier
            .fillMaxWidth()
            .weight(1f)
        ) {
          route.legs.forEach { leg ->
            val path = leg.path
            val distance = path.totalDistance

            val meters = distance.inMeters.roundToInt()
            val minutes = "${leg.travelDuration?.toInt(TimeUnit.MINUTES) ?: 0} min"
            Text(
              text = "${leg.description()} for $minutes ($meters meters)",
              style = MaterialTheme.typography.caption
            )
          }
        }
        Column(
          modifier = Modifier.wrapContentHeight(),
          horizontalAlignment = Alignment.CenterHorizontally
        ) {
          val minutes = route.legs
            .fold(Duration.ZERO) { acc, leg -> acc + (leg.travelDuration ?: Duration.ZERO) }
            .let { ceil(it.inMinutes).roundToInt() }

          Text(
            modifier = Modifier.width(56.dp),
            text = minutes.toString(),
            style = MaterialTheme.typography.h4 + TextStyle(textAlign = TextAlign.Center)
          )
          Text(
            text = "min",
            style = MaterialTheme.typography.body2
          )
        }
      }
    }
  }
}

@Composable
fun GuidanceContainer(
  viewState: HomeViewState,
  endGo: () -> Unit,
  vehicleLockState: (VehicleLockState) -> Unit
) {
  Column(
    modifier = Modifier.fillMaxSize(),
    verticalArrangement = Arrangement.Bottom,
    horizontalAlignment = Alignment.End
  ) {
    SampleButton(
      modifier = Modifier.padding(end = 16.dp),
      text = "End GO",
      action = endGo
    )
    SampleCard(height = 250.dp) {
      val legProgress = viewState.routeProgress?.legProgress
      val upcoming = legProgress?.nextInstructionProgress
        ?: return@SampleCard

      LazyColumn(
        contentPadding = PaddingValues(16.dp),
        content = {
          item {
            InstructionRow(
              instruction = upcoming.instruction,
              distance = upcoming.distanceUntilInstruction,
              duration = upcoming.durationUntilInstruction
            )
          }
          items(legProgress.remainingInstructionSegmentsAfterNext.orEmpty()) {
            InstructionRow(
              instruction = it.endInstruction,
              distance = it.distance,
              duration = it.duration
            )
          }

          val actionableVehicleLockState = viewState.actionableVehicleLockState
          if (actionableVehicleLockState != null) {
            item {
              when (actionableVehicleLockState) {
                VehicleLockState.Locked, null -> {
                  SampleButton(text = "Unlock") {
                    vehicleLockState(VehicleLockState.Unlocked())
                  }
                }
                is VehicleLockState.Unlocked -> {
                  SampleButton(text = "Lock") {
                    vehicleLockState(VehicleLockState.Locked)
                  }
                }
              }
            }
          }
        }
      )
    }
  }
}

@Composable
fun InstructionRow(instruction: Instruction, distance: Distance?, duration: Duration?) {
  Box(
    modifier = Modifier
      .fillMaxWidth()
      .padding(vertical = 4.dp)
  ) {
    Row(
      modifier = Modifier.fillMaxWidth()
    ) {
      Column(
        modifier = Modifier
          .fillMaxWidth()
          .weight(1f)
      ) {
        if (distance != null) {
          val intMeters = distance.inMeters.roundToInt()
          Text(
            text = "In $intMeters meters",
            style = MaterialTheme.typography.overline.copy(
              fontSize = 16.sp
            )
          )
        }
        Text(
          text = instruction.descriptionText,
          style = MaterialTheme.typography.h6
        )
      }

      val durationText = when {
        duration == null -> ""
        duration < 1.minutes -> "< 1 min"
        else -> "${ceil(duration.inMinutes).toInt()} min"
      }

      Text(
        modifier = Modifier
          .width(56.dp)
          .align(Alignment.CenterVertically),
        text = durationText,
        style = MaterialTheme.typography.body2 + TextStyle(textAlign = TextAlign.Center)
      )
    }
  }
}

@Composable
fun SettingsDrawer(
  state: HomeViewState,
  profileCallback: (Profile) -> Unit,
  apiCallCallback: (AvailableApi) -> Unit,
  brandIdCallback: (String) -> Unit,
  removeCustomVehicleCallback: () -> Unit,
  content: @Composable () -> Unit
) {
  val drawerState = rememberDrawerState(DrawerValue.Closed)
  val scope = rememberCoroutineScope()
  ModalDrawer(
    drawerState = drawerState,
    gesturesEnabled = false,
    drawerContent = {
      Column(modifier = Modifier.padding(16.dp)) {
        Button(onClick = { scope.launch { drawerState.close() } }) {
          Text(text = "Close Settings")
        }
        ShareLogButton()
        if (!state.isNavigationActive) {
          ApiChooser(state.availableApi, apiCallCallback)
        }
        if (!state.isNavigationActive &&
          state.customVehicleLocation != null &&
          AvailableApi.useCustomVehicle.contains(state.availableApi)
        ) {
          TextButton(onClick = { removeCustomVehicleCallback() }) {
            Text(text = "Remove custom vehicle")
          }
        }
        if (!state.isNavigationActive &&
          AvailableApi.needProfile.contains(state.availableApi)
        ) {
          ProfileChooser(state.profile, profileCallback)
        }
        if (!state.isNavigationActive &&
          AvailableApi.needBrand.contains(state.availableApi)
        ) {
          BrandIdChooser(state.brandId, brandIdCallback)
        }
      }
    },
    content = {
      content()
      Button(
        modifier = Modifier.padding(16.dp),
        onClick = {
          scope.launch {
            drawerState.open()
          }
        }
      ) {
        Text(text = "Settings")
      }
    }
  )
}

@Composable
fun ErrorDialog(error: String?, onDismiss: () -> Unit) {
  AlertDialog(
    onDismissRequest = { onDismiss() },
    title = { Text(text = "Error") },
    text = { Text(text = error ?: "Oops, Something Went Wrong") },
    confirmButton = {
      TextButton(
        onClick = { onDismiss() }
      ) {
        Text(text = "Close")
      }
    }
  )
}

@Composable
fun ProfileChooser(currentProfile: Profile, profileCallback: (Profile) -> Unit) {
  val showMenu = remember { mutableStateOf(false) }
  Box {
    TextButton(onClick = { showMenu.value = true }) {
      Text(text = "Profile: ${currentProfile.string}")
    }

    DropdownMenu(
      expanded = showMenu.value,
      onDismissRequest = { showMenu.value = false }
    ) {
      DropdownMenuItem(
        onClick = {
          profileCallback(Profile.Quiet)
          showMenu.value = false
        }
      ) {
        Text(text = "Quiet")
      }
      DropdownMenuItem(
        onClick = {
          profileCallback(Profile.Regular)
          showMenu.value = false
        }
      ) {
        Text(text = "Regular")
      }
      DropdownMenuItem(
        onClick = {
          profileCallback(Profile.Fast)
          showMenu.value = false
        }
      ) {
        Text(text = "Fast")
      }
    }
  }
}

@Composable
fun ApiChooser(currentApi: AvailableApi, profileApi: (AvailableApi) -> Unit) {
  val showMenu = remember { mutableStateOf(false) }
  Box {
    TextButton(
      onClick = { showMenu.value = true }
    ) {
      Text(text = "Api: ${currentApi.route}")
    }
    DropdownMenu(
      expanded = showMenu.value,
      onDismissRequest = { showMenu.value = false }
    ) {
      AvailableApi.values().forEach {
        DropdownMenuItem(
          onClick = {
            profileApi(it)
            showMenu.value = false
          }
        ) {
          Text(text = it.route)
        }
      }
    }
  }
}

@Composable
fun ShareLogButton() {
  val context = LocalContext.current
  TextButton(
    onClick = {
      val file = CitymapperNavigationTracking.currentNavigationLogFile(context)
      if (file.exists()) {
        val uri: Uri = FileProvider.getUriForFile(
          context,
          "com.example.sdk.sample.fileprovider",
          file
        )
        ShareCompat.IntentBuilder(context)
          .setStream(uri)
          .setType("text/plain")
          .setStream(uri)
          .startChooser()
      }
    }
  ) {
    Text(text = "Share Log")
  }
}

@Composable
fun BrandIdChooser(brandId: String, brandIdCallback: (String) -> Unit) {
  val currentBrandId = remember { mutableStateOf(TextFieldValue(brandId)) }
  val showDialog = remember { mutableStateOf(false) }
  Box {
    TextButton(onClick = { showDialog.value = true }) {
      Text(text = "Set brandId")
    }
    if (showDialog.value) {
      AlertDialog(
        onDismissRequest = { showDialog.value = false },
        text = {
          TextField(
            value = currentBrandId.value,
            onValueChange = {
              currentBrandId.value = it
            },
            singleLine = true
          )
        },
        confirmButton = {
          TextButton(
            onClick = {
              showDialog.value = false
              brandIdCallback(currentBrandId.value.text)
            }
          ) {
            Text(text = "Save")
          }
        },
        dismissButton = {
          TextButton(
            onClick = { showDialog.value = false }
          ) {
            Text(text = "Close")
          }
        }
      )
    }
  }
}

@Composable
fun EnableLocationSnackBar(hasPermission: (Boolean) -> Unit) {
  val context = LocalContext.current
  val lifecycle = LocalLifecycleOwner.current.lifecycle
  Box(modifier = Modifier.fillMaxSize()) {
    Snackbar(
      modifier = Modifier
        .padding(16.dp)
        .align(Alignment.BottomStart),
      content = { Text(text = "You need to enable Location permission to use the sample") },
      action = {
        Button(
          onClick = {
            requestLocationPermission(lifecycle, context) { hasPermission ->
              hasPermission(hasPermission)
            }
          }
        ) {
          Text("Request")
        }
      }
    )
  }
}

private fun Leg.description(): String {
  return when (this) {
    is HiredVehicleLeg -> "Ride ${service.name} ${vehicleType.description()}"
    is OwnVehicleLeg -> "Ride ${vehicleType.description()}"
    is WalkLeg -> "Walk"
    else -> ""
  }
}

private fun VehicleType.description() = name.toLowerCase(Locale.getDefault())
