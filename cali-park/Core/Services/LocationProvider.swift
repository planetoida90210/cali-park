import CoreLocation
import Foundation

// MARK: - LocationAuthorization
nonisolated enum LocationAuthorization: Sendable, Equatable {
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

// MARK: - LocationManaging
/// The part of `CLLocationManager` that `CoreLocationProvider` uses, so tests
/// can drive authorization answers, fixes and silence without Core Location.
/// Callbacks arrive on the main actor.
@MainActor
protocol LocationManaging: AnyObject {
    var authorizationStatus: CLAuthorizationStatus { get }
    /// Called whenever the authorization status changes, including once
    /// shortly after creation.
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)? { get set }
    /// Called with a fix after `requestLocation()`, or `nil` when it failed.
    var onLocation: ((CLLocationCoordinate2D?) -> Void)? { get set }

    func requestWhenInUseAuthorization()
    func requestLocation()
}

// MARK: - SystemLocationManager
/// `LocationManaging` on a real `CLLocationManager`. Create it on the main
/// thread: the manager then calls its delegate on the main run loop.
final class SystemLocationManager: NSObject, LocationManaging {
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?
    var onLocation: ((CLLocationCoordinate2D?) -> Void)?

    private let manager = CLLocationManager()
    private nonisolated static let log = AppLog.logger(category: "Location")

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var authorizationStatus: CLAuthorizationStatus { manager.authorizationStatus }

    func requestWhenInUseAuthorization() { manager.requestWhenInUseAuthorization() }

    func requestLocation() { manager.requestLocation() }
}

extension SystemLocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        MainActor.assumeIsolated { onAuthorizationChange?(status) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinate = locations.last?.coordinate
        MainActor.assumeIsolated { onLocation?(coordinate) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Self.log.error("Location request failed: \(error.localizedDescription, privacy: .public)")
        MainActor.assumeIsolated { onLocation?(nil) }
    }
}

// MARK: - CoreLocationProvider
/// `LocationProviding` over a `LocationManaging` (Core Location in the app).
/// Callers waiting for the same answer share one prompt or one location
/// request; a request that gets no answer ends with `nil` after a timeout.
@MainActor
@Observable
final class CoreLocationProvider: LocationProviding {
    private(set) var authorization: LocationAuthorization = .notDetermined

    @ObservationIgnored private let manager: LocationManaging
    @ObservationIgnored private let clock: () -> Date
    @ObservationIgnored private var authorizationWaiters: [CheckedContinuation<LocationAuthorization, Never>] = []
    @ObservationIgnored private var locationWaiters: [CheckedContinuation<CLLocationCoordinate2D?, Never>] = []

    private nonisolated static let log = AppLog.logger(category: "Location")

    /// A fix received less than this ago is good enough for "how far is the
    /// Park".
    static let maximumFixAge: TimeInterval = 300
    /// `requestLocation()` can take a while (or never answer); give up then.
    @ObservationIgnored private let requestTimeout: Duration
    @ObservationIgnored private var lastFix: (coordinate: CLLocationCoordinate2D, receivedAt: Date)?
    /// Bumped per `requestLocation()`, so a stale timeout can't end a newer request.
    @ObservationIgnored private var requestGeneration = 0

    init(manager: LocationManaging,
         clock: @escaping () -> Date,
         requestTimeout: Duration = .seconds(10)) {
        self.manager = manager
        self.clock = clock
        self.requestTimeout = requestTimeout
        authorization = Self.authorization(from: manager.authorizationStatus)
        manager.onAuthorizationChange = { [weak self] status in self?.authorizationDidChange(to: status) }
        manager.onLocation = { [weak self] coordinate in self?.finishLocationRequest(with: coordinate) }
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
        if let lastFix, clock().timeIntervalSince(lastFix.receivedAt) < Self.maximumFixAge {
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
            do {
                try await Task.sleep(for: requestTimeout)
            } catch {
                return
            }
            guard let self, self.requestGeneration == generation, !self.locationWaiters.isEmpty else { return }
            Self.log.notice("Location request timed out")
            self.finishLocationRequest(with: nil)
        }
    }

    private func finishLocationRequest(with coordinate: CLLocationCoordinate2D?) {
        if let coordinate {
            lastFix = (coordinate, clock())
        }
        requestGeneration += 1
        let waiters = locationWaiters
        locationWaiters = []
        waiters.forEach { $0.resume(returning: coordinate) }
    }
}
