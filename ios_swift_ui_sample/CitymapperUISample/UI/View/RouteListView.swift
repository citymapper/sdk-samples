//
//  RouteListView.swift
//  CitymapperUISample
//
//  Created by Iuliia Ponomareva on 02/09/2022.
//

import CitymapperNavigation
import CitymapperUI
import SwiftUI

struct RouteListView: View {
    
    @State private var isShowingTransitRouteDetails = false
    @State private var isShowingRouteDetails = false
    @State private (set) var route: Route? = nil
    @ObservedObject var viewModel: RouteListViewModel
    
    let didSwapStartAndEnd: () -> Void
    let startHasBeenFocused: () -> Void
    let endHasBeenFocused: () -> Void
    let timePickerButtonDidTap: () -> Void
    
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
        VStack(spacing: 0) {
            SearchHeaderView(
                start: viewModel.routePlanningSpec.start,
                end: viewModel.routePlanningSpec.end,
                timeConstraint: viewModel.routePlanningSpec.timeConstraint,
                didSwapStartAndEnd: { didSwapStartAndEnd() },
                startHasBeenFocused: { startHasBeenFocused() },
                endHasBeenFocused: { endHasBeenFocused() },
                timePickerButtonDidTap: { timePickerButtonDidTap() }
            )
            .frame(maxHeight: 190)
            LinearGradient(colors: [.gray, .white], startPoint: .top, endPoint: .bottom)
                .frame(height: 4)
                .opacity(0.8)
            
            if viewModel.routes.isEmpty {
                Spacer(minLength: 20)
                ProgressView("Loading...")
                Spacer(minLength: 20)
            } else {
                RoutesView(routes: viewModel.routes) { route in
                    self.route = route
                    if route.hasTransitLegs() {
                        isShowingTransitRouteDetails = true
                    } else {
                        isShowingRouteDetails = true
                    }
                }.ignoresSafeArea(.all, edges: .bottom)
            }
            
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
}
