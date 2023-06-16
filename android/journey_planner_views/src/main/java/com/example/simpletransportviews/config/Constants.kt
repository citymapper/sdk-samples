package com.example.simpletransportviews.config

import com.citymapper.sdk.core.geo.Coords
import com.citymapper.sdk.core.geo.CoordsBounds

object Constants {

  val DefaultMapCenter = Coords(latitude = 51.500757, longitude = -0.124589)
  val DefaultSearchRegion = CoordsBounds(
    latNorth = 52.49,
    lonEast = 1.58,
    latSouth = 50.7,
    lonWest = -1.51
  )

}
