import SwiftUI

// MARK: - ParkSearchSuggestions
/// Parks matching the search, shown under the search field on the map; a tap
/// focuses the map on the Park.
struct ParkSearchSuggestions: View {
    let viewModel: ParkMapViewModel
    var isSearchFocused: FocusState<Bool>.Binding

    var body: some View {
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
                    isSearchFocused.wrappedValue = false
                    viewModel.focus(on: item.park.id)
                } label: {
                    ParkRow(item: item, isFavorite: viewModel.isFavorite(item.park))
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
        .parkGlass(in: .rect(cornerRadius: AppRadius.large))
    }
}
