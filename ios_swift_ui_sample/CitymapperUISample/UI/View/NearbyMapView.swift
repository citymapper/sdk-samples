//
//  NearbyMapView.swift
//  CitymapperUISample
//
//  Created by Iuliia Ponomareva on 24/11/2022.
//

@_spi(CMExperimentalNearby) import CitymapperUI
import Foundation
import SwiftUI
import UIKit

struct NearbyMapView: UIViewControllerRepresentable {
    
    let nearbyViewModel: NearbyViewModel
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let nearbyCardsVC = NearbyCardsViewController(nearbyViewModel: nearbyViewModel)
        let nearbyMapVC = NearbyMapViewController(nearbyViewModel: nearbyViewModel,
                                                  childControllersToAdd:[
                                                    (nearbyCardsVC, UIEdgeInsets(top: 0, left: 12, bottom: 0, right: -12))
                                                    ]
        )
        return nearbyMapVC
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }
}

extension NearbyCardsViewController {

}
