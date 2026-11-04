import MapKit
import SwiftUI

// MARK: - ParksView
/// The Parks tab (label "Siłownie"): variant A "Wyciszona" map with a list
/// toggle (ticket 011). Read-only Parks from OpenStreetMap.
struct ParksView: View {
    @State private var viewModel: ParkMapViewModel
    @Environment(TabRouter.self) private var router: TabRouter?
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var isSearchFocused: Bool
    /// Height of the compact sheet detent; grows with Dynamic Type.
    @ScaledMetric(relativeTo: .body) private var compactSheetHeight: CGFloat = 250

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
            header
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
        // The Park card is a sheet (ticket 023); the map stays usable under the
        // compact detent, so another pin can be tapped right away.
        .sheet(isPresented: sheetBinding) {
            if let park = viewModel.selectedPark {
                ParkSheetView(park: park,
                              distance: viewModel.distance(to: park),
                              dataTimestamp: viewModel.dataTimestamp) {
                    viewModel.clearSelection()
                }
                .presentationDetents([.height(compactSheetHeight), .large])
                .presentationBackgroundInteraction(.enabled(upThrough: .height(compactSheetHeight)))
                .presentationDragIndicator(.visible)
            }
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
        .alert(viewModel.errorMessage ?? "", isPresented: errorBinding) {
            Button("Spróbuj ponownie") {
                Task { await viewModel.load() }
            }
            Button("Zamknij", role: .cancel) {}
        }
    }

    // MARK: Header

    private var header: some View {
        @Bindable var viewModel = viewModel
        return VStack(spacing: 8) {
            HStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.textSecondary)
                        .accessibilityHidden(true)
                    TextField("Szukaj Parku lub miasta", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .foregroundStyle(Color.textPrimary)
                        .focused($isSearchFocused)
                        .submitLabel(.search)
                        .autocorrectionDisabled()
                        .onSubmit {
                            if viewModel.mode == .map { viewModel.submitSearch() }
                        }
                    if !viewModel.searchText.isEmpty {
                        Button("Wyczyść", systemImage: "xmark.circle.fill") {
                            viewModel.searchText = ""
                        }
                        .labelStyle(.iconOnly)
                        .foregroundStyle(Color.textSecondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .parkGlass(in: .capsule)

                Button {
                    isSearchFocused = false
                    withAnimation(.smooth) { viewModel.toggleMode() }
                } label: {
                    Image(systemName: viewModel.mode == .map ? "list.bullet" : "map")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.accent)
                        .frame(width: 46, height: 46)
                        .parkGlass(in: .circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(viewModel.mode == .map ? "Pokaż listę" : "Pokaż mapę")
            }

            if viewModel.mode == .map && isSearchFocused && viewModel.isSearching {
                suggestions
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var suggestions: some View {
        VStack(spacing: 0) {
            if viewModel.searchSuggestions.isEmpty {
                Text("Brak Parków dla „\(viewModel.searchText)”")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
            ForEach(viewModel.searchSuggestions) { item in
                Button {
                    isSearchFocused = false
                    viewModel.focus(on: item.park.id)
                } label: {
                    ParkRow(item: item)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                if item.id != viewModel.searchSuggestions.last?.id {
                    Divider().overlay(Color.divider)
                }
            }
        }
        .parkGlass(in: .rect(cornerRadius: 20))
    }

    // MARK: Helpers

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

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}

// MARK: - ParkMapContent
private struct ParkMapContent: View {
    @Bindable var viewModel: ParkMapViewModel

    var body: some View {
        Map(position: $viewModel.position) {
            if viewModel.authorization == .authorized {
                UserAnnotation()
            }
            ForEach(viewModel.clusters) { cluster in
                if cluster.isSingle, let park = cluster.parks.first {
                    Annotation(park.displayName, coordinate: park.coordinate, anchor: .bottom) {
                        Button {
                            withAnimation(.smooth) { viewModel.select(park) }
                        } label: {
                            ParkPin(equipment: park.headlineEquipment, isSelected: park.id == viewModel.selectedParkID)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(park.displayName)
                    }
                    .annotationTitles(.hidden)
                } else {
                    Annotation(ParkFormat.parkCount(cluster.parks.count), coordinate: cluster.coordinate, anchor: .center) {
                        Button {
                            withAnimation(.smooth) { viewModel.zoom(into: cluster) }
                        } label: {
                            ParkClusterBubble(count: cluster.parks.count)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(ParkFormat.parkCount(cluster.parks.count))
                        .accessibilityHint("Przybliża mapę")
                    }
                    .annotationTitles(.hidden)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
        .mapControls {
            if viewModel.authorization == .authorized {
                MapUserLocationButton()
            }
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            viewModel.cameraDidChange(to: context.region)
        }
        .overlay(alignment: .bottomTrailing) {
            OSMAttributionLink()
                .padding(.trailing, 12)
                .padding(.bottom, 8)
        }
    }
}

// MARK: - ParkListContent
/// Variant C list as a toggle: nearest Parks with distance.
private struct ParkListContent: View {
    let viewModel: ParkMapViewModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        let items = viewModel.listItems
        List {
            Section {
                if viewModel.authorization != .authorized {
                    locationPrompt
                }
                ForEach(items) { item in
                    Button {
                        withAnimation(.smooth) { viewModel.focus(on: item.park.id) }
                    } label: {
                        ParkRow(item: item)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Pokazuje Park na mapie")
                    .listRowBackground(Color.componentBackground)
                }
            } header: {
                Text(header(count: items.count))
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    OSMAttributionLink()
                    if let date = viewModel.dataTimestamp {
                        Text(ParkFormat.dataDate(date))
                    }
                }
                .padding(.top, 8)
            }
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .overlay {
            if viewModel.isLoaded && items.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
            }
        }
    }

    private func header(count: Int) -> String {
        if !viewModel.searchText.isEmpty { return "Wyniki: \(ParkFormat.parkCount(count))" }
        return viewModel.userLocation == nil ? ParkFormat.parkCount(count) : "Najbliżej Ciebie"
    }

    @ViewBuilder
    private var locationPrompt: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Odległość do Parków", systemImage: "location")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
            Text("Zezwól CaliPark na lokalizację, a lista ułoży się od najbliższego Parku. Twoja pozycja zostaje w telefonie.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
            if viewModel.authorization == .denied, let url = URL(string: UIApplication.openSettingsURLString) {
                Button("Otwórz Ustawienia") { openURL(url) }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accent)
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.componentBackground)
    }
}

// MARK: - ParkRow
struct ParkRow: View {
    let item: ParkDistance

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.park.headlineEquipment?.symbol ?? "figure.strengthtraining.functional")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.accent)
                .frame(width: 34, height: 34)
                .background(Color.appBackground, in: .circle)
                .overlay(Circle().stroke(Color.accent.opacity(0.6), lineWidth: 1))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.park.displayName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)
                if let locality = item.park.locality.label {
                    Text(locality)
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            if let meters = item.meters {
                Text(ParkFormat.distance(meters))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Color.accent)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ParksView(environment: .seeded())
    }
    .preferredColorScheme(.dark)
}
