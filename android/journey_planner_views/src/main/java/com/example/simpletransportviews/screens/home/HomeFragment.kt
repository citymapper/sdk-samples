package com.example.simpletransportviews.screens.home

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.view.View
import androidx.activity.result.contract.ActivityResultContracts
import androidx.fragment.app.Fragment
import androidx.navigation.fragment.findNavController
import com.example.simpletransportviews.R
import com.example.simpletransportviews.databinding.FragmentHomeBinding
import com.example.simpletransportviews.screens.NavRoutes

class HomeFragment : Fragment(R.layout.fragment_home) {

  private val requestPermissionLauncher =
    registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { grantResults ->
      val allGranted = grantResults.values.all { it }
      if (allGranted) {
        openGms()
      }
    }

  override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
    super.onViewCreated(view, savedInstanceState)

    val binding = FragmentHomeBinding.bind(view)
    binding.getMeHome.setOnClickListener {
      checkPermissionAndOpenGms()
    }
  }

  private fun checkPermissionAndOpenGms() {
    if (requireContext().checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
      openGms()
    } else {
      requestPermissionLauncher.launch(
        arrayOf(
          Manifest.permission.ACCESS_FINE_LOCATION,
          Manifest.permission.ACCESS_COARSE_LOCATION
        )
      )
    }
  }

  private fun openGms() {
    findNavController().navigate(NavRoutes.GetMeSomewhere)
  }
}