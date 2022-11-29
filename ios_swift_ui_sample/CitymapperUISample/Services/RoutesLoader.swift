//
//  RoutesLoader.swift
//  CitymapperUISample
//
//  Created by Iuliia Ponomareva on 02/09/2022.
//

import CitymapperCore
@_spi(CM) import CitymapperNavigation
import Foundation
import CoreLocation

protocol RoutesLoader {
    func loadRoutes(startCoordinate: CLLocationCoordinate2D,
                    endCoordinate: CLLocationCoordinate2D,
                    departOrArriveConstraint: DepartOrArriveConstraint) async -> [Route]
}

struct DefaultRoutesLoader: RoutesLoader {
    
    enum RouteOrder: Int {
        case walk
        case bike
        case scooter
        case transit
        case taxi
        case bikeHire
        case scooterHire
    }
    
    func loadRoutes(startCoordinate: CLLocationCoordinate2D,
                    endCoordinate: CLLocationCoordinate2D,
                    departOrArriveConstraint: DepartOrArriveConstraint) async -> [Route] {
        
        let resultsWithOrder = await withTaskGroup(of: (order: RouteOrder, [Route]?).self) { [startCoordinate, endCoordinate] group -> [(order: RouteOrder, [Route])] in
            
            group.addTask { (.walk, try? await [getWalkingRoute(from: startCoordinate, to: endCoordinate)]) }
            group.addTask { (.bike, try? await [getBikeRoute(from: startCoordinate, to: endCoordinate)]) }
            group.addTask { (.scooter, try? await [getScooterRoute(from: startCoordinate, to: endCoordinate)]) }
            group.addTask { (.transit, try? await getTransitRoutes(from: startCoordinate, to: endCoordinate, departOrArriveConstraint: departOrArriveConstraint)) }
            group.addTask { (.taxi, try? await getTaxiRoutes(from: startCoordinate, to: endCoordinate)) }
            group.addTask { (.bikeHire, try? await [getBikeHireRoute(from: startCoordinate, to: endCoordinate, brandId: BrandConstants.bikeBrandId)]) }
            group.addTask { (.scooterHire, try? await [getScooterHireRoute(from: startCoordinate, to: endCoordinate, brandId: BrandConstants.scooterBrandId)]) }
            
            return await group.reduce(into: [(RouteOrder, [Route])]()) {
                if let route = $1.1 {
                    $0.append(($1.0, route))
                }
            }
        }
        
        return resultsWithOrder
            .sorted(by: { $0.order.rawValue < $1.order.rawValue })
            .reduce(into: [Route](), {
                $0.append(contentsOf: $1.1)
            })
    }
    
    private func getWalkingRoute(from startCoordinate: CLLocationCoordinate2D,
                                 to endCoordinate: CLLocationCoordinate2D) async throws -> Route {
        return try await newResultSet(start: startCoordinate, end: endCoordinate, routingRequestId: nil) {
            $0.walkRoute()
        }
        .routes()
        .firstRouteOrThrow()
    }
    
    private func getBikeRoute(from startCoordinate: CLLocationCoordinate2D,
                              to endCoordinate: CLLocationCoordinate2D,
                              profile: Profile? = nil) async throws -> Route {
        return try await newResultSet(start: startCoordinate, end: endCoordinate, routingRequestId: nil) {
            $0.bikeRoute(profile: profile ?? .regular)
        }
        .routes()
        .firstRouteOrThrow()
    }
    
    private func getScooterRoute(from startCoordinate: CLLocationCoordinate2D,
                                 to endCoordinate: CLLocationCoordinate2D) async throws -> Route {
        return try await newResultSet(start: startCoordinate, end: endCoordinate, routingRequestId: nil) {
            $0.scooterRoute()
        }
        .routes()
        .firstRouteOrThrow()
    }
    
    private func getTransitRoutes(from startCoordinate: CLLocationCoordinate2D,
                                  to endCoordinate: CLLocationCoordinate2D,
                                  departOrArriveConstraint: DepartOrArriveConstraint) async throws -> [Route] {
        return try await newResultSet(start: startCoordinate, end: endCoordinate, routingRequestId: nil, departOrArriveConstraint: departOrArriveConstraint) {
            $0.transitRoutes()
        }
        .routes()
        .resultOrThrow()
        .routes
    }
    
    private func getTaxiRoutes(from startCoordinate: CLLocationCoordinate2D,
                               to endCoordinate: CLLocationCoordinate2D,
                               brandIds: [String]? = nil) async throws -> [Route] {
        return try await newResultSet(start: startCoordinate, end: endCoordinate, routingRequestId: nil) {
            $0.taxiRoutes(brandIds: brandIds)
        }
        .routes()
        .resultOrThrow()
        .routes
    }
    
    private func getBikeHireRoute(from startCoordinate: CLLocationCoordinate2D,
                                  to endCoordinate: CLLocationCoordinate2D,
                                  brandId: String) async throws -> Route {
        return try await newResultSet(start: startCoordinate, end: endCoordinate, routingRequestId: nil) {
            $0.bikeHireRoute(brandId: brandId)
        }
        .routes()
        .firstRouteOrThrow()
    }
    
    private func getScooterHireRoute(from startCoordinate: CLLocationCoordinate2D,
                                     to endCoordinate: CLLocationCoordinate2D,
                                     brandId: String) async throws -> Route {
        return try await newResultSet(start: startCoordinate, end: endCoordinate, routingRequestId: nil) {
            $0.scooterHireRoute(brandId: brandId)
        }
        .routes()
        .firstRouteOrThrow()
    }
    
    private func newResultSet(start: CLLocationCoordinate2D,
                              end: CLLocationCoordinate2D,
                              routingRequestId: String?,
                              departOrArriveConstraint: DepartOrArriveConstraint = .departApproximateNow,
                              builder: (RouteResultSet.Builder) -> Void) -> RouteResultSet {
        return Citymapper.shared.directions.buildResultSet(start: start, end: end, timeConstraint: departOrArriveConstraint) {
            
            if let routingRequestId = routingRequestId {
                $0.addExtra(key: "routing_request_id", value: routingRequestId, persistent: true)
            }
            
            builder($0)
        }
    }
}

private extension DirectionsApiResults {
    
    func resultOrThrow() throws -> DirectionsResults {
        switch self {
        case .success(let results):
            return results
        case .failure(let error):
            throw error
        }
    }
    
    func firstRouteOrThrow() throws -> Route {
        let results = try resultOrThrow()
        
        guard let route = results.routes.first else {
            throw DirectionsError.noRoutesFound(message: "Tried to unwrap")
        }
        
        return route
    }
}

extension DirectionsError: Error {
    
}
