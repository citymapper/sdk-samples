//
//  RouteDetailsView.swift
//  CitymapperUISample
//
//  Created by Iuliia Ponomareva on 07/09/2022.
//

import CitymapperNavigation
import CitymapperUI
import Foundation
import SwiftUI

struct RouteDetailsView: UIViewControllerRepresentable {
    
    @Environment(\.presentationMode) var presentationMode
    let route: Route
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let detailsConfig = RouteDetailsConfiguration(backBehaviour: .visible(actionOnTap: {
            presentationMode.wrappedValue.dismiss()
        }))
        return RouteDetailsContainer.createWrappedRouteDetailsController(route: route,
                                                                         configuration: detailsConfig)
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
