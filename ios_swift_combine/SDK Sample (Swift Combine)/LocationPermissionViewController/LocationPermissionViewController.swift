//
//  LocationPermissionViewController.swift
//

import UIKit

import Combine

class LocationPermissionViewController: UIViewController {

    private var viewModel: LocationPermissionViewModel
    private var screenStateCancellable: AnyCancellable?

    private static let kPrimaryButtonAction = "kPrimaryButtonAction"

    private lazy var loadingSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.style = .large
        spinner.hidesWhenStopped = true
        return spinner
    }()

    private lazy var grantLocationPermissionButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.titleLabel?.font = .boldSystemFont(ofSize: 22)
        button.titleLabel?.textColor = .white
        button.backgroundColor = UIColor.systemBlue
        button.layer.cornerRadius = 10
        return button
    }()

    init(viewModel: LocationPermissionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.isModalInPresentation = true

        self.view.backgroundColor = .white
        self.view.addSubview(self.loadingSpinner)
        self.view.addSubview(self.grantLocationPermissionButton)

        self.subscribeToViewModel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !self.grantLocationPermissionButton.isHidden {
            let horizontalMargin: CGFloat = 15
            let buttonWidth = self.view.bounds.width - (horizontalMargin + horizontalMargin)
            let buttonHeight = self.grantLocationPermissionButton
                                    .sizeThatFits(CGSize(width: buttonWidth,
                                                         height: .greatestFiniteMagnitude)).height

            self.grantLocationPermissionButton.frame.size = CGSize(width: buttonWidth,
                                                                   height: buttonHeight)
            self.grantLocationPermissionButton.center = CGPoint(x: self.view.bounds.midX,
                                                                y: self.view.bounds.midY)
        }

        self.loadingSpinner.center = CGPoint(x: self.view.bounds.midX,
                                             y: self.view.bounds.midY)
    }

    private func showLoading(_ loadingVisible: Bool) {
        if loadingVisible {
            self.grantLocationPermissionButton.isHidden = true
            self.loadingSpinner.startAnimating()
        } else {
            self.loadingSpinner.stopAnimating()
            self.grantLocationPermissionButton.isHidden = false
        }
    }

    private func subscribeToViewModel() {
        self.screenStateCancellable = self.viewModel.$currentLocationPermissionScreenState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] screenState in

            guard let strongSelf = self else { return }
                
            strongSelf.grantLocationPermissionButton.removeTarget(nil, action: nil, for: .allEvents)

            switch screenState {
            case .loading:
                strongSelf.showLoading(true)
            case .needsLocationPermission(canRequestInApp: let canRequestInApp, buttonTitle: let buttonTitle):
                strongSelf.showLoading(false)
                strongSelf.grantLocationPermissionButton.setTitle(buttonTitle, for: .normal)
                
                let buttonAction: UIAction
                
                if canRequestInApp {
                    buttonAction = strongSelf.primaryButtonAction(with: { [weak self] (_) in
                        self?.enableLocationInAppTapped()
                    })
                } else {
                    buttonAction = strongSelf.primaryButtonAction(with: { [weak self] (_) in
                        self?.enableLocationInSettingsTapped()
                    })
                }
                
                strongSelf.grantLocationPermissionButton.addAction(buttonAction,
                                                                   for: .touchUpInside)
            case .locationGrantedAndTracking(buttonTitle: let buttonTitle):
                strongSelf.showLoading(false)
                strongSelf.grantLocationPermissionButton.setTitle(buttonTitle, for: .normal)

                let buttonAction = strongSelf.primaryButtonAction { [weak self] (_) in
                    self?.dismissScreen()
                }
                strongSelf.grantLocationPermissionButton.addAction(buttonAction,
                                                                   for: .touchUpInside)
            }
        }
    }

    private func primaryButtonAction(with handler: @escaping UIActionHandler) -> UIAction {
        let action = UIAction(title: "Primary Button Action",
                              identifier: UIAction.Identifier(Self.kPrimaryButtonAction),
                              handler: handler)
        return action
    }

    private func enableLocationInAppTapped() {
        self.viewModel.enableLocationInAppTapped()
    }

    private func enableLocationInSettingsTapped() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
        }
    }

    private func dismissScreen() {
        self.dismiss(animated: true, completion: nil)
    }
}
