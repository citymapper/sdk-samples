//
//  SearchView.swift
//  CitymapperUISample
//
//  Created by Iuliia Ponomareva on 02/09/2022.
//

import CitymapperUI
import CitymapperNavigation
import Foundation
import SwiftUI

struct SearchView: UIViewControllerRepresentable {
    
    let searchState: CitymapperSearchViewState

    func makeUIViewController(context: Context) -> some UIViewController {
        return CitymapperSearchViewController(searchViewState: searchState) { _, _, _  in }
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
}
