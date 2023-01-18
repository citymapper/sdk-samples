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
    
    @State var showAdditionalUI = false
    @State var isShowingGMS = false
    
    var body: some View {
        ZStack(alignment: .bottom)  {
            NearbyMapView(showAdditionalUI: $showAdditionalUI)
                .navigationBarTitle("Nearby", displayMode: .inline)
                .ignoresSafeArea(.all, edges: .bottom)
            if !showAdditionalUI {
                NavigationLink(
                    destination: RouteListView()
                        .navigationBarTitle("", displayMode: .inline)
                        .navigationBarHidden(true),
                    isActive: $isShowingGMS
                ) {

                }
                Button("Get Me Somewhere", action: {
                    self.isShowingGMS = true
                })
                .foregroundColor(.white)
                .padding([.top, .bottom], 10)
                .frame(maxWidth: .infinity)
                .background(.purple)
                .cornerRadius(25)
                .padding([.leading, .trailing], 25)
                .padding(.bottom, 50)
            }
        }
    }
}


