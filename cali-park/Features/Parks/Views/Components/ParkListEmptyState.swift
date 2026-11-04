import SwiftUI

// MARK: - ParkListEmptyState
/// Shown over an empty Parks list: unreadable favorites, no favorites yet, or
/// no search results.
struct ParkListEmptyState: View {
    let viewModel: ParkMapViewModel

    var body: some View {
        if viewModel.listFilter == .favorites && viewModel.favoritesUnreadable {
            ContentUnavailableView(
                "Ulubione niedostępne", systemImage: "exclamationmark.triangle",
                description: Text(ParkFavorites.loadFailureMessage))
        } else if viewModel.listFilter == .favorites && !viewModel.isSearching {
            ContentUnavailableView(
                "Brak ulubionych Parków", systemImage: "heart",
                description: Text("Stuknij serce na karcie Parku, a zapiszesz go tutaj."))
        } else {
            ContentUnavailableView.search(text: viewModel.searchText)
        }
    }
}
