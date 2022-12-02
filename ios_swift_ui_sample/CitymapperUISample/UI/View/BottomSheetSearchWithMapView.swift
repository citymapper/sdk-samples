//
//  BottomSheetSearchWithMapView.swift
//  CitymapperUISample
//
//  Created by Ben Kay on 02/12/2022.
//

import CitymapperCore
import Foundation
import SwiftUI
import CitymapperNavigation
@_spi(CM) import CitymapperUI

struct BottomSheetSearchWithMapView: View {
    let theme: Theme
    let defaultMapCenter: Coords
    let initialStart: SearchEndpoint?
    let initialEnd: SearchEndpoint?
    let initialTimeConstraint: DepartOrArriveConstraint
    let searchProviderFactory: () -> SearchProvider
    let distanceUnits: DistanceUnits
    let onClose: () -> Void
    let planBuilder: (DirectionsPlan.Builder) -> Void
    let onClickRoute: (Route) -> Void

    public init(
        theme: Theme = BasicTheme(),
        defaultMapCenter: Coords,
        initialStart: SearchEndpoint? = .currentLocation,
        initialEnd: SearchEndpoint? = nil,
        initialTimeConstraint: DepartOrArriveConstraint = .departApproximateNow,
        searchProviderFactory: @escaping () -> SearchProvider,
        distanceUnits: DistanceUnits = DistanceUnits.getDefault(),
        onClose: @escaping () -> Void,
        planBuilder: @escaping (DirectionsPlan.Builder) -> Void,
        onClickRoute: @escaping (Route) -> Void
    ) {
        self.theme = theme
        self.defaultMapCenter = defaultMapCenter
        self.initialStart = initialStart
        self.initialEnd = initialEnd
        self.initialTimeConstraint = initialTimeConstraint
        self.searchProviderFactory = searchProviderFactory
        self.distanceUnits = distanceUnits
        self.onClose = onClose
        self.planBuilder = planBuilder
        self.onClickRoute = onClickRoute
    }

    public var body: some View {
        GeometryReader { geo in
            InternalSheetSearchWithMapView(
                theme: theme,
                defaultMapCenter: defaultMapCenter,
                initialStart: initialStart,
                initialEnd: initialEnd,
                initialTimeConstraint: initialTimeConstraint,
                searchProviderFactory: searchProviderFactory,
                distanceUnits: distanceUnits,
                onClose: onClose,
                planBuilder: planBuilder,
                onClickRoute: onClickRoute
            ).edgesIgnoringSafeArea(.all).frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

@available(iOS 13, *)
struct InternalSheetSearchWithMapView: UIViewControllerRepresentable {
    typealias UIViewControllerType = BottomSheetSearchWithMapViewController

    let theme: Theme
    let defaultMapCenter: Coords
    let initialStart: SearchEndpoint?
    let initialEnd: SearchEndpoint?
    let initialTimeConstraint: DepartOrArriveConstraint
    let searchProviderFactory: () -> SearchProvider
    let distanceUnits: DistanceUnits
    let onClose: () -> Void
    let planBuilder: (DirectionsPlan.Builder) -> Void
    let onClickRoute: (Route) -> Void

    func makeUIViewController(context: Context) -> UIViewControllerType {
        BottomSheetSearchWithMapViewController(
            theme: theme,
            defaultMapCenter: defaultMapCenter,
            initialStart: initialStart,
            initialEnd: initialEnd,
            initialTimeConstraint: initialTimeConstraint,
            searchProviderFactory: searchProviderFactory,
            distanceUnits: distanceUnits,
            topAppBarView: DefaultTopAppBarView(onClose: onClose),
            searchBoxesView: DefaultSearchBoxesView(),
            sheetContentView: DefaultSheetContentView(
                theme: theme,
                planBuilder: planBuilder,
                onClickRoute: onClickRoute
            )
        )
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
