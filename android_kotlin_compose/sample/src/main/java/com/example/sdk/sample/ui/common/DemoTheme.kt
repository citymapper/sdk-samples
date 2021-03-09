package com.example.sdk.sample.ui.common

import androidx.compose.material.MaterialTheme
import androidx.compose.material.lightColors
import androidx.compose.runtime.Composable

val demoColors = lightColors()

@Composable
fun DemoTheme(children: @Composable () -> Unit) {
  MaterialTheme(colors = demoColors) {
    children()
  }
}
