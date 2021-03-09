//
//  MapListViewModel.swift
//

import Foundation

import Combine
import CoreLocation

import CitymapperNavigation

final class MapListViewModel {

    enum MapTapState {
        case unknown
        case startAndEnd(_ start: CLLocationCoordinate2D, _ end: CLLocationCoordinate2D)
    }

    @Published var currentMapTapState: MapTapState = .unknown
    @Published var selectedProfile: Profile = .regular

    enum MapUserLocationTracking {
        case followingUser
        case notFollowingUser
    }

    private var currentMapUserLocationTracking: MapUserLocationTracking = .followingUser
    @Published var centerMapOnLocationUpdates = true
    @Published var showMapResetButton = false
    @Published var showShareLogsButton = true
    @Published var showEndActiveNavigationButton = false

    private let guidanceFetcher: GuidanceFetcher
    private let locationManager: LocationManager

    @Published var primaryRouteDisplaying: Route?
    @Published var routeMapPathGeometry: [PathGeometrySegment]?
    @Published var alternateInactiveRoutes: [Route] = []
    @Published var latestLocation: CLLocation?

    @Published var legProgress: LegProgress? = nil
    @Published var guidanceEvent: GuidanceEvent? = nil

    @Published var latestError: Error?

    private var activeRouteCancellable: AnyCancellable?
    private var mapRoutePathCancellable: AnyCancellable?
    private var alternateInactiveRoutesCancellable: AnyCancellable?
    private var legProgressCancellable: AnyCancellable?
    private var latestLocationCancellable: AnyCancellable?
    private var latestErrorCancellable: AnyCancellable?
    private var latestGuidanceEventCancellable: AnyCancellable?

    init(_ guidanceFetcher: GuidanceFetcher,
         locationManager: LocationManager) {
        self.guidanceFetcher = guidanceFetcher
        self.locationManager = locationManager
        self.subscribeToModel()
    }

    private func subscribeToModel() {
        self.activeRouteCancellable = self.guidanceFetcher.$activeRoute.sink { [weak self] newActiveRoute in
            self?.primaryRouteDisplaying = newActiveRoute
            self?.showEndActiveNavigationButton = (newActiveRoute != nil)
            if newActiveRoute == nil {
                self?.legProgress = nil
                self?.currentMapTapState = .unknown
            }
        }
        self.mapRoutePathCancellable = self.guidanceFetcher.$routePathSegments.assign(to: \.routeMapPathGeometry, on: self)
        self.alternateInactiveRoutesCancellable = self.guidanceFetcher.$alternateInactiveRoutes.assign(to: \.alternateInactiveRoutes, on: self)
        self.legProgressCancellable = self.guidanceFetcher.$legProgress.assign(to: \.legProgress, on: self)
        self.latestLocationCancellable = self.locationManager.$mostRecentLocation.assign(to: \.latestLocation, on: self)
        self.latestErrorCancellable = self.guidanceFetcher.$latestError.assign(to: \.latestError, on: self)
        self.latestGuidanceEventCancellable = self.guidanceFetcher.$guidanceEvent.assign(to: \.guidanceEvent, on: self)
    }

    private func startNavigating(from start: CLLocationCoordinate2D,
                                 to destination: CLLocationCoordinate2D,
                                 profile: Profile) {
        self.guidanceFetcher.startNavigating(from: start,
                                             to: destination,
                                             profile: profile)
    }

    private func stopNavigating() {
        self.guidanceFetcher.stopNavigating()
    }

    func shouldShowLocationPermissionScreen() -> Bool {
        guard let validLocationAuthStatus = self.locationManager.authorizationStatus else {
            return true
        }
        
        switch validLocationAuthStatus {
        case .notDetermined, .restricted, .denied:
            return true
        case .authorizedAlways, .authorizedWhenInUse:
            return false
        @unknown default:
            return true
        }
    }

    func locationPermissionScreen() -> LocationPermissionViewController {
        let viewModel = LocationPermissionViewModel(locationManager: self.locationManager)
        return LocationPermissionViewController(viewModel: viewModel)
    }

    func setCurrentProfile(profile: Profile) {
        selectedProfile = profile
    }

    func didTapMap(at newCoordinate: CLLocationCoordinate2D) {
        switch self.currentMapTapState {
        case .unknown:
            let userCoordinate = locationManager.mostRecentLocation?.coordinate
            self.primaryRouteDisplaying = nil
            if let validUserCoordinate = userCoordinate {
                self.currentMapTapState = .startAndEnd(validUserCoordinate, newCoordinate)
                self.startNavigating(from: validUserCoordinate,
                                     to: newCoordinate,
                                     profile: selectedProfile)
            } else {
                self.currentMapTapState = .unknown
            }
        case .startAndEnd:
            self.primaryRouteDisplaying = nil
            self.legProgress = nil
            self.currentMapTapState = .unknown
        }
    }

    func userDidInteractWithMap() {
        self.currentMapUserLocationTracking = .notFollowingUser
        self.centerMapOnLocationUpdates = false
        self.showMapResetButton = true
    }

    func didTapResetMap() {
        self.currentMapUserLocationTracking = .followingUser
        self.centerMapOnLocationUpdates = true
        self.showMapResetButton = false
    }

    func didTapEndActiveNavigation() {
        self.stopNavigating()
    }
}
