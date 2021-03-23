//
//  UserDefaultsStore.swift
//  DemoMapper
//
//  Created by Tom Humphrey on 19/03/2021.
//

import Foundation

extension UserDefaults {
    private static let kCurrentSelectedApi = "kCurrentSelectedApi"
    private static let kCurrentHireBrandId = "kCurrentHireBrandId"

    @objc var currentSelectedApi: String {
        get {
            if let currentApi = value(forKey: Self.kCurrentSelectedApi) as? String {
                return currentApi
            }
            return AvailableApi.bikeRide.rawValue
        }
        set {
            set(newValue, forKey: Self.kCurrentSelectedApi)
        }
    }

    @objc var currentHireBrandId: String? {
        get {
            value(forKey: Self.kCurrentHireBrandId) as? String
        }
        set {
            set(newValue, forKey: Self.kCurrentHireBrandId)
        }
    }
}
