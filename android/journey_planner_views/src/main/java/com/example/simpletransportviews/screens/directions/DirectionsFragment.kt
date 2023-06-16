package com.example.simpletransportviews.screens.directions

import android.os.Bundle
import android.view.View
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import androidx.navigation.fragment.findNavController
import com.citymapper.sdk.cache.StoredRouteHandle
import com.citymapper.sdk.directions.CitymapperDirections
import com.citymapper.sdk.navigation.CitymapperNavigationTracking
import com.citymapper.sdk.navigation.TrackingConfiguration
import com.citymapper.sdk.ui.navigation.CitymapperDirectionsView
import com.example.simpletransportviews.R
import com.example.simpletransportviews.databinding.FragmentDirectionsBinding
import com.example.simpletransportviews.screens.NavArgs
import com.example.simpletransportviews.screens.NavRoutes
import kotlinx.coroutines.launch

class DirectionsFragment : Fragment(R.layout.fragment_directions) {

  override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
    super.onViewCreated(view, savedInstanceState)

    val binding = FragmentDirectionsBinding.bind(view)

    val routeHandle = checkNotNull(requireArguments().getString(NavArgs.DirectionsRouteHandle))

    val directions = CitymapperDirections.getInstance(requireContext())
    val navigation = CitymapperNavigationTracking.getInstance(requireContext())

    viewLifecycleOwner.lifecycleScope.launch {
      val route = directions.loadRoute(StoredRouteHandle.fromString(routeHandle))
      if (route == null) {
        findNavController().popBackStack()
        return@launch
      }

      var popToHome = false
      binding.directions.configure(
        uiControls = CitymapperDirectionsView.UiControls.Default,
        onStopNavigationTracking = { state ->
          if (state.isCloseToArrival) {
            popToHome = true
            CitymapperDirectionsView.StopNavigationTrackingBehavior.CloseNavigation
          } else {
            CitymapperDirectionsView.StopNavigationTrackingBehavior.DisplayOverview
          }
        },
        onClose = {
          if (popToHome) {
            findNavController().popBackStack(NavRoutes.Home, inclusive = false)
          } else {
            findNavController().popBackStack()
          }
        })

      val navigableRoute =
        navigation.createNavigableRoute(route, trackingConfiguration = TrackingConfiguration())
      binding.directions.setNavigableRoute(navigableRoute)
    }
  }

}