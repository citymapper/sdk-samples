//
//  RouteListViewModel.swift
//  CitymapperUISample
//
//  Created by Iuliia Ponomareva on 09/09/2022.
//

import CitymapperNavigation
import CitymapperUI
import Foundation

class RouteListViewModel: ObservableObject {
    let routesLoader: RoutesLoader
    let routePlanningSpec: RoutePlanningSpec
    
    @Published var routes: [Route] = []
    
    init(routesLoader: RoutesLoader, routePlanningSpec: RoutePlanningSpec) {
        self.routesLoader = routesLoader
        self.routePlanningSpec = routePlanningSpec
        
        Task { @MainActor in
            routes = await routesLoader.loadRoutes(startCoordinate: routePlanningSpec.start.coords.asCLLocationCoordinate2D(),
                                                   endCoordinate: routePlanningSpec.end.coords.asCLLocationCoordinate2D(),
                                                   departOrArriveConstraint: routePlanningSpec.timeConstraint)
        }
    }
}
