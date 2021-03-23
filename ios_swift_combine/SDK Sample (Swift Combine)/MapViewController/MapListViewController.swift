//
//  MapListViewController.swift
//

import Combine
import MapKit
import UIKit

import CitymapperNavigation

final class MapListViewController: UIViewController {
    private static let londonLocation = CLLocation(latitude: 51.509865,
                                                   longitude: -0.118092)
    private static let smallCircularButtonSize = CGSize(width: 50,
                                                        height: 50)

    let viewModel: MapListViewModel

    private var mapTapStateCancellable: AnyCancellable?
    private var primaryRouteDisplayingCancellable: AnyCancellable?
    private var latestLocationCancellable: AnyCancellable?
    private var listSpecsCancellable: AnyCancellable?

    private var latestErrorCancellable: AnyCancellable?
    private var centerMapOnLocationUpdatesCancellable: AnyCancellable?
    private var showMapResetButtonCancellable: AnyCancellable?
    private var showEndActiveNavigationButtonCancellable: AnyCancellable?
    private var latestGuidanceEventCancellable: AnyCancellable?
    private var currentApiCancellable: AnyCancellable?
    private var shouldShowProfileSwitcherCancellable: AnyCancellable?
    private var currentBrandIdCancellable: AnyCancellable?
    private var shouldShowBrandIdButtonCancellable: AnyCancellable?

    private lazy var profileSwitcher: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(frame: .zero)
        segmentedControl.insertSegment(withTitle: Profile.quiet.rawValue,
                                       at: 0,
                                       animated: false)
        segmentedControl.insertSegment(withTitle: Profile.regular.rawValue,
                                       at: 1,
                                       animated: false)
        segmentedControl.insertSegment(withTitle: Profile.fast.rawValue,
                                       at: 2,
                                       animated: false)
        segmentedControl.selectedSegmentIndex = 1
        segmentedControl.addTarget(self,
                                   action: #selector(self.setCurrentProfile),
                                   for: .valueChanged)

        return segmentedControl
    }()

    private lazy var apiSwitcher: UIButton = {
        let button = UIButton(primaryAction: UIAction { [weak self] _ in
            self?.apiSwitcherButtonTapped()
        })
        button.setTitle(UserDefaults.standard.currentSelectedApi,
                        for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 10
        return button
    }()

    private lazy var brandIdButton: UIButton = {
        let button = UIButton(primaryAction: UIAction { [weak self] _ in
            self?.brandIdButtonTapped()
        })
        button.setTitle(UserDefaults.standard.currentHireBrandId ?? "Set brand id",
                        for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 10
        return button
    }()

    private lazy var mapView: MKMapView = {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = self
        mapView.showsUserLocation = true

        let mapCenterLocation = self.viewModel.latestLocation ?? MapListViewController.londonLocation
        let region = MKCoordinateRegion(center: mapCenterLocation.coordinate,
                                        latitudinalMeters: 10000,
                                        longitudinalMeters: 10000)
        mapView.setRegion(region,
                          animated: false)

        let tapGestureRecogniser = UITapGestureRecognizer(target: self, action: #selector(mapViewTapped))
        mapView.addGestureRecognizer(tapGestureRecogniser)

        return mapView
    }()

    private lazy var resetMapButton: UIButton = {
        let button = UIButton(primaryAction: UIAction { [weak self] _ in
            self?.resetMapButtonTapped()
        })
        let resetLocationIcon = UIImage(systemName: "location.fill")
        button.setImage(resetLocationIcon, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = MapListViewController.smallCircularButtonSize.width / 2
        button.isHidden = true
        return button
    }()

    private lazy var endActiveNavigationButton: UIButton = {
        let button = UIButton(primaryAction: UIAction { [weak self] _ in
            self?.endActiveNavigationButtonTapped()
        })
        let shareLogsButton = UIImage(systemName: "multiply.circle")
        button.setImage(shareLogsButton, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = MapListViewController.smallCircularButtonSize.width / 2
        button.isHidden = true
        return button
    }()

    private lazy var shareLogsButton: UIButton = {
        let button = UIButton(primaryAction: UIAction { [weak self] _ in
            self?.shareLogsButtonTapped()
        })
        let shareLogsButton = UIImage(systemName: "square.and.arrow.up")
        button.setImage(shareLogsButton, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = MapListViewController.smallCircularButtonSize.width / 2
        return button
    }()

    private static let kDefaultInstructionRowHeight: CGFloat = 100

    private lazy var instructionsTableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        tableView.dataSource = self.instructionsTableDataSource
        tableView.delegate = self.instructionsTableDelegate
        tableView.rowHeight = MapListViewController.kDefaultInstructionRowHeight
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none

        tableView.register(BasicTableViewCell.self, forCellReuseIdentifier: BasicTableViewCell.kReuseId)
        tableView.register(VehicleLockStateButtonCell.self, forCellReuseIdentifier: VehicleLockStateButtonCell.kReuseId)
        return tableView
    }()

    private let instructionsTableDataSource = InstructionsTableDataSource()
    private let instructionsTableDelegate = InstructionsTableDelegate()

    init(viewModel: MapListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        view.addSubview(mapView)
        view.addSubview(profileSwitcher)
        view.addSubview(apiSwitcher)
        view.addSubview(brandIdButton)
        view.addSubview(resetMapButton)
        view.addSubview(endActiveNavigationButton)
        view.addSubview(shareLogsButton)
        view.addSubview(instructionsTableView)

        subscribeToViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if viewModel.shouldShowLocationPermissionScreen() {
            present(viewModel.locationPermissionScreen(),
                    animated: true,
                    completion: nil)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let screenEdgeMargin: CGFloat = 15

        let mapViewHeight = view.bounds.height * 0.8
        mapView.frame = CGRect(x: 0,
                               y: 0,
                               width: view.bounds.width,
                               height: mapViewHeight)

        layoutApiButtons()

        let xOriginSmallButtons = view.bounds.width - (MapListViewController.smallCircularButtonSize.width + screenEdgeMargin)
        var yOriginSmallButtons = mapViewHeight - (screenEdgeMargin + screenEdgeMargin + MapListViewController.smallCircularButtonSize.height)

        shareLogsButton.frame = CGRect(x: xOriginSmallButtons,
                                       y: yOriginSmallButtons,
                                       width: Self.smallCircularButtonSize.width,
                                       height: Self.smallCircularButtonSize.height)
        yOriginSmallButtons = shareLogsButton.frame.minY - (screenEdgeMargin + Self.smallCircularButtonSize.height)

        if !endActiveNavigationButton.isHidden {
            endActiveNavigationButton.frame = CGRect(x: xOriginSmallButtons,
                                                     y: yOriginSmallButtons,
                                                     width: Self.smallCircularButtonSize.width,
                                                     height: Self.smallCircularButtonSize.height)
            yOriginSmallButtons = endActiveNavigationButton.frame.minY - (screenEdgeMargin + Self.smallCircularButtonSize.height)
        }

        if !resetMapButton.isHidden {
            resetMapButton.frame = CGRect(x: xOriginSmallButtons,
                                          y: yOriginSmallButtons,
                                          width: MapListViewController.smallCircularButtonSize.width,
                                          height: MapListViewController.smallCircularButtonSize.height)
        }

        let tableHeight = view.bounds.height - mapViewHeight
        instructionsTableView.frame = CGRect(x: 0,
                                             y: mapView.frame.maxY,
                                             width: view.bounds.width,
                                             height: tableHeight)
    }

    private func layoutApiButtons() {
        let xOriginApiButtons: CGFloat = 15
        var apiButtonsYOrigin: CGFloat = view.safeAreaInsets.top + 15

        if !profileSwitcher.isHidden {
            profileSwitcher.frame = CGRect(x: xOriginApiButtons,
                                           y: view.safeAreaInsets.top + 15,
                                           width: view.bounds.width - 30,
                                           height: 30)
            apiButtonsYOrigin = profileSwitcher.frame.maxY + 15
        }
        apiSwitcher.frame = CGRect(x: xOriginApiButtons,
                                   y: apiButtonsYOrigin,
                                   width: 220,
                                   height: 30)
        apiButtonsYOrigin = apiSwitcher.frame.maxY + 15

        if !brandIdButton.isHidden {
            brandIdButton.frame = CGRect(x: xOriginApiButtons,
                                         y: apiButtonsYOrigin,
                                         width: 180,
                                         height: 30)
        }
    }

    private func subscribeToViewModel() {
        mapTapStateCancellable = viewModel.$currentMapTapState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mapTapState in
                self?.updateMapForTapState(mapTapState)
            }

        primaryRouteDisplayingCancellable = viewModel.$routeMapPathGeometry
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pathSegments in
                self?.updateMapWithPrimaryRoute(pathSegments)
            }

        latestLocationCancellable = viewModel.$latestLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] latestLocation in
                guard let validLatestLocation = latestLocation,
                      self?.viewModel.centerMapOnLocationUpdates ?? false
                else {
                    return
                }

                self?.mapView.setCenter(validLatestLocation.coordinate,
                                        animated: true)
            }

        listSpecsCancellable = viewModel.$listSpecs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] listSpecs in
                self?.instructionsTableDataSource.specs = listSpecs
                self?.instructionsTableView.reloadSections(IndexSet(arrayLiteral: 0),
                                                           with: .automatic)
            }

        latestGuidanceEventCancellable = viewModel.$guidanceEvent
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newGuidanceEvent in
                guard let guidanceEvent = newGuidanceEvent else { return }

                let spokenMessage = guidanceEvent.createSpeechText()
                _ = self?.viewModel.speaker.speak(spokenMessage)
            }

        latestErrorCancellable = viewModel.$latestError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] possibleError in

                guard let latestError = possibleError else {
                    return
                }

                var errorDescription: String?

                if let guidanceError = latestError as? GuidanceFetcherError {
                    errorDescription = guidanceError.errorDescription
                } else if let validError = latestError as NSError? {
                    errorDescription = validError.localizedDescription
                }

                let alert = UIAlertController(title: "Error",
                                              message: errorDescription,
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }

        centerMapOnLocationUpdatesCancellable = viewModel.$centerMapOnLocationUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] centerMapOnLocationUpdates in
                if centerMapOnLocationUpdates,
                   let validLatestLocation = self?.viewModel.latestLocation {
                    self?.mapView.setCenter(validLatestLocation.coordinate,
                                            animated: true)
                }
            }

        showMapResetButtonCancellable = viewModel.$showMapResetButton
            .receive(on: DispatchQueue.main)
            .sink { [weak self] showMapResetButton in
                self?.resetMapButton.isHidden = !showMapResetButton
                self?.view.setNeedsLayout()
            }

        showEndActiveNavigationButtonCancellable = viewModel.$showEndActiveNavigationButton
            .receive(on: DispatchQueue.main)
            .sink { [weak self] showEndActiveNavigationButton in
                self?.endActiveNavigationButton.isHidden = !showEndActiveNavigationButton
                self?.view.setNeedsLayout()
            }

        currentApiCancellable = viewModel.$currentApi
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentApiString in
                self?.apiSwitcher.setTitle(currentApiString, for: .normal)
                self?.view.setNeedsLayout()
            }

        shouldShowProfileSwitcherCancellable = viewModel.$shouldShowProfileSwitcher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldShowProfileSwitcher in
                self?.profileSwitcher.isHidden = !shouldShowProfileSwitcher
                self?.view.setNeedsLayout()
            }

        currentBrandIdCancellable = viewModel.$currentBrandId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentBrandId in
                self?.brandIdButton.setTitle(currentBrandId ?? "Set brand id", for: .normal)
                self?.view.setNeedsLayout()
            }

        shouldShowBrandIdButtonCancellable = viewModel.$shouldShowBrandIdButton
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldShowBrandIdButton in
                self?.brandIdButton.isHidden = !shouldShowBrandIdButton
                self?.view.setNeedsLayout()
            }
    }

    private func updateMapWithPrimaryRoute(_ pathSegments: [PathGeometrySegment]?) {
        mapView.removeOverlays(mapView.overlays)

        guard let validPathSegments = pathSegments else {
            return
        }

        for segment in validPathSegments {
            let coordinates = segment.geometry.asCLLocationCoordinate2DArray()
            let polyline = PathGeometryPolyline(coordinates: coordinates, count: coordinates.count)
            polyline.isPast = segment.pastOrFuture == PathGeometrySegment.PastOrFuture.past
            polyline.travelMode = segment.travelMode
            mapView.addOverlay(polyline)
        }
    }

    private func updateMapForTapState(_ mapTapState: MapListViewModel.MapTapState) {
        mapView.removeAnnotations(mapView.annotations)

        switch mapTapState {
        case .unknown:
            break
        case let .startAndEnd(startCoords, endCoords):
            addMapAnnotation(coords: endCoords)
        }
    }

    private func addMapAnnotation(coords: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coords
        mapView.addAnnotation(annotation)
    }

    @objc
    private func mapViewTapped(_ sender: UITapGestureRecognizer) {
        guard sender.state == .ended else { return }

        let cgPointTappedOnMapView = sender.location(in: mapView)
        let coordinate = mapView.convert(cgPointTappedOnMapView,
                                         toCoordinateFrom: mapView)

        viewModel.didTapMap(at: coordinate)
    }

    private func shareLogsButtonTapped() {
        let citymapperNav = CitymapperNavigationTracking.shared

        guard citymapperNav.navigationLogExists() else {
#if DEBUG
            NSLog("No logs available")
#endif // DEBUG
            return
        }

        guard let validLogFileUrl = citymapperNav.currentNavigationLogFileUrl() else {
            return
        }

        let shareSheetController = UIActivityViewController(activityItems: [validLogFileUrl],
                                                            applicationActivities: nil)
        present(shareSheetController,
                animated: true,
                completion: nil)
    }

    private func brandIdButtonTapped() {
        let alertTitle = NSLocalizedString("Vehicle_Brand_Id_Alert_Title", comment: "The title of the alert shown when selecting a new vehicle brand id")

        let brandIdController = UIAlertController(title: alertTitle,
                                                  message: nil,
                                                  preferredStyle: .alert)
        brandIdController.addTextField { [weak self] textFieldToBeShown in
            textFieldToBeShown.placeholder = self?.viewModel.currentBrandId
        }

        let okayTitle = NSLocalizedString("Okay_Button_Title", comment: "Okay button")
        let okayAction = UIAlertAction(title: okayTitle,
                                       style: .default) { [weak brandIdController, weak self] _ in
            guard let validBrandIdController = brandIdController,
                  let textField = validBrandIdController.textFields?.first
            else {
                return
            }

            self?.viewModel.didUpdateHireVehicleBrandId(to: textField.text)
        }

        let cancelTitle = NSLocalizedString("Cancel_Button_Title", comment: "Cancel button")
        let cancelAction = UIAlertAction(title: cancelTitle,
                                         style: .cancel) { _ in
        }

        brandIdController.addAction(okayAction)
        brandIdController.addAction(cancelAction)

        present(brandIdController,
                animated: true,
                completion: nil)
    }

    private func apiSwitcherButtonTapped() {
        let apiSwitchScreen = viewModel.apiSelectionScreen()
        present(apiSwitchScreen,
                animated: true,
                completion: nil)
    }

    private func resetMapButtonTapped() {
        viewModel.didTapResetMap()
    }

    @objc
    private func setCurrentProfile(segment: UISegmentedControl) {
        var profile: Profile
        switch segment.selectedSegmentIndex {
        case 0:
            profile = Profile.quiet
        case 1:
            profile = Profile.regular
        case 2:
            profile = Profile.fast
        default:
            profile = Profile.regular
        }
        viewModel.setCurrentProfile(profile: profile)
        viewModel.didTapEndActiveNavigation()
    }

    private func endActiveNavigationButtonTapped() {
        viewModel.didTapEndActiveNavigation()
    }
}

class PathGeometryPolyline: MKPolyline {
    var isPast: Bool = false
    var travelMode: PathGeometrySegment.TravelMode?
}

extension MapListViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let routePolyline = overlay as? MKPolyline {
            let polylineRenderer = MKPolylineRenderer(polyline: routePolyline)
            polylineRenderer.lineWidth = 5
            polylineRenderer.strokeColor = UIColor(red: 0.22, green: 0.67, blue: 0.18, alpha: 1.00)
            if let polylineForLeg = routePolyline as? PathGeometryPolyline {
                polylineRenderer.alpha = CGFloat(polylineForLeg.isPast ? 0.5 : 1)
                if polylineForLeg.travelMode == PathGeometrySegment.TravelMode.walk {
                    polylineRenderer.lineDashPattern = [0, 10]
                }
            }
            return polylineRenderer
        }
        return MKOverlayRenderer()
    }

    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        if mapViewRegionDidChangeFromUserInteraction() {
            viewModel.userDidInteractWithMap()
        }
    }

    private func mapViewRegionDidChangeFromUserInteraction() -> Bool {
        guard let view = mapView.subviews.first,
              let gestureRecognizers = view.gestureRecognizers
        else {
            return false
        }

        for recognizer in gestureRecognizers {
            if (recognizer.state == UIGestureRecognizer.State.began)
                || (recognizer.state == UIGestureRecognizer.State.ended) {
                return true
            }
        }

        return false
    }
}

final class InstructionsTableDataSource: NSObject, UITableViewDataSource {
    var specs = [TableCellSpec]()

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        specs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        TableViewUtils.tableView(tableView,
                                 cellForRowAt: indexPath,
                                 specs: specs)
    }
}

final class InstructionsTableDelegate: NSObject, UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
