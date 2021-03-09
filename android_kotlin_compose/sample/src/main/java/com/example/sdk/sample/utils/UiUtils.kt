package com.example.sdk.sample.utils

import android.content.Context
import android.util.TypedValue
import kotlin.math.roundToInt

fun Number.toPx(context: Context): Int {
  return TypedValue.applyDimension(
    TypedValue.COMPLEX_UNIT_DIP, this.toFloat(), context.resources.displayMetrics
  ).roundToInt()
}
