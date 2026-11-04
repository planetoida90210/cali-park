import SwiftUI

// MARK: - ParkSearchHeader
/// The Parks tab's top bar: the search field, the map/list toggle, and the
/// search suggestions while typing on the map.
struct ParkSearchHeader: View {
    @Bindable var viewModel: ParkMapViewModel
    var isSearchFocused: FocusState<Bool>.Binding

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.textSecondary)
                        .accessibilityHidden(true)
                    TextField("Szukaj Parku lub miasta", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .foregroundStyle(Color.textPrimary)
                        .focused(isSearchFocused)
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
                    isSearchFocused.wrappedValue = false
                    withAnimation(.smooth) { viewModel.toggleMode() }
                } label: {
                    Image(systemName: viewModel.mode == .map ? "list.bullet" : "map")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.accent)
                        .scaledIconFrame(46)
                        .parkGlass(in: .circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(viewModel.mode == .map ? "Pokaż listę" : "Pokaż mapę")
            }

            if viewModel.mode == .map && isSearchFocused.wrappedValue && viewModel.isSearching {
                ParkSearchSuggestions(viewModel: viewModel, isSearchFocused: isSearchFocused)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
