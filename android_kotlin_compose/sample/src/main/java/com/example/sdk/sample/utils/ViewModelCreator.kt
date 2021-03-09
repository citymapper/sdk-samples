package com.example.sdk.sample.utils

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider

fun interface ViewModelCreator<T> : ViewModelProvider.Factory {

  fun create(): T

  @Suppress("UNCHECKED_CAST")
  override fun <T : ViewModel?> create(modelClass: Class<T>): T {
    return create() as T
  }
}
