//
//  LocationPermissionViewModel.swift
//

import Foundation

import Combine
import CoreLocation

class LocationPermissionViewModel: NSObject {
    enum LocationPermissionScreenState {
        case loading
        case needsLocationPermission(canRequestInApp: Bool, buttonTitle: String)
        case locationGrantedAndTracking(buttonTitle: String)
    }

    @Published var currentLocationPermissionScreenState: LocationPermissionScreenState = .loading

    private let locationManager: LocationManager
    private var authorizationStatusCancellable: AnyCancellable?

    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        super.init()

        subscribeToLocationManager()
    }

    func enableLocationInAppTapped() {
        currentLocationPermissionScreenState = .loading
        locationManager.requestWhenInUseLocationPermission()
    }

    private func subscribeToLocationManager() {
        authorizationStatusCancellable = locationManager.$authorizationStatus
            .sink { [weak self] authorizationStatus in
                guard let strongSelf = self else { return }

                let canRequestLocationPermissionInApp = strongSelf.ableToRequestLocationPermissionInApp(with: authorizationStatus)
                let needsLocationPermission = ((authorizationStatus != .authorizedAlways)
                    && (authorizationStatus != .authorizedWhenInUse))

                if needsLocationPermission {
                    strongSelf.locationManager.stopUpdatingLocation()

                    let buttonTitle = strongSelf.allowLocationButtonTitle(canRequestInApp: canRequestLocationPermissionInApp)
                    strongSelf.currentLocationPermissionScreenState = .needsLocationPermission(canRequestInApp: canRequestLocationPermissionInApp,
                                                                                               buttonTitle: buttonTitle)
                } else {
                    strongSelf.locationManager.startUpdatingLocation()
                    strongSelf.currentLocationPermissionScreenState = .locationGrantedAndTracking(buttonTitle: strongSelf.locationGrantedButtonTitle())
                }
            }
    }

    private func allowLocationButtonTitle(canRequestInApp: Bool) -> String {
        NSLocalizedString("Enable_Location_Button_Title", comment: "The title of the button used to grant location permissions")
    }

    private func locationGrantedButtonTitle() -> String {
        NSLocalizedString("Dismiss_And_Save_Modal_Screen_Button_Title", comment: "The title of the button used to dismiss the location permissions screen")
    }

    private func ableToRequestLocationPermissionInApp(with status: CLAuthorizationStatus?) -> Bool {
        guard let validAuthorizationStatus = status else { return false }

        switch validAuthorizationStatus {
        case .notDetermined:
            return true
        case .restricted, .denied:
            return false
        case .authorizedAlways:
            return false
        case .authorizedWhenInUse:
            return true
        @unknown default:
            return false
        }
    }
}
