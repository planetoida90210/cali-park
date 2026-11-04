#if DEBUG
import Foundation

// MARK: - InMemoryParkDirectory
/// Fixed Parks for tests and previews; `error` makes `catalog()` throw.
nonisolated struct InMemoryParkDirectory: ParkDirectory {
    var parks: [Park]
    var dataTimestamp: Date?
    var error: ParkDirectoryError?

    init(parks: [Park] = [], dataTimestamp: Date? = nil, error: ParkDirectoryError? = nil) {
        self.parks = parks
        self.dataTimestamp = dataTimestamp
        self.error = error
    }

    func catalog() async throws -> ParkCatalog {
        if let error { throw error }
        return ParkCatalog(parks: parks.filter { $0.status == .published }, dataTimestamp: dataTimestamp)
    }
}
#endif
