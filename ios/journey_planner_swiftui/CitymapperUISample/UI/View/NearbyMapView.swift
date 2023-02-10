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
        
        let theme = BasicTheme()
        let nearbyViewModel = NearbyViewModel(theme: theme)
        
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
            fallbackMapCenter: .center(CLLocationCoordinate2D(latitude: 51.49, longitude: 0.14)),
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
