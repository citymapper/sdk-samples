//
//  SearchHeaderView.swift
//  CitymapperUISample
//
//  Created by Iuliia Ponomareva on 02/09/2022.
//

import CitymapperUI
import Foundation
import SwiftUI

struct SearchHeaderView: UIViewRepresentable {
    
    class Coordinator: CitymapperSearchHeaderViewDelegate {
        var parent: SearchHeaderView
        
        init(parent: SearchHeaderView) {
            self.parent = parent
        }
        
        func startFieldHasBeenFocused() {
            parent.startHasBeenFocused()
        }
        
        func endFieldHasBeenFocused() {
            parent.endHasBeenFocused()
        }
        
        func didSwapStartAndEnd() {
            parent.didSwapStartAndEnd()
        }
    }
    
    let start: SearchResult
    let end: SearchResult
    
    let didSwapStartAndEnd: () -> Void
    let startHasBeenFocused: () -> Void
    let endHasBeenFocused: () -> Void
    
    func makeUIView(context: Context) -> some UIView {
        let headerView = CitymapperSearchHeaderView(start: start, end: end)
        headerView.delegate = context.coordinator
        return headerView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        guard let view = uiView as? CitymapperSearchHeaderView else { return }
        view.start = start
        view.end = end
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}
