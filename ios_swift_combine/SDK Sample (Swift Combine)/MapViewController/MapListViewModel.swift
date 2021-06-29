//
//  MapListViewModel.swift
//

import UIKit

import Combine
import CoreLocation

import CitymapperNavigation

final class MapListViewModel {
    lazy var speaker: Speaker = SpeakerConcrete()

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
    private let vehicleActivityManager: VehicleActivityManager

    @Published var primaryRouteDisplaying: Route?
    @Published var routeMapPathGeometry: PathGeometrySegments?
    @Published var alternateInactiveRoutes: [Route] = []
    @Published var latestLocation: CLLocation?

    private var activeRoute: Route?
    @Published var guidanceEvent: GuidanceEvent? = nil

    @Published var currentApi: String = AvailableApi.bikeRide.rawValue
    @Published var shouldShowProfileSwitcher = true

    @Published var currentBrandId: String?
    @Published var shouldShowBrandIdButton = false

    private var legProgress: LegProgress?
    private var isVehicleActive = false
    @Published var listSpecs: [TableCellSpec] = []

    @Published var latestError: Error?

    private var activeRouteCancellable: AnyCancellable?
    private var mapRoutePathCancellable: AnyCancellable?
    private var alternateInactiveRoutesCancellable: AnyCancellable?
    private var legProgressCancellable: AnyCancellable?
    private var latestLocationCancellable: AnyCancellable?
    private var latestErrorCancellable: AnyCancellable?
    private var latestGuidanceEventCancellable: AnyCancellable?
    private var currentApiCancellable: AnyCancellable?
    private var currentBrandIdCancellable: AnyCancellable?
    private var currentVehicleActiveCancellable: AnyCancellable?

    init(_ guidanceFetcher: GuidanceFetcher,
         locationManager: LocationManager,
         vehicleActivityManager: VehicleActivityManager) {
        self.guidanceFetcher = guidanceFetcher
        self.locationManager = locationManager
        self.vehicleActivityManager = vehicleActivityManager
        subscribeToModel()
    }

    private func subscribeToModel() {
        activeRouteCancellable = guidanceFetcher.$activeRoute.sink { [weak self] newActiveRoute in
            self?.activeRoute = newActiveRoute
            self?.primaryRouteDisplaying = newActiveRoute
            self?.showEndActiveNavigationButton = (newActiveRoute != nil)
            if newActiveRoute == nil {
                self?.legProgress = nil
                self?.currentMapTapState = .unknown
            }

            self?.updateListSpecs()
        }

        mapRoutePathCancellable = guidanceFetcher.$routePathSegments.assign(to: \.routeMapPathGeometry, on: self)
        alternateInactiveRoutesCancellable = guidanceFetcher.$alternateInactiveRoutes.assign(to: \.alternateInactiveRoutes, on: self)
        latestLocationCancellable = locationManager.$mostRecentLocation.assign(to: \.latestLocation, on: self)
        latestErrorCancellable = guidanceFetcher.$latestError.assign(to: \.latestError, on: self)
        latestGuidanceEventCancellable = guidanceFetcher.$guidanceEvent.assign(to: \.guidanceEvent, on: self)
        currentApiCancellable = UserDefaults.standard.publisher(for: \.currentSelectedApi)
            .sink { [weak self] currentApiString in
                self?.currentApi = currentApiString

                guard let currentApi = AvailableApi(rawValue: currentApiString) else {
                    self?.shouldShowProfileSwitcher = false
                    return
                }

                self?.shouldShowProfileSwitcher = currentApi.acceptsRouteProfiles()
                self?.shouldShowBrandIdButton = currentApi.requiresBrandId()
            }
        currentBrandIdCancellable = UserDefaults.standard.publisher(for: \.currentHireBrandId)
            .assign(to: \.currentBrandId, on: self)

        legProgressCancellable = guidanceFetcher.$legProgress
            .sink { [weak self] legProgress in
                self?.legProgress = legProgress
                self?.updateListSpecs()
            }

        currentVehicleActiveCancellable = vehicleActivityManager.$isVehicleActive
            .sink { [weak self] isVehicleActive in
                self?.isVehicleActive = isVehicleActive
                self?.updateListSpecs()
            }
    }

    private func updateListSpecs() {
        listSpecs = specsForInstructionsTable(legProgress: legProgress,
                                              isVehicleActive: isVehicleActive,
                                              activeRoute: activeRoute)
    }

    private func startNavigating(from start: CLLocationCoordinate2D,
                                 to destination: CLLocationCoordinate2D,
                                 profile: Profile) {
        guidanceFetcher.startNavigating(from: start,
                                        to: destination,
                                        profile: profile)
    }

    private func stopNavigating() {
        vehicleActivityManager.isVehicleActive = false
        guidanceFetcher.stopNavigating()
        speaker.stopSpeaking()
    }

    func shouldShowLocationPermissionScreen() -> Bool {
        guard let validLocationAuthStatus = locationManager.authorizationStatus else {
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
        let viewModel = LocationPermissionViewModel(locationManager: locationManager)
        return LocationPermissionViewController(viewModel: viewModel)
    }

    func apiSelectionScreen() -> ApiSelectionViewController {
        let viewModel = ApiSelectionViewModel(guidanceFetcher: guidanceFetcher)
        return ApiSelectionViewController(viewModel: viewModel)
    }

    func setCurrentProfile(profile: Profile) {
        selectedProfile = profile
    }

    func didTapMap(at newCoordinate: CLLocationCoordinate2D) {
        stopNavigating()

        switch currentMapTapState {
        case .unknown:
            let userCoordinate = locationManager.mostRecentLocation?.coordinate
            primaryRouteDisplaying = nil
            if let validUserCoordinate = userCoordinate {
                currentMapTapState = .startAndEnd(validUserCoordinate, newCoordinate)
                startNavigating(from: validUserCoordinate,
                                to: newCoordinate,
                                profile: selectedProfile)
            } else {
                currentMapTapState = .unknown
            }
        case .startAndEnd:
            primaryRouteDisplaying = nil
            legProgress = nil
            currentMapTapState = .unknown
        }
    }

    func userDidInteractWithMap() {
        currentMapUserLocationTracking = .notFollowingUser
        centerMapOnLocationUpdates = false
        showMapResetButton = true
    }

    func didTapResetMap() {
        currentMapUserLocationTracking = .followingUser
        centerMapOnLocationUpdates = true
        showMapResetButton = false
    }

    func didTapEndActiveNavigation() {
        stopNavigating()
    }

    func didUpdateHireVehicleBrandId(to newBrandId: String?) {
        UserDefaults.standard.currentHireBrandId = newBrandId
    }

    func vehicleActivityToggled() {
        let isVehicleActive = !vehicleActivityManager.isVehicleActive
        vehicleActivityManager.isVehicleActive = isVehicleActive

        guidanceFetcher.updateVehicleActiveState(isActive: isVehicleActive)
    }
}

extension MapListViewModel {
    private func attributedText(from instruction: Instruction,
                                distance: Distance?,
                                duration: Duration?) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.left

        let boldTextAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .bold),
            NSAttributedString.Key.foregroundColor: UIColor.black,
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ]

        guard !instruction.isDepart else {
            return NSAttributedString(string: instruction.descriptionText,
                                      attributes: boldTextAttributes)
        }

        let lightTextAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .light),
            NSAttributedString.Key.foregroundColor: UIColor.systemBlue,
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ]

        let attributedInstructionText = NSAttributedString(string: "\n\(instruction.descriptionText)",
                                                           attributes: lightTextAttributes)

        let localisedMetersText = NSLocalizedString("Visual_Instruction_Meters_Format", comment: "Describes the number of meters until an instruction")
        let metersValueString = distance.flatMap { "\(Int(round($0.inMeters)))" } ?? ""
        let completedText = NSMutableAttributedString(string: String(format: localisedMetersText,
                                                                     metersValueString),
                                                      attributes: boldTextAttributes)

        completedText.append(attributedInstructionText)
        return completedText
    }

    private func specsForInstructionsTable(legProgress: LegProgress?,
                                           isVehicleActive: Bool,
                                           activeRoute: Route?) -> [TableCellSpec] {
        var specs = [TableCellSpec]()

        guard let validActiveRoute = activeRoute else {
            return specs
        }

        if let nextInstructionProgress = legProgress?.nextInstructionProgress {
            let instruction = nextInstructionProgress.instruction
            let distance = nextInstructionProgress.distanceUntilInstruction
            let duration = nextInstructionProgress.durationUntilInstruction

            let instructionText = attributedText(from: instruction,
                                                 distance: distance,
                                                 duration: duration)

            specs.append(BasicTableViewCellSpec(numberOfLines: 0,
                                                attributedText: instructionText,
                                                backgroundColor: .white))
        }

        if let subsequentInstructions = legProgress?.remainingInstructionsAfterNext {
            let subsequentInstructionSpecs = subsequentInstructions.map { instructionSegment -> TableCellSpec in
                let instruction = instructionSegment.endInstruction
                let distance = instructionSegment.distance
                let duration = instructionSegment.duration

                let instructionText = self.attributedText(from: instruction,
                                                          distance: distance,
                                                          duration: duration)
                return BasicTableViewCellSpec(numberOfLines: 0,
                                              attributedText: instructionText,
                                              backgroundColor: .white)
            }

            specs.append(contentsOf: subsequentInstructionSpecs)
        }

        let routeContainsHiredLeg = validActiveRoute.legs.contains { (leg) -> Bool in
            leg.type == .hiredVehicle
        }

        if routeContainsHiredLeg {
            let vehicleLockButtonText: String

            if isVehicleActive {
                vehicleLockButtonText = NSLocalizedString("Lock_Button_Title", comment: "Lock button title")
            } else {
                vehicleLockButtonText = NSLocalizedString("Unlock_Button_Title", comment: "Unlock button title")
            }

            let buttonSpec = unlockLockButtonSpec(title: vehicleLockButtonText) { [weak self] in
                self?.vehicleActivityToggled()
            }
            specs.append(buttonSpec)
        }

        return specs
    }

    private func unlockLockButtonSpec(title: String,
                                      action: @escaping () -> Void) -> VehicleLockStateButtonCellSpec {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.left

        let boldTextAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .bold),
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ]

        let buttonText = NSAttributedString(string: title,
                                            attributes: boldTextAttributes)

        return VehicleLockStateButtonCellSpec(type: .vehicleLockStateButton,
                                              contentInsets: UIEdgeInsets(top: 15,
                                                                          left: 15,
                                                                          bottom: 15,
                                                                          right: 15),
                                              attributedText: buttonText,
                                              backgroundColor: .systemGreen,
                                              borderWidth: 0,
                                              borderColor: .clear,
                                              action: action)
    }
}
