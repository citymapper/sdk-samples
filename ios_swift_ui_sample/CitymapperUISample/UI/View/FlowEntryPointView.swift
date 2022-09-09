//
//  ContentView.swift
//  CitymapperUISample
//
//  Created by Iuliia Ponomareva on 01/09/2022.
//

import SwiftUI

struct FlowEntryPointView: View {
    @ObservedObject var viewModel: FlowEntryPointViewModel = .init()
    
    var body: some View {
        NavigationView {
            VStack {
                Button("Get me somewhere") {
                    self.viewModel.isShowingDetailView.toggle()
                }
                .padding()
                .background(Color(red: 55/255, green: 171/255, blue: 47/255))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .foregroundColor(.white)
                
                NavigationLink(
                    destination: SearchViewWrapped(routesLoader: DefaultRoutesLoader()),
                    isActive: $viewModel.isShowingDetailView
                ) { }
            }
            .navigationTitle("Get me somewhere")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
