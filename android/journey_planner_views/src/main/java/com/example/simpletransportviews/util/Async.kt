package com.example.simpletransportviews.util

sealed class Async<out T, out E> {
  open operator fun invoke(): T? = null
}

data class Success<T>(val data: T) : Async<T, Nothing>() {
  override fun invoke(): T = data
}

object Loading : Async<Nothing, Nothing>()

data class Failure<E>(val error: E? = null) : Async<Nothing, E>()