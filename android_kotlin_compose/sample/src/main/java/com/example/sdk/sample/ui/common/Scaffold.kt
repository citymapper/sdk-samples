package com.example.sdk.sample.ui.common

import androidx.compose.runtime.Composable

@Composable
fun DemoScaffold(children: @Composable () -> Unit) {
  DemoTheme {
    children()
  }
}
