import SwiftUI

// MARK: - ParksView
/// The Parks tab (label "Siłownie"): variant A "Wyciszona" map with a list
/// toggle (ticket 011). Read-only Parks from OpenStreetMap.
struct ParksView: View {
    @State private var viewModel: ParkMapViewModel
    @Environment(TabRouter.self) private var router: TabRouter?
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var isSearchFocused: Bool
    /// Height of the compact sheet detent before the card header is measured;
    /// grows with Dynamic Type.
    @ScaledMetric(relativeTo: .body) private var estimatedCompactHeight: CGFloat = 200
    /// The measured card header plus its padding; fits the compact detent to
    /// the header at any text size.
    @State private var measuredCompactHeight: CGFloat?
    @State private var sheetDetent: PresentationDetent = .medium

    init(environment: AppEnvironment) {
        _viewModel = State(initialValue: environment.makeParkMapViewModel())
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        ZStack {
            Color.appBackground.ignoresSafeArea()
            switch viewModel.mode {
            case .map:
                ParkMapContent(viewModel: viewModel)
            case .list:
                ParkListContent(viewModel: viewModel)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            ParkSearchHeader(viewModel: viewModel, isSearchFocused: $isSearchFocused)
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
        // The Park card is a sheet (ticket 023); the map stays usable under the
        // compact detent, so another pin can be tapped right away.
        .sheet(isPresented: sheetBinding) {
            if let park = viewModel.selectedPark {
                ParkSheetView(
                    park: park,
                    distance: viewModel.distance(to: park),
                    dataTimestamp: viewModel.dataTimestamp,
                    isFavorite: viewModel.isFavorite(park),
                    isExpanded: sheetDetent == .large,
                    onHeaderHeightChange: updateCompactHeight,
                    onToggleFavorite: { viewModel.toggleFavorite(park) },
                    onExpand: { withAnimation(.smooth) { sheetDetent = .large } },
                    onClose: { viewModel.clearSelection() }
                )
                .presentationDetents([compactDetent, .large], selection: $sheetDetent)
                .presentationBackgroundInteraction(.enabled(upThrough: compactDetent))
                .presentationContentInteraction(.resizes)
                .presentationDragIndicator(.visible)
                .errorAlert($viewModel.favoritesMessage)
            }
        }
        .onChange(of: viewModel.selectedParkID == nil) {
            // A newly opened card always starts compact, with the map usable.
            sheetDetent = compactDetent
        }
        .task {
            await viewModel.start()
            consumeFocusRequest()
        }
        .onChange(of: router?.parkToFocus) {
            consumeFocusRequest()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await viewModel.refreshLocation() }
            }
        }
        .messageAlert($viewModel.errorMessage) {
            Button("Spróbuj ponownie") {
                Task { await viewModel.load() }
            }
            Button("Zamknij", role: .cancel) {}
        }
    }

    // MARK: Helpers

    private var compactDetent: PresentationDetent {
        .height(measuredCompactHeight ?? estimatedCompactHeight)
    }

    private func updateCompactHeight(headerHeight: CGFloat) {
        let height = (headerHeight + ParkSheetView.headerTopPadding + ParkSheetView.headerBottomPadding).rounded(.up)
        guard abs(height - (measuredCompactHeight ?? 0)) >= 1 else { return }
        let wasCompact = sheetDetent != .large
        measuredCompactHeight = height
        if wasCompact { sheetDetent = compactDetent }
    }

    private func consumeFocusRequest() {
        guard let router, let id = router.parkToFocus else { return }
        router.parkToFocus = nil
        viewModel.focus(on: id)
    }

    private var sheetBinding: Binding<Bool> {
        Binding(
            get: { viewModel.selectedParkID != nil },
            set: { if !$0 { viewModel.clearSelection() } }
        )
    }
}

#if DEBUG
// MARK: - Preview
#Preview {
    NavigationStack {
        ParksView(environment: .seeded())
    }
    .preferredColorScheme(.dark)
}
#endif
