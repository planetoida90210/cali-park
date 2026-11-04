import CoreLocation
import Foundation

// MARK: - LocationAuthorization
enum LocationAuthorization: Sendable, Equatable {
    case notDetermined
    /// Denied by the user, or restricted (parental controls, MDM).
    case denied
    case authorized
}

// MARK: - LocationProviding
/// The user's position for distances to Parks. The position stays on the
/// phone: it is never stored or sent anywhere.
@MainActor
protocol LocationProviding: AnyObject {
    /// Observable in the real provider, so views can react when the user
    /// answers the prompt or changes it in Settings.
    var authorization: LocationAuthorization { get }

    /// Shows the when-in-use prompt if the user hasn't answered yet and returns
    /// the answer. Returns the current state right away otherwise.
    func requestAuthorization() async -> LocationAuthorization

    /// One fresh position, or nil when not authorized or no fix is available.
    /// Never prompts.
    func currentLocation() async -> CLLocationCoordinate2D?
}

// MARK: - CoreLocationProvider
/// `LocationProviding` on `CLLocationManager`. Create it on the main thread:
/// the manager then calls its delegate on the main run loop.
@MainActor
@Observable
final class CoreLocationProvider: NSObject, LocationProviding {
    private(set) var authorization: LocationAuthorization = .notDetermined

    @ObservationIgnored private let manager = CLLocationManager()
    @ObservationIgnored private var authorizationWaiters: [CheckedContinuation<LocationAuthorization, Never>] = []
    @ObservationIgnored private var locationWaiters: [CheckedContinuation<CLLocationCoordinate2D?, Never>] = []

    private nonisolated static let log = AppLog.logger(category: "Location")

    /// A fix received less than this ago is good enough for "how far is the
    /// Park".
    @ObservationIgnored private let maximumFixAge: TimeInterval = 300
    /// `requestLocation()` can take a while (or never answer); give up then.
    @ObservationIgnored private let requestTimeout: Duration = .seconds(10)
    @ObservationIgnored private var lastFix: (coordinate: CLLocationCoordinate2D, receivedAt: Date)?
    /// Bumped per `requestLocation()`, so a stale timeout can't end a newer request.
    @ObservationIgnored private var requestGeneration = 0

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorization = Self.authorization(from: manager.authorizationStatus)
    }

    func requestAuthorization() async -> LocationAuthorization {
        guard authorization == .notDetermined else { return authorization }
        return await withCheckedContinuation { continuation in
            authorizationWaiters.append(continuation)
            if authorizationWaiters.count == 1 {
                manager.requestWhenInUseAuthorization()
            }
        }
    }

    func currentLocation() async -> CLLocationCoordinate2D? {
        guard authorization == .authorized else { return nil }
        if let lastFix, -lastFix.receivedAt.timeIntervalSinceNow < maximumFixAge {
            return lastFix.coordinate
        }
        return await withCheckedContinuation { continuation in
            locationWaiters.append(continuation)
            if locationWaiters.count == 1 {
                startLocationRequest()
            }
        }
    }

    // MARK: Private

    static func authorization(from status: CLAuthorizationStatus) -> LocationAuthorization {
        switch status {
        case .notDetermined: .notDetermined
        case .authorizedWhenInUse, .authorizedAlways: .authorized
        case .denied, .restricted: .denied
        @unknown default: .denied
        }
    }

    private func authorizationDidChange(to status: CLAuthorizationStatus) {
        let state = Self.authorization(from: status)
        if authorization != state { authorization = state }
        guard state != .notDetermined else { return }
        let waiters = authorizationWaiters
        authorizationWaiters = []
        waiters.forEach { $0.resume(returning: state) }
    }

    private func startLocationRequest() {
        requestGeneration += 1
        let generation = requestGeneration
        manager.requestLocation()
        Task { [weak self, requestTimeout] in
            try? await Task.sleep(for: requestTimeout)
            guard let self, self.requestGeneration == generation, !self.locationWaiters.isEmpty else { return }
            Self.log.notice("Location request timed out")
            self.finishLocationRequest(with: nil)
        }
    }

    private func finishLocationRequest(with coordinate: CLLocationCoordinate2D?) {
        if let coordinate {
            lastFix = (coordinate, Date())
        }
        requestGeneration += 1
        let waiters = locationWaiters
        locationWaiters = []
        waiters.forEach { $0.resume(returning: coordinate) }
    }
}

// MARK: - CLLocationManagerDelegate
extension CoreLocationProvider: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        MainActor.assumeIsolated { authorizationDidChange(to: status) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinate = locations.last?.coordinate
        MainActor.assumeIsolated { finishLocationRequest(with: coordinate) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Self.log.error("Location request failed: \(error.localizedDescription, privacy: .public)")
        MainActor.assumeIsolated { finishLocationRequest(with: nil) }
    }
}

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
