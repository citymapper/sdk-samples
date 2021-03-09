package com.example.sdk.sample.ui.home

import android.net.Uri
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.AlertDialog
import androidx.compose.material.Button
import androidx.compose.material.DropdownMenu
import androidx.compose.material.DropdownMenuItem
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Snackbar
import androidx.compose.material.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.app.ShareCompat
import androidx.core.content.FileProvider
import com.citymapper.sdk.core.geo.Distance
import com.citymapper.sdk.core.geo.totalDistance
import com.citymapper.sdk.core.transit.Instruction
import com.citymapper.sdk.core.transit.Profile
import com.citymapper.sdk.core.transit.Route
import com.citymapper.sdk.navigation.CitymapperNavigationTracking
import com.citymapper.sdk.navigation.progress.LegProgress
import com.example.sdk.sample.ui.common.SampleButton
import com.example.sdk.sample.ui.common.SampleCard
import com.example.sdk.sample.utils.requestLocationPermission
import kotlin.math.ceil
import kotlin.math.roundToInt
import kotlin.time.Duration
import kotlin.time.DurationUnit
import kotlin.time.minutes

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
            val minutes = leg.travelDuration?.toString(DurationUnit.MINUTES, 1)
            Text(
              text = "${leg.type} $minutes ($meters meters)",
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
fun GuidanceContainer(legProgress: LegProgress?, endGo: () -> Unit) {
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
fun ErrorDialog(error: String?, onDismiss: () -> Unit) {
  AlertDialog(
    onDismissRequest = { onDismiss() },
    title = { Text(text = "Error") },
    text = { Text(text = error ?: "Oops, Something Went Wrong") },
    confirmButton = {
      Button(
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
    Button(
      onClick = { showMenu.value = true }
    ) {
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
    Button(
      onClick = { showMenu.value = true }
    ) {
      Text(text = currentApi.route)
    }
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

@Composable
fun TopBar(
  isNavigationActive: Boolean,
  currentProfile: Profile,
  currentApi: AvailableApi,
  profileCallback: (Profile) -> Unit,
  apiCallCallback: (AvailableApi) -> Unit
) {
  Column(
    modifier = Modifier
      .fillMaxWidth()
      .padding(16.dp)
  ) {
    Row {
      if (!isNavigationActive) {
        ApiChooser(currentApi, apiCallCallback)
        Spacer(modifier = Modifier.width(8.dp))
      }
      ShareLogButton()
    }
    if (!isNavigationActive && currentApi == AvailableApi.Bikeride) {
      Spacer(modifier = Modifier.height(8.dp))
      ProfileChooser(currentProfile, profileCallback)
    }
  }
}

@Composable
fun ShareLogButton() {
  val context = LocalContext.current
  SampleButton(text = "Share Log") {
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
