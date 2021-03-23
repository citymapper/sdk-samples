//
//  ApiSelectionViewModel.swift
//  DemoMapper
//
//  Created by Tom Humphrey on 10/03/2021.
//

import UIKit

enum AvailableApi: String, CaseIterable {
    case walk = "planWalkRoutes()"
    case bikeRide = "planBikeRoutes()"
    case scooterRide = "planScooterRoute()"
    case scooter = "planScooterHireRoute()"
    case bike = "planBikeHireRoutes()"
}

extension AvailableApi {
    func requiresBrandId() -> Bool {
        switch self {
        case .walk, .bikeRide, .scooterRide:
            return false
        case .scooter, .bike:
            return true
        }
    }

    func acceptsRouteProfiles() -> Bool {
        switch self {
        case .walk, .scooter, .scooterRide:
            return false
        case .bike, .bikeRide:
            return true
        }
    }
}

class ApiSelectionViewModel: NSObject {
    private let guidanceFetcher: GuidanceFetcher
    var selectedRowIndex = 0

    init(guidanceFetcher: GuidanceFetcher) {
        self.guidanceFetcher = guidanceFetcher
        super.init()

        let currentApi = AvailableApi(rawValue: UserDefaults.standard.currentSelectedApi) ?? .bikeRide
        if let storedRowIndex = AvailableApi.allCases.firstIndex(of: currentApi) {
            self.selectedRowIndex = storedRowIndex
        }
    }

    func selectApi(atRow selectedApiRow: Int) {
        guard AvailableApi.allCases.count > selectedApiRow else {
            return
        }

        let newlySelectedApi = AvailableApi.allCases[selectedApiRow].rawValue
        let previouslySelectedApi = UserDefaults.standard.currentSelectedApi

        guard newlySelectedApi != previouslySelectedApi else { return }

        guidanceFetcher.stopNavigating()
        UserDefaults.standard.currentSelectedApi = AvailableApi.allCases[selectedApiRow].rawValue
    }
}

extension ApiSelectionViewModel: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        AvailableApi.allCases.count
    }
}

extension ApiSelectionViewModel: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {
        guard row < AvailableApi.allCases.count else {
            return nil
        }

        return AvailableApi.allCases[row].rawValue
    }
}
