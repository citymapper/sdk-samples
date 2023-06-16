//
//  RoutesView.swift
//  CitymapperUISample
//
//  Created by Iuliia Ponomareva on 02/09/2022.
//

import CitymapperNavigation
import CitymapperUI
import Foundation
import SwiftUI

struct RoutesView: UIViewControllerRepresentable {
    
    class Coordinator: RouteListDelegate {
        let parent: RoutesView
        
        init(parent: RoutesView) {
            self.parent = parent
        }
        
        func showRouteDetails(for route: Route) {
            parent.showRouteDetails(route)
        }
        
        func listContentHeightUpdated(newHeight: CGFloat) { }
    }
    
    @State private (set) var routes: [Route]
    let showRouteDetails: (Route) -> Void
    
    func makeUIViewController(context: Context) -> some UIViewController {
        return RouteListContainer.createWrappedRouteListController(routes: routes,
                                                                   delegate: context.coordinator,
                                                                   scrollEnabled: true) as UIViewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}

