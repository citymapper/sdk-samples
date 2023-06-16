package com.example.simpletransportviews.screens.getmesomewhere

import android.os.Bundle
import android.text.TextUtils.replace
import android.view.LayoutInflater
import android.view.SearchEvent
import android.view.View
import android.view.ViewGroup
import android.view.ViewGroup.MarginLayoutParams
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.marginTop
import androidx.core.view.updateLayoutParams
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentContainerView
import androidx.fragment.app.commitNow
import androidx.fragment.app.viewModels
import androidx.lifecycle.SAVED_STATE_REGISTRY_OWNER_KEY
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import androidx.navigation.fragment.findNavController
import com.citymapper.sdk.core.transit.DepartApproximateNow
import com.citymapper.sdk.core.transit.DepartOrArriveConstraint
import com.citymapper.sdk.core.transit.Route
import com.citymapper.sdk.directions.CitymapperDirections
import com.citymapper.sdk.ui.map.MapFocus
import com.citymapper.sdk.ui.navigation.CitymapperDirectionsView
import com.citymapper.sdk.ui.routedetail.RouteDetail
import com.citymapper.sdk.ui.search.ExpandedSheetBehaviour
import com.citymapper.sdk.ui.search.ExperimentalSearchUi
import com.citymapper.sdk.ui.search.SearchEndpoint
import com.citymapper.sdk.ui.search.google.googleSearchProviderFactory
import com.example.simpletransportviews.BuildConfig
import com.example.simpletransportviews.R
import com.example.simpletransportviews.config.Constants
import com.example.simpletransportviews.databinding.FragmentGmsBinding
import com.example.simpletransportviews.screens.NavRoutes
import kotlinx.coroutines.launch

class GetMeSomewhereFragment : Fragment(R.layout.fragment_gms) {

  override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
    super.onViewCreated(view, savedInstanceState)

    val binding = FragmentGmsBinding.bind(view)
    val searchView = binding.searchView
    searchView.configure(
      defaultMapFocus = MapFocus.onPoint(Constants.DefaultMapCenter),
      searchProviderFactory = googleSearchProviderFactory(
        googlePlacesApiKey = BuildConfig.PLACES_API_KEY,
        region = Constants.DefaultSearchRegion
      ),
      topAppBarContent = {
        DefaultTopAppBar {
          findNavController().navigateUp()
        }
      },
      searchCompleteContent = {
        RouteResults(
          planBuilder = {
            walkRoute()
            bikeRoute()
            transitRoutes()
          },
          onRouteClick = ::openRouteDetail
        )
      }
    )
  }

  private fun openRouteDetail(route: Route) {
    if (CitymapperDirectionsView.supportsRoute(route)) {
      val handle = CitymapperDirections.getInstance(requireContext()).storeRoute(route)
      findNavController().navigate(NavRoutes.Directions(handle.toString()))
    } else {
      RouteDetail.showStandaloneRouteDetailScreen(requireContext(), route)
    }
  }
}
