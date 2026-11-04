import CoreLocation
import Observation

// MARK: - NearestParkViewModel
/// The Home module "Najbliższy Park": the closest real Park from the directory.
/// Uses the position only when the user has already allowed it; it never shows
/// the location prompt (that belongs to the first map open).
@MainActor
@Observable
final class NearestParkViewModel {
    private static let logger = AppLog.logger(category: "Parks")

    enum State: Equatable {
        case loading
        case nearest(ParkDistance)
        /// No permission yet, denied, or no fix: invite to the map instead.
        case needsLocation
        case noParks
        case failed(String)
    }

    private(set) var state: State = .loading

    private let directory: ParkDirectory
    private let location: LocationProviding

    init(directory: ParkDirectory, location: LocationProviding) {
        self.directory = directory
        self.location = location
    }

    func refresh() async {
        let parks: [Park]
        do {
            parks = try await directory.catalog().parks
        } catch {
            Self.logger.fault("Cannot load the Park snapshot: \(String(describing: error), privacy: .public)")
            state = .failed(ParkMapViewModel.loadErrorMessage)
            return
        }
        guard !parks.isEmpty else {
            state = .noParks
            return
        }
        guard location.authorization == .authorized,
            let origin = await location.currentLocation(),
            let nearest = ParkSearch.nearest(parks, to: origin)
        else {
            state = .needsLocation
            return
        }
        state = .nearest(nearest)
    }
}
