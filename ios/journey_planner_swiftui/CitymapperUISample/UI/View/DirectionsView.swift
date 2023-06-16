//
//  DirectionsView.swift
//  CitymapperUISample
//
//  Created by Iuliia Ponomareva on 07/09/2022.
//

import CitymapperNavigation
import CitymapperUI
import Foundation
import SwiftUI

struct DirectionsView: UIViewControllerRepresentable {
    
    @Environment(\.presentationMode) var presentationMode
    let route: Route
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let navigationTracking = CitymapperNavigationTracking.shared
        
        let viewConfig = DirectionsViewController.Configuration(
            uiControls: .defaultControls,
            stopNavigationTrackingHandler: { _ in .displayOverview },
            closeViewControllerHandler: {
                presentationMode.wrappedValue.dismiss()
            }
        )

        let trackingConfig = TrackingConfiguration(enableOnDeviceLogging: true)

        let navigableRoute = navigationTracking.createNavigableRoute(
            seedRoute: route,
            fetchOnDemandServicesForRouteUpdates: true,
            trackingConfiguration: trackingConfig
        )

        return DirectionsViewController(for: navigableRoute,
                                        configuration: viewConfig)
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
