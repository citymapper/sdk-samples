package com.example.simpletransportviews.screens.getmesomewhere

import android.os.Bundle
import android.view.LayoutInflater
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
import com.citymapper.sdk.ui.search.ExperimentalSearchUi
import com.example.simpletransportviews.R
import com.example.simpletransportviews.databinding.FragmentGmsBinding
import kotlinx.coroutines.launch

@OptIn(ExperimentalSearchUi::class)
class GetMeSomewhereFragment : Fragment(R.layout.fragment_gms) {

  private val viewModel by viewModels<GetMeSomewhereViewModel>()

  override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
    super.onViewCreated(view, savedInstanceState)

    val binding = FragmentGmsBinding.bind(view)
    val toolbar = binding.toolbar
    ViewCompat.setOnApplyWindowInsetsListener(toolbar) { _, insets ->
      toolbar.updateLayoutParams<MarginLayoutParams> {
        topMargin = insets.getInsets(WindowInsetsCompat.Type.statusBars()).top
      }
      insets
    }
    toolbar.setNavigationIcon(R.drawable.ic_navigation_up)
    toolbar.setNavigationOnClickListener {
      findNavController().navigateUp()
    }

    viewLifecycleOwner.lifecycleScope.launch {
      viewModel.searchState.resolvedState.collect {
        if (it != null) {
          showResults()
        } else {
          showSearch()
        }
      }
    }
  }

  private fun showSearch() {
    if (childFragmentManager.findFragmentById(R.id.fragment_container) is SearchFragment) {
      return
    }
    childFragmentManager.commitNow {
      replace(R.id.fragment_container, SearchFragment())
    }
  }

  private fun showResults() {
    if (childFragmentManager.findFragmentById(R.id.fragment_container) is RouteResultsFragment) {
      return
    }
    childFragmentManager.commitNow {
      replace(R.id.fragment_container, RouteResultsFragment())
    }
  }
}