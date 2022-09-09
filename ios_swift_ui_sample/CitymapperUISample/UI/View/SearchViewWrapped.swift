//
//  SearchViewWrapped.swift
//  CitymapperUISample
//
//  Created by Iuliia Ponomareva on 09/09/2022.
//

import CitymapperUI
import Foundation
import MapKit
import SwiftUI

struct SearchViewWrapped: View {
    
    let routesLoader: RoutesLoader
    
    private let searchState = CitymapperSearchViewStateFactory.create(
        start: .currentLocation,
        searchProviderFactory: appleSearchProviderFactory(region: MKCoordinateRegion(center: LocationConstants.bigBenLocation,
                                                                                     span: LocationConstants.defaultSpan))
    )
    
    @State private var resolvedState: RoutePlanningSpec?
    var body: some View {
        VStack {
            if let state = resolvedState {
                RouteListView(viewModel: RouteListViewModel(routesLoader: routesLoader, routePlanningSpec: state),
                              didSwapStartAndEnd: { searchState.swapStartAndEnd() },
                              startHasBeenFocused: { searchState.clearResolvedStateAndEditStart() },
                              endHasBeenFocused:  { searchState.clearResolvedStateAndEditEnd() }
                ).navigationBarTitle("Routes List", displayMode: .inline)
            } else {
                SearchView(searchState: searchState)
                    .navigationBarTitle("Search", displayMode: .inline)
                    .ignoresSafeArea(.all, edges: .bottom)
            }
        }.onReceive(searchState.resolvedStatePublisher) { state in
            resolvedState = state
        }
    }
}
