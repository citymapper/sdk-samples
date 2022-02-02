//
//  GuidanceFetcher.swift
//

import Foundation

import Combine
import CoreLocation

import CitymapperNavigation

final class GuidanceFetcher: NSObject {
    @Published var activeRoute: Route?
    @Published var alternateInactiveRoutes: [Route] = []

    @Published var legProgress: LegProgress? = nil
    @Published var guidanceEvent: GuidanceEvent? = nil

    @Published var routePathSegments: PathGeometrySegments?

    @Published var latestError: Error?

    func startNavigating(from start: CLLocationCoordinate2D,
                         to destination: CLLocationCoordinate2D,
                         profile: Profile,
                         originalVehicleLocation: Coords? = nil) {
        let storedCurrentApiString = UserDefaults.standard.currentSelectedApi
        let selectedApi = AvailableApi(rawValue: storedCurrentApiString) ?? .bikeRide

        switch selectedApi {
        case .walk:
            CitymapperDirections.shared.planWalkRoutes(start: start, end: destination) { [weak self] result in
                self?.startNavigatingCompletion(result: result)
            }
        case .bikeRide:
            CitymapperDirections.shared.planBikeRoutes(start: start, end: destination, profiles: [profile]) { [weak self] result in
                self?.startNavigatingCompletion(result: result)
            }
        case .scooterRide:
            CitymapperDirections.shared.planScooterRoute(start: start, end: destination) { [weak self] result in
                self?.startNavigatingCompletion(result: result)
            }
        case .scooter:
            guard let validBrandId = currentHireBrandId(),
                  !validBrandId.isEmpty else {
                errorEncountered(withTitle: "Scooter hire brand id invalid")
                return
            }

            CitymapperDirections.shared.planScooterHireRoute(start: start,
                                                             end: destination,
                                                             brandId: validBrandId,
                                                             originalVehicleLocation: originalVehicleLocation) { [weak self] result in
                self?.startNavigatingCompletion(result: result)
            }
        case .bike:
            guard let validBrandId = currentHireBrandId(),
                  !validBrandId.isEmpty else {
                errorEncountered(withTitle: "Bike hire brand id invalid")
                return
            }

            CitymapperDirections.shared.planBikeHireRoutes(start: start,
                                                           end: destination,
                                                           brandId: validBrandId,
                                                           originalVehicleLocation: originalVehicleLocation,
                                                           profiles: [profile]) { [weak self] result in
                self?.startNavigatingCompletion(result: result)
            }
        }
    }

    private func currentHireBrandId() -> String? {
        UserDefaults.standard.currentHireBrandId
    }

    private func errorEncountered(withTitle title: String) {
        latestError = GuidanceFetcherError(title)
    }

    private func startNavigatingCompletion(result: ApiResult<DirectionsResults, DirectionsError>) {
        switch result {
        case let .failure(error):
            latestError = getGuidanceFetcherError(failure: error)
        case let .success(results):
            guard let route = results.routes.first else {
                return
            }
            CitymapperNavigationTracking.shared.addRouteProgressObserver(observer: self)
            CitymapperNavigationTracking.shared.addGuidanceEventObserver(observer: self)

            let trackingConfiguration = TrackingConfiguration(enableOnDeviceLogging: true)
            CitymapperNavigationTracking.shared.startNavigation(route: route,
                                                                trackingConfiguration: trackingConfiguration) { result in
                switch result {
                case let .failure(reason):
                    NSLog("Failed to start tracking: \(reason)")
                default: break
                }
            }
        }
    }

    private func getGuidanceFetcherError(failure: ApiFailure<DirectionsError>) -> GuidanceFetcherError {
        switch failure {
        case .networkFailure:
            return GuidanceFetcherError("Network Error")
        case let .httpFailure(code: code, error):
            if let error = error {
                switch error {
                case .noRoutesFound(message: _):
                    return GuidanceFetcherError("No routes found")
                case .startOrEndOutOfCoverage(message: _):
                    return GuidanceFetcherError("Outside coverage")
                case .unknown(message: _):
                    return GuidanceFetcherError("Unknown error")
                }
            } else {
                return GuidanceFetcherError("HTTP \(code)")
            }
        case .unknownFailure:
            return GuidanceFetcherError("Unknown error")
        }
    }

    func stopNavigating() {
        CitymapperNavigationTracking.shared.endNavigation()
    }

    func updateVehicleActiveState(isActive: Bool) {
        if isActive {
            CitymapperNavigationTracking.shared.setVehicleLockState(state: .unlocked())
        } else {
            CitymapperNavigationTracking.shared.setVehicleLockState(state: .locked)
        }
    }
}

extension GuidanceFetcher: RouteProgressObserver {
    func routeProgressUpdated(routeProgress: RouteProgress?) {
        activeRoute = routeProgress?.route
        legProgress = routeProgress?.legProgress
        routePathSegments = routeProgress?.pathGeometrySegments
    }
}

extension GuidanceFetcher: GuidanceEventObserver {
    func guidanceEventTriggered(_ guidanceEvent: GuidanceEvent) {
        self.guidanceEvent = guidanceEvent
    }
}

struct GuidanceFetcherError: LocalizedError {
    var errorDescription: String

    init(_ errorDescription: String) {
        self.errorDescription = errorDescription
    }
}
