//
//  Configuration.swift
//  CitymapperUISample
//
//  Created by Iuliia Ponomareva on 02/09/2022.
//

import Foundation
import MapKit


// Please use different centre coordinates and span to search in your area, sample app configured to search in London
struct LocationConstants {
    static let bigBenLocation = CLLocationCoordinate2D(latitude: 51.5007, longitude: 0.1246)
    static let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.033212, longitudeDelta: 0.054932)
}

struct BrandConstants {
    static let bikeBrandId = "LondonCycleHire"
    static let scooterBrandId = "Dott"
}

