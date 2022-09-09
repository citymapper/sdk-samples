package com.example.sdk.sample.ui.common

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.Button
import androidx.compose.material.Card
import androidx.compose.material.CircularProgressIndicator
import androidx.compose.material.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog

@Composable
fun SampleButton(
  modifier: Modifier = Modifier,
  text: String,
  action: () -> Unit
) {
  Button(
    modifier = modifier,
    onClick = action
  ) {
    Text(text = text)
  }
}

@Composable
fun SampleCard(height: Dp, content: @Composable () -> Unit) {
  Card(
    modifier = Modifier
      .fillMaxWidth()
      .height(height)
      .padding(16.dp),
    shape = RoundedCornerShape(8.dp),
    elevation = 4.dp,
    content = content
  )
}

@Composable
fun SampleLoading() {
  Dialog(onDismissRequest = { }) {
    Card(
      modifier = Modifier
        .height(128.dp)
        .width(128.dp),
      shape = RoundedCornerShape(8.dp),
      elevation = 4.dp
    ) {
      Box(modifier = Modifier.fillMaxSize()) {
        CircularProgressIndicator(
          modifier = Modifier.align(Alignment.Center)
        )
      }
    }
  }
}
