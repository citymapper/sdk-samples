package com.example.simpletransportviews.screens.getmesomewhere

import android.os.Bundle
import android.view.View
import androidx.activity.addCallback
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.findNavController
import com.citymapper.sdk.ui.search.ExperimentalSearchUi
import com.example.simpletransportviews.R
import com.example.simpletransportviews.databinding.FragmentSearchBinding

@OptIn(ExperimentalSearchUi::class)
class SearchFragment : Fragment(R.layout.fragment_search) {

  private val viewModel by viewModels<GetMeSomewhereViewModel>(ownerProducer = { requireParentFragment() })

  override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
    super.onViewCreated(view, savedInstanceState)

    val searchState = viewModel.searchState

    FragmentSearchBinding.bind(view)
      .searchView
      .configure(searchState)

    if (searchState.canRestoreLastResolvedState()) {
      requireActivity().onBackPressedDispatcher.addCallback(viewLifecycleOwner) {
        viewModel.searchState.restoreLastResolvedState()
      }
    }
  }
}