package com.example.simpletransportviews.screens

import androidx.navigation.NavController
import androidx.navigation.NavType
import androidx.navigation.createGraph
import androidx.navigation.fragment.fragment
import com.example.simpletransportviews.screens.directions.DirectionsFragment
import com.example.simpletransportviews.screens.getmesomewhere.GetMeSomewhereFragment
import com.example.simpletransportviews.screens.home.HomeFragment

@Suppress("FunctionName")
object NavRoutes {
  const val Home = "home"
  const val GetMeSomewhere = "gms"
  fun Directions(handle: String) = "directions/$handle"
}

object NavArgs {
  const val DirectionsRouteHandle = "route_handle"
}

fun NavController.createNavGraph() = createGraph(NavRoutes.Home) {
  fragment<HomeFragment>(NavRoutes.Home)
  fragment<GetMeSomewhereFragment>(NavRoutes.GetMeSomewhere)
  fragment<DirectionsFragment>(NavRoutes.Directions("{${NavArgs.DirectionsRouteHandle}}")) {
    argument(NavArgs.DirectionsRouteHandle) {
      nullable = false
      type = NavType.StringType
    }
  }
}