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

    @Published var routePathSegments: [PathGeometrySegment]?

    @Published var latestError: Error?

    func startNavigating(from start: CLLocationCoordinate2D,
                         to destination: CLLocationCoordinate2D,
                         profile: Profile) {

        CitymapperDirections.shared.planBikeRoutes(start: start, end: destination, profiles: [profile], withCompletion: { [weak self] result in
            guard let strongSelf = self else {
                return
            }

            switch result {
            case let .failure(error):
                strongSelf.latestError = error
            case let .success(results):
                guard let route = results.routes.first else {
                    return
                }
                CitymapperNavigationTracking.shared.routeProgressDelegate = strongSelf
                CitymapperNavigationTracking.shared.guidanceEventDelegate = strongSelf

                let trackingConfiguration = TrackingConfiguration(enableOnDeviceLogging: true)
                CitymapperNavigationTracking.shared.startNavigation(route: route,
                                                                    trackingConfiguration: trackingConfiguration
                ) { result in
                    switch result {
                    case let .failure(reason):
                        NSLog("Failed to start tracking: \(reason)")
                    default: break
                    }
                }
            }
        })

    }

    func stopNavigating() {
        CitymapperNavigationTracking.shared.endNavigation()
    }
}

extension GuidanceFetcher: RouteProgressDelegate {

    func routeProgressUpdated(routeProgress: RouteProgress?) {
        self.activeRoute = routeProgress?.route
        self.legProgress = routeProgress?.legProgress
        self.routePathSegments = routeProgress?.pathGeometrySegments
    }
}

extension GuidanceFetcher: GuidanceEventDelegate {

    func triggerGuidanceEvent(_ guidanceEvent: GuidanceEvent) {
        self.guidanceEvent = guidanceEvent
    }
}
