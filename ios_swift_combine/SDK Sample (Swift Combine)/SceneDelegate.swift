//
//  SceneDelegate.swift
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }

        let guidanceFetcher = GuidanceFetcher()
        let locationManager = LocationManager()
        let mapViewModel = MapListViewModel(guidanceFetcher,
                                            locationManager: locationManager)
        let mapViewController = MapListViewController(viewModel: mapViewModel)

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = mapViewController
        window.makeKeyAndVisible()
        self.window = window
    }
}

