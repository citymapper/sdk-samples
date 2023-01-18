//
//  RouteListView.swift
//  CitymapperUISample
//
//  Created by Iuliia Ponomareva on 02/09/2022.
//

import CitymapperNavigation
import CitymapperUI
import SwiftUI
import MapKit

struct RouteListView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isShowingTransitRouteDetails = false
    @State private var isShowingRouteDetails = false
    @State private (set) var route: Route? = nil
    
    @ViewBuilder var routeDetailsView: some View {
        if let route = route {
            RouteDetailsView(route: route).ignoresSafeArea()
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder var directionsView: some View {
        if let route = route {
            DirectionsView(route: route).ignoresSafeArea()
        } else {
            EmptyView()
        }
    }
    
    var body: some View {
        /*
        let searchProviderFactory = googleSearchProviderFactory(
            googlePlacesApiKey: ConfigurationConstants.googlePlacesApiKey,
            region: MKCoordinateRegion(center: LocationConstants.bigBenLocation,
                                       span: LocationConstants.defaultSpan)
        */

        let bigBen = LocationConstants.bigBenLocation
        let searchProviderFactory = appleSearchProviderFactory(
            region: MKCoordinateRegion(center: bigBen,
                                       span: LocationConstants.defaultSpan))
        
        BottomSheetSearchWithMapView(
            // A fallback location for the map center e.g. if no location permission
            // is granted
            defaultMapCenter: Coords(latitude: bigBen.latitude, longitude: bigBen.longitude),
            searchProviderFactory: searchProviderFactory,
            onClose: {
                presentationMode.wrappedValue.dismiss()
            },
            searchCompleteView: { spec in
                DefaultSearchCompleteView(
                    spec: spec,
                    planBuilder: { builder in
                        // Customise the routes planned
                        builder.walkRoute()
                        builder.scooterRoute()
                        builder.transitRoutes()
                    },
                    onClickRoute: { route in
                        self.route = route
                        if route.hasTransitLegs() {
                            isShowingTransitRouteDetails = true
                        } else {
                            isShowingRouteDetails = true
                        }
                    })
            }
        )
        
        NavigationLink(
            destination: routeDetailsView
                .navigationBarTitle("", displayMode: .inline)
                .navigationBarHidden(true),
            isActive: $isShowingTransitRouteDetails) { }
        
        NavigationLink(
            destination: directionsView
                .navigationBarTitle("", displayMode: .inline)
                .navigationBarHidden(true),
            isActive: $isShowingRouteDetails) { }
    }
}
