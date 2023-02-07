package com.example.simpletransportviews.screens.home

import android.Manifest
import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.annotation.SuppressLint
import android.content.pm.PackageManager
import android.os.Bundle
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup.LayoutParams
import android.view.ViewGroup.MarginLayoutParams
import androidx.activity.OnBackPressedCallback
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.updateLayoutParams
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import androidx.navigation.fragment.findNavController
import com.citymapper.sdk.ui.map.MapFocus
import com.citymapper.sdk.ui.nearby.CitymapperNearbyState
import com.citymapper.sdk.ui.nearby.view.NearbyFiltersAndDetailView
import com.example.simpletransportviews.R
import com.example.simpletransportviews.config.Constants
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

  @SuppressLint("ClickableViewAccessibility")
  override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
    super.onViewCreated(view, savedInstanceState)

    val nearbyState =
      CitymapperNearbyState.create(requireContext(), viewLifecycleOwner.lifecycleScope)

    val binding = FragmentHomeBinding.bind(view)
    binding.getMeSomewhere.setOnClickListener {
      checkPermissionAndOpenGms()
    }

    ViewCompat.setOnApplyWindowInsetsListener(binding.gmsContainer) { v, insets ->
      v.updateLayoutParams<MarginLayoutParams> {
        bottomMargin = insets.getInsets(WindowInsetsCompat.Type.navigationBars()).bottom
      }
      insets
    }

    val onBackPressedCallback = object : OnBackPressedCallback(false) {
      override fun handleOnBackPressed() {
        if (isShowingNearby(binding)) {
          animateToHome(binding, nearbyState, this)
        }
      }
    }
    requireActivity().onBackPressedDispatcher.addCallback(
      viewLifecycleOwner,
      onBackPressedCallback
    )

    binding.map.configure(
      nearbyState,
      fallbackMapFocus = MapFocus.Center(Constants.DefaultMapCenter),
      onMapClickListener = {
        if (!isShowingNearby(binding)) {
          animateToNearby(binding, nearbyState, onBackPressedCallback)
        }
      })
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

  private fun isShowingNearby(binding: FragmentHomeBinding) =
    binding.nearbyCardsContainer.childCount > 0

  private fun animateToNearby(
    binding: FragmentHomeBinding,
    nearbyState: CitymapperNearbyState,
    onBackPressedCallback: OnBackPressedCallback
  ) {
    binding.gmsContainer.animate()
      .y(binding.root.height.toFloat())
      .setListener(object : AnimatorListenerAdapter() {
        override fun onAnimationEnd(animation: Animator) {
          val detailView = NearbyFiltersAndDetailView(requireContext())
          binding.nearbyCardsContainer.addView(
            detailView,
            LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
          )

          detailView.configure(nearbyState) {
            animateToHome(binding, nearbyState, onBackPressedCallback)
          }
          onBackPressedCallback.isEnabled = true
        }
      })
  }

  private fun animateToHome(
    binding: FragmentHomeBinding,
    nearbyState: CitymapperNearbyState,
    onBackPressedCallback: OnBackPressedCallback
  ) {
    binding.nearbyCardsContainer.removeAllViews()
    binding.gmsContainer.animate().translationY(0f).setListener(null)
    onBackPressedCallback.isEnabled = false
    nearbyState.clearSelectedFeature()
  }

  private fun openGms() {
    findNavController().navigate(NavRoutes.GetMeSomewhere)
  }
}
