//
//  LocationManager.swift
//

import Foundation

import Combine
import CoreLocation

class LocationManager: NSObject {
    private let locationManagerReadyQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.isSuspended = true
        return queue
    }()

    private var internalLocationManager: CLLocationManager?

    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var mostRecentLocation: CLLocation?

    override init() {
        super.init()

        assert(Thread.isMainThread)
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        self.internalLocationManager = locationManager
        self.authorizationStatus = locationManager.authorizationStatus

        if canUpdateUserLocation(with: locationManager.authorizationStatus) {
            startUpdatingLocation()
        }

        locationManagerReadyQueue.isSuspended = false
    }

    func requestWhenInUseLocationPermission() {
        performWhenSystemLocationManagerReady { [weak self] in
            self?.internalLocationManager?.requestWhenInUseAuthorization()
        }
    }

    func canUpdateUserLocation(with currentAuthStatus: CLAuthorizationStatus) -> Bool {
        switch currentAuthStatus {
        case .notDetermined, .restricted, .denied:
            return false
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        @unknown default:
            return false
        }
    }

    func startUpdatingLocation() {
        performWhenSystemLocationManagerReady { [weak self] in
            self?.internalLocationManager?.startUpdatingLocation()
        }
    }

    func stopUpdatingLocation() {
        performWhenSystemLocationManagerReady { [weak self] in
            self?.internalLocationManager?.stopUpdatingLocation()
        }
    }

    private func performWhenSystemLocationManagerReady(_ block: @escaping () -> Void) {
        if internalLocationManager != nil {
            block()
        } else {
            locationManagerReadyQueue.addOperation {
                block()
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let mostRecentLocationUpdate = locations.last else { return }

        mostRecentLocation = mostRecentLocationUpdate
    }

    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
    }
}
