import SwiftUI

// MARK: - ParkListContent
/// Variant C list as a toggle: nearest Parks with distance.
struct ParkListContent: View {
    @Bindable var viewModel: ParkMapViewModel

    var body: some View {
        let items = viewModel.listItems
        List {
            Picker("Pokaż", selection: $viewModel.listFilter) {
                ForEach(ParkMapViewModel.ListFilter.allCases, id: \.self) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            Section {
                if viewModel.authorization != .authorized && viewModel.listFilter == .all {
                    ParkListLocationPrompt(authorization: viewModel.authorization)
                }
                ForEach(items) { item in
                    Button {
                        withAnimation(.smooth) { viewModel.focus(on: item.park.id) }
                    } label: {
                        ParkRow(item: item, isFavorite: viewModel.isFavorite(item.park))
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
                ParkListEmptyState(viewModel: viewModel)
            }
        }
    }

    private func header(count: Int) -> String {
        if viewModel.isSearching { return String(localized: "Wyniki: \(ParkFormat.parkCount(count))") }
        if viewModel.listFilter == .favorites { return String(localized: "Ulubione: \(ParkFormat.parkCount(count))") }
        return viewModel.userLocation == nil ? ParkFormat.parkCount(count) : String(localized: "Najbliżej Ciebie")
    }
}
