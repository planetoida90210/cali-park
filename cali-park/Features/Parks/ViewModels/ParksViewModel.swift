import Foundation
import Combine
import CoreLocation

// MARK: - ParksViewModel
@MainActor
final class ParksViewModel: ObservableObject {
    // MARK: Published Properties
    @Published private(set) var parks: [Park] = []
    @Published var searchText: String = "" {
        didSet { filterParks() }
    }
    @Published var selectedTab: Tab = .nearest {
        didSet { sortParks() }
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

    // MARK: Private Helpers
    private func loadParks() {
        // Replace with networking later
        parks = Park.mock
        computeDistances()
        filterParks()
    }

    private func computeDistances() {
        parks = parks.map { park in
            var copy = park
            let parkLocation = CLLocation(latitude: park.coordinate.latitude, longitude: park.coordinate.longitude)
            copy.distance = userLocation.distance(from: parkLocation) / 1000 // km
            return copy
        }
    }

    private func filterParks() {
        let filtered: [Park]
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filtered = parks
        } else {
            let term = searchText.lowercased()
            filtered = parks.filter { $0.name.lowercased().contains(term) || $0.city.lowercased().contains(term) }
        }
        displayedParks = sort(filtered)
    }

    private func sortParks() {
        displayedParks = sort(displayedParks)
    }

    private func sort(_ list: [Park]) -> [Park] {
        switch selectedTab {
        case .nearest:
            return list.sorted { ($0.distance ?? .greatestFiniteMagnitude) < ($1.distance ?? .greatestFiniteMagnitude) }
        case .popular:
            return list.sorted { $0.rating > $1.rating }
        case .favorites:
            return list.filter { $0.isFavorite }
        }
    }

    // MARK: Tab Enum
    enum Tab: String, CaseIterable, Identifiable {
        var id: String { rawValue }
        case nearest = "Najbliżej"
        case popular = "Popularne"
        case favorites = "Ulubione"
    }
} 