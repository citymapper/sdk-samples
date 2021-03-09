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
    private var instructionsCancellable: AnyCancellable?
    private var latestErrorCancellable: AnyCancellable?
    private var centerMapOnLocationUpdatesCancellable: AnyCancellable?
    private var showMapResetButtonCancellable: AnyCancellable?
    private var showEndActiveNavigationButtonCancellable: AnyCancellable?
    private var latestGuidanceEventCancellable: AnyCancellable?

    private lazy var speaker: Speaker = SpeakerConcrete()

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
        let button = UIButton(primaryAction: UIAction { [weak self] (_) in
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
        let button = UIButton(primaryAction: UIAction { [weak self] (_) in
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
        let button = UIButton(primaryAction: UIAction { [weak self] (_) in
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
        return tableView
    }()

    private let instructionsTableDataSource = InstructionsTableDataSource()
    private let instructionsTableDelegate = InstructionsTableDelegate()

    init(viewModel: MapListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .white
        self.view.addSubview(self.mapView)
        self.view.addSubview(self.profileSwitcher)
        self.view.addSubview(self.resetMapButton)
        self.view.addSubview(self.endActiveNavigationButton)
        self.view.addSubview(self.shareLogsButton)
        self.view.addSubview(self.instructionsTableView)

        self.subscribeToViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if self.viewModel.shouldShowLocationPermissionScreen() {
            self.present(self.viewModel.locationPermissionScreen(),
                         animated: true,
                         completion: nil)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let screenEdgeMargin: CGFloat = 15

        let mapViewHeight = self.view.bounds.height * 0.8
        self.mapView.frame = CGRect(x: 0,
                                    y: 0,
                                    width: self.view.bounds.width,
                                    height: mapViewHeight)

        let xOriginSmallButtons = self.view.bounds.width - (MapListViewController.smallCircularButtonSize.width + screenEdgeMargin)
        var yOriginSmallButtons = mapViewHeight - (screenEdgeMargin + screenEdgeMargin + MapListViewController.smallCircularButtonSize.height)

        self.profileSwitcher.frame = CGRect(x: 15,
                                            y: view.safeAreaInsets.top + 15,
                                            width: self.view.bounds.width - 30,
                                            height: 30)

        self.shareLogsButton.frame = CGRect(x: xOriginSmallButtons,
                                            y: yOriginSmallButtons,
                                            width: Self.smallCircularButtonSize.width,
                                            height: Self.smallCircularButtonSize.height)
        yOriginSmallButtons = self.shareLogsButton.frame.minY - (screenEdgeMargin + Self.smallCircularButtonSize.height)

        if !self.endActiveNavigationButton.isHidden {
            self.endActiveNavigationButton.frame = CGRect(x: xOriginSmallButtons,
                                                y: yOriginSmallButtons,
                                                width: Self.smallCircularButtonSize.width,
                                                height: Self.smallCircularButtonSize.height)
            yOriginSmallButtons = self.endActiveNavigationButton.frame.minY - (screenEdgeMargin + Self.smallCircularButtonSize.height)
        }

        if !self.resetMapButton.isHidden {
            self.resetMapButton.frame = CGRect(x: xOriginSmallButtons,
                                               y: yOriginSmallButtons,
                                               width: MapListViewController.smallCircularButtonSize.width,
                                               height: MapListViewController.smallCircularButtonSize.height)
        }

        let tableHeight = self.view.bounds.height - mapViewHeight
        self.instructionsTableView.frame = CGRect(x: 0,
                                                  y: self.mapView.frame.maxY,
                                                  width: self.view.bounds.width,
                                                  height: tableHeight)
    }

    private func subscribeToViewModel() {
        self.mapTapStateCancellable = self.viewModel.$currentMapTapState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mapTapState in
                self?.updateMapForTapState(mapTapState)
            }

        self.primaryRouteDisplayingCancellable = self.viewModel.$routeMapPathGeometry
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pathSegments in
                self?.updateMapWithPrimaryRoute(pathSegments)
            }

        self.latestLocationCancellable = self.viewModel.$latestLocation
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

        self.instructionsCancellable = self.viewModel.$legProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] legProgress in
                self?.instructionsTableDataSource.nextInstructionProgress = legProgress?.nextInstructionProgress
                self?.instructionsTableDataSource.subsequentInstructions = legProgress?.remainingInstructionsAfterNext ?? []
                self?.instructionsTableView.reloadSections(IndexSet(arrayLiteral: 0),
                                                           with: .automatic)
            }

        self.latestGuidanceEventCancellable = self.viewModel.$guidanceEvent
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newGuidanceEvent in
                guard let guidanceEvent = newGuidanceEvent else { return }

                let spokenMessage = guidanceEvent.createSpeechText()
                _ = self?.speaker.speak(spokenMessage)
            }

        self.latestErrorCancellable = self.viewModel.$latestError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] latestError in

                guard let validError = latestError as NSError? else { return }

                let alert = UIAlertController(title: "Error",
                                              message: validError.localizedDescription,
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }

        self.centerMapOnLocationUpdatesCancellable = self.viewModel.$centerMapOnLocationUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] centerMapOnLocationUpdates in
                if centerMapOnLocationUpdates,
                   let validLatestLocation = self?.viewModel.latestLocation {
                    self?.mapView.setCenter(validLatestLocation.coordinate,
                                            animated: true)
                }
            }

        self.showMapResetButtonCancellable = self.viewModel.$showMapResetButton
            .receive(on: DispatchQueue.main)
            .sink { [weak self] showMapResetButton in
                self?.resetMapButton.isHidden = !showMapResetButton
                self?.view.setNeedsLayout()
            }

        self.showEndActiveNavigationButtonCancellable = self.viewModel.$showEndActiveNavigationButton
            .receive(on: DispatchQueue.main)
            .sink { [weak self] showEndActiveNavigationButton in
                self?.endActiveNavigationButton.isHidden = !showEndActiveNavigationButton
                self?.view.setNeedsLayout()
        }
    }

    private func updateMapWithPrimaryRoute(_ pathSegments: [PathGeometrySegment]?) {
        self.mapView.removeOverlays(self.mapView.overlays)

        guard let validPathSegments = pathSegments else {
            return
        }

        for segment in validPathSegments {
            let coordinates = segment.geometry.asCLLocationCoordinate2DArray()
            let polyline = PathGeometryPolyline(coordinates: coordinates, count: coordinates.count)
            polyline.isPast = segment.pastOrFuture == PathGeometrySegment.PastOrFuture.past
            polyline.travelMode = segment.travelMode
            self.mapView.addOverlay(polyline)
        }
    }

    private func updateMapForTapState(_ mapTapState: MapListViewModel.MapTapState) {
        self.mapView.removeAnnotations(self.mapView.annotations)

        switch mapTapState {
        case .unknown:
            break
        case .startAndEnd(let startCoords, let endCoords):
            self.addMapAnnotation(coords: endCoords)
        }
    }

    private func addMapAnnotation(coords: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coords
        self.mapView.addAnnotation(annotation)
    }

    @objc
    private func mapViewTapped(_ sender: UITapGestureRecognizer) {
        guard sender.state == .ended else { return }

        let cgPointTappedOnMapView = sender.location(in: self.mapView)
        let coordinate = self.mapView.convert(cgPointTappedOnMapView,
                                              toCoordinateFrom: self.mapView)

        self.viewModel.didTapMap(at: coordinate)
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
        self.present(shareSheetController,
                     animated: true,
                     completion: nil)
    }

    private func resetMapButtonTapped() {
        self.viewModel.didTapResetMap()
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
        self.viewModel.setCurrentProfile(profile: profile)
        self.viewModel.didTapEndActiveNavigation()
    }

    private func endActiveNavigationButtonTapped() {
        self.viewModel.didTapEndActiveNavigation()
    }
}

class PathGeometryPolyline: MKPolyline {

    var isPast: Bool = false
    var travelMode: PathGeometrySegment.TravelMode? = nil
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
        if self.mapViewRegionDidChangeFromUserInteraction() {
            self.viewModel.userDidInteractWithMap()
        }
    }

    private func mapViewRegionDidChangeFromUserInteraction() -> Bool {
        guard let view = self.mapView.subviews.first,
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

    var nextInstructionProgress: InstructionProgress? = nil
    var subsequentInstructions = [InstructionSegment]()

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (nextInstructionProgress == nil) {
            return 0
        } else {
            return self.subsequentInstructions.count + 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let nextInstructionProgress = nextInstructionProgress,
            self.subsequentInstructions.count + 1 > indexPath.row else {
            return UITableViewCell()
        }

        let instruction: Instruction
        let distance: Distance?
        let duration: Duration?
        if (indexPath.row == 0) {
            instruction = nextInstructionProgress.instruction
            distance = nextInstructionProgress.distanceUntilInstruction
            duration = nextInstructionProgress.durationUntilInstruction
        } else {
            let instructionSegment = self.subsequentInstructions[indexPath.row - 1]
            instruction = instructionSegment.endInstruction
            distance = instructionSegment.distance
            duration = instructionSegment.duration
        }

        let cell = UITableViewCell()
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.attributedText = self.attributedText(from: instruction,
                                                             distance: distance,
                                                             duration: duration)
        cell.backgroundColor = .white
        return cell
    }

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
}

final class InstructionsTableDelegate: NSObject, UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
