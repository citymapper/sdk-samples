package com.example.simpletransportviews.screens.getmesomewhere

import android.os.Bundle
import android.util.Log
import android.view.View
import androidx.core.view.isVisible
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.lifecycle.lifecycleScope
import androidx.navigation.fragment.findNavController
import com.citymapper.sdk.cache.StoredRouteHandle
import com.citymapper.sdk.core.transit.Route
import com.citymapper.sdk.directions.CitymapperDirections
import com.citymapper.sdk.ui.navigation.CitymapperDirectionsView
import com.citymapper.sdk.ui.routedetail.RouteDetail
import com.citymapper.sdk.ui.search.ExperimentalSearchUi
import com.example.simpletransportviews.R
import com.example.simpletransportviews.databinding.FragmentRouteResultsBinding
import com.example.simpletransportviews.screens.NavRoutes
import com.example.simpletransportviews.util.Failure
import com.example.simpletransportviews.util.Loading
import com.example.simpletransportviews.util.Success
import kotlinx.coroutines.launch

@OptIn(ExperimentalSearchUi::class)
class RouteResultsFragment : Fragment(R.layout.fragment_route_results) {

  private val searchViewModel by viewModels<GetMeSomewhereViewModel>(ownerProducer = { requireParentFragment() })
  private val resultsViewModel by viewModels<RouteResultsViewModel>()

  override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
    super.onViewCreated(view, savedInstanceState)
    val binding = FragmentRouteResultsBinding.bind(view)

    resultsViewModel.setSearchState(searchViewModel.searchState)
    binding.searchHeader.setSearchState(searchViewModel.searchState)

    viewLifecycleOwner.lifecycleScope.launch {
      resultsViewModel.results.collect { async ->
        Log.d("TAAAG", "async: $async")
        when (async) {
          Loading -> {
            renderLoading(binding)
          }
          is Failure -> {
            renderFailure(binding)
          }
          is Success -> {
            renderRoutes(binding, async)
          }
        }
      }
    }
  }

  private fun renderRoutes(
    binding: FragmentRouteResultsBinding,
    async: Success<List<Route>>
  ) {
    binding.routeList.isVisible = true
    binding.progressErrorContainer.isVisible = false
    binding.routeList.setRoutes(async.data, ::openRouteDetail)
  }

  private fun renderFailure(binding: FragmentRouteResultsBinding) {
    binding.routeList.isVisible = false
    binding.progressErrorContainer.isVisible = true
    binding.progress.isVisible = false
    binding.error.isVisible = true

    binding.error.setOnClickListener {
      resultsViewModel.refresh()
    }
  }

  private fun renderLoading(binding: FragmentRouteResultsBinding) {
    binding.routeList.isVisible = false
    binding.progressErrorContainer.isVisible = true
    binding.progress.isVisible = true
    binding.error.isVisible = false
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