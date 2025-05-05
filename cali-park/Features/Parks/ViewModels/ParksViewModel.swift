import Foundation
import Combine
import CoreLocation

// MARK: - ParksViewModel
@MainActor
final class ParksViewModel: ObservableObject {
    // MARK: Published Properties
    @Published private(set) var parks: [Park] = []
    @Published var searchText: String = "" {
        didSet { applyFilters() }
    }
    @Published var selectedTab: Tab = .nearest {
        didSet { applyFilters() }
    }

    // Computed list after filter & sort
    @Published private(set) var displayedParks: [Park] = []

    // User location (mock for now)
    private var userLocation: CLLocation = .init(latitude: 52.2297, longitude: 21.0122)

    // Subscriptions
    private var cancellables = Set<AnyCancellable>()

    // MARK: Initialization
    init() {
        loadParks()
    }

    // MARK: Public
    func refresh() {
        loadParks()
    }

    // Toggle favorite status for a given park
    func toggleFavorite(for park: Park) {
        guard let index = parks.firstIndex(where: { $0.id == park.id }) else { return }
        parks[index].isFavorite.toggle()
        applyFilters()
    }

    // MARK: Private Helpers
    private func loadParks() {
        // Replace with networking later
        parks = Park.mock
        computeDistances()
        applyFilters()
    }

    private func computeDistances() {
        parks = parks.map { park in
            var copy = park
            let parkLocation = CLLocation(latitude: park.coordinate.latitude, longitude: park.coordinate.longitude)
            copy.distance = userLocation.distance(from: parkLocation) / 1000 // km
            return copy
        }
    }

    private func applyFilters() {
        var list = parks

        // Search filter
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let term = searchText.lowercased()
            list = list.filter { $0.name.lowercased().contains(term) || $0.city.lowercased().contains(term) }
        }

        // Tab filter / sort
        switch selectedTab {
        case .nearest:
            list = list.sorted { ($0.distance ?? .greatestFiniteMagnitude) < ($1.distance ?? .greatestFiniteMagnitude) }
        case .popular:
            list = list.sorted { $0.rating > $1.rating }
        case .favorites:
            list = list.filter { $0.isFavorite }
        }

        displayedParks = list
    }

    // MARK: Tab Enum
    enum Tab: String, CaseIterable, Identifiable {
        var id: String { rawValue }
        case nearest = "Najbliżej"
        case popular = "Popularne"
        case favorites = "Ulubione"
    }
} 