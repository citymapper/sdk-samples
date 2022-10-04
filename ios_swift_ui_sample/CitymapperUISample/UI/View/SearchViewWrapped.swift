//
//  SearchViewWrapped.swift
//  CitymapperUISample
//
//  Created by Iuliia Ponomareva on 09/09/2022.
//

// uncomment this import to use Google search
import CitymapperGoogleSearchProvider
import CitymapperUI
import Foundation
import MapKit
import SwiftUI

struct SearchViewWrapped: View {
    
    let routesLoader: RoutesLoader
    
    /*
     for Google search you'll need to change `appleSearchProviderFactory` to:
     googleSearchProviderFactory(googlePlacesApiKey: ConfigurationConstants.googlePlacesApiKey,
                                             region: MKCoordinateRegion(center: LocationConstants.bigBenLocation,
                                                                          span: LocationConstants.defaultSpan)
     
     */
    
    
    private let searchState = CitymapperSearchViewStateFactory.create(
        start: .currentLocation,
        searchProviderFactory: appleSearchProviderFactory(region: MKCoordinateRegion(center: LocationConstants.bigBenLocation,
                                                                                     span: LocationConstants.defaultSpan))
    )
    
    @State private var resolvedState: RoutePlanningSpec?
    @State private var showTimePicker: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                if let state = resolvedState {
                    RouteListView(viewModel: RouteListViewModel(routesLoader: routesLoader, routePlanningSpec: state),
                                  didSwapStartAndEnd: { searchState.swapStartAndEnd() },
                                  startHasBeenFocused: { searchState.clearResolvedStateAndEditStart() },
                                  endHasBeenFocused:  { searchState.clearResolvedStateAndEditEnd() },
                                  timePickerButtonDidTap: {
                        showTimePicker.toggle()
                    }
                    ).navigationBarTitle("Routes List", displayMode: .inline)
                } else {
                    SearchView(searchState: searchState)
                        .navigationBarTitle("Search", displayMode: .inline)
                        .ignoresSafeArea(.all, edges: .bottom)
                }
            }.onReceive(searchState.resolvedStatePublisher) { state in
                resolvedState = state
            }
            
            CitymapperTimePickerView(isPresented: $showTimePicker) { timeConstraint in
                searchState.setTimeConstraint(timeConstraint: timeConstraint)
            }
        }
    }
}
