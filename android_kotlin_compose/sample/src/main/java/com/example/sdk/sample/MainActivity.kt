package com.example.sdk.sample

import android.os.Bundle
import androidx.activity.compose.setContent
import androidx.appcompat.app.AppCompatActivity
import com.example.sdk.sample.ui.common.DemoScaffold
import com.example.sdk.sample.ui.home.HomeScreen

class MainActivity : AppCompatActivity() {

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    setContent {
      DemoScaffold {
        HomeScreen()
      }
    }
  }
}
