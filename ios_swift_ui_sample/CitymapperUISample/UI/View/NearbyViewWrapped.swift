//
//  NearbyViewWrapped.swift
//  CitymapperUISample
//
//  Created by Iuliia Ponomareva on 24/11/2022.
//

@_spi(CMExperimentalNearby) import CitymapperUI
import Foundation
import SwiftUI


struct NearbyViewWrapped: View {
    
    let nearbyViewModel = NearbyViewModel()
    
    var body: some View {
        NearbyMapView(nearbyViewModel: nearbyViewModel)
                .navigationBarTitle("Nearby", displayMode: .inline)
                .ignoresSafeArea(.all, edges: .bottom)
    }
}


