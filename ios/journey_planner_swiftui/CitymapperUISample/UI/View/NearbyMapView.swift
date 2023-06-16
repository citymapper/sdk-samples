//
//  NearbyMapView.swift
//  CitymapperUISample
//
//  Created by Iuliia Ponomareva on 24/11/2022.
//

@_spi(CMExperimentalNearby) import CitymapperUI
import Foundation
import SwiftUI
import UIKit
import CitymapperCore
import CoreLocation
import MapKit

private class NearbyMapViewState: ObservableObject {
    internal init(showAdditionalUI: Binding<Bool>) {
        self._showAdditionalUIBinding = showAdditionalUI
        self.showAdditionalUIPublished = showAdditionalUI.wrappedValue
    }    

    /// Binding: causes parent view to update
    @Binding private var showAdditionalUIBinding: Bool
    
    /// Published: causes nearby map view to update
    @Published private var showAdditionalUIPublished: Bool
    
    var showAdditionalUI: Bool {
        get {
            showAdditionalUIPublished
        } set {
            showAdditionalUIBinding = newValue
            showAdditionalUIPublished = newValue
        }
    }
    
    func closeTapped() {
        showAdditionalUI = false
    }
    
    func mapTapped() {
        showAdditionalUI = true
    }
}

struct NearbyMapView: UIViewControllerRepresentable {
    internal init(showAdditionalUI: Binding<Bool>) {
        self.state = .init(showAdditionalUI: showAdditionalUI)
    }
    
    @ObservedObject private var state: NearbyMapViewState
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let region = MKCoordinateRegion(
            center: .init(latitude: 4.6542644, longitude: -74.1189713),
            latitudinalMeters: 25000,
            longitudinalMeters: 25000
        )
        let theme = BasicTheme()
        let nearbyViewModel = NearbyViewModel(defaultMapFocus: { location in
            if let location, region.contains(coordinate: location) {
                return .center(location)
            } else {
                return .region(region)
            }
        })
        
        let nearbyCardsVC = NearbyFiltersAndCardsViewController(
            theme: theme,
            nearbyViewModel: nearbyViewModel,
            closeButtonAction: {
                nearbyViewModel.clearSelectionAndFilter()
                self.state.closeTapped()
        })

        let nearbyMapVC = NearbyMapViewController(
            theme: theme,
            nearbyViewModel: nearbyViewModel,
            childControllersToAdd: [
                (nearbyCardsVC, UIEdgeInsets(top: 0, left: 12, bottom: 0, right: -12))
            ],
            didTapMap: {
                self.state.mapTapped()
            }
        )
        
        return nearbyMapVC
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        uiViewController.children.first { $0 is NearbyFiltersAndCardsViewController}?.view.isHidden = !state.showAdditionalUI
    }
}

private extension MKCoordinateRegion {
    func contains(coordinate: CLLocationCoordinate2D) -> Bool {
        // Doesn't account for regions which cross the 180-degree meridian, for simplicity
        
        let latitudeDeltaHalf = span.latitudeDelta / 2.0
        let longitudeDeltaHalf = span.longitudeDelta / 2.0
        
        let centerLatitude = center.latitude
        let centerLongitude = center.longitude
        
        let coordinateLatitude = coordinate.latitude
        let coordinateLongitude = coordinate.longitude
        
        let latitudeCondition = abs(centerLatitude - coordinateLatitude) <= latitudeDeltaHalf
        let longitudeCondition = abs(centerLongitude - coordinateLongitude) <= longitudeDeltaHalf
        
        return latitudeCondition && longitudeCondition
    }
}
