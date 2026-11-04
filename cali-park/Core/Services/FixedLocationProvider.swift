import CoreLocation
import Foundation

// MARK: - FixedLocationProvider
/// A provider with a fixed answer, for tests and previews. Records how often
/// the prompt was requested.
@MainActor
final class FixedLocationProvider: LocationProviding {
    var authorization: LocationAuthorization
    var location: CLLocationCoordinate2D?
    /// What the user answers when prompted.
    var answer: LocationAuthorization
    private(set) var requestCount = 0

    init(authorization: LocationAuthorization,
         location: CLLocationCoordinate2D? = nil,
         answer: LocationAuthorization = .authorized) {
        self.authorization = authorization
        self.location = location
        self.answer = answer
    }

    func requestAuthorization() async -> LocationAuthorization {
        guard authorization == .notDetermined else { return authorization }
        requestCount += 1
        authorization = answer
        return authorization
    }

    func currentLocation() async -> CLLocationCoordinate2D? {
        authorization == .authorized ? location : nil
    }
}
