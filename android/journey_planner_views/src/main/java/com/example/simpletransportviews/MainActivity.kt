package com.example.simpletransportviews

import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import androidx.core.view.WindowCompat
import androidx.navigation.fragment.NavHostFragment
import com.example.simpletransportviews.screens.createNavGraph

class MainActivity : AppCompatActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    WindowCompat.setDecorFitsSystemWindows(window, false)

    setContentView(R.layout.activity_main)

    val navHost = supportFragmentManager.findFragmentById(R.id.nav_host) as NavHostFragment
    val navController = navHost.navController
    navController.graph = navController.createNavGraph()
  }
}