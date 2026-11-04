import CoreLocation
import Foundation
import Testing
@testable import cali_park

// MARK: - Fake manager

/// A `LocationManaging` the test answers by hand: it records prompts and
/// location requests, and the test sends authorization changes and fixes.
@MainActor
private final class FakeLocationManager: LocationManaging {
    var authorizationStatus: CLAuthorizationStatus
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?
    var onLocation: ((CLLocationCoordinate2D?) -> Void)?
    private(set) var promptCount = 0
    private(set) var locationRequestCount = 0

    init(status: CLAuthorizationStatus) { authorizationStatus = status }

    func requestWhenInUseAuthorization() { promptCount += 1 }
    func requestLocation() { locationRequestCount += 1 }

    /// The user answered the prompt, or changed it in Settings.
    func change(to status: CLAuthorizationStatus) {
        authorizationStatus = status
        onAuthorizationChange?(status)
    }

    func deliver(_ coordinate: CLLocationCoordinate2D?) { onLocation?(coordinate) }
}

private enum LocationFixtures {
    static let warsaw = CLLocationCoordinate2D(latitude: 52.2297, longitude: 21.0122)
    static let krakow = CLLocationCoordinate2D(latitude: 50.0647, longitude: 19.9450)
}

/// Lets queued main-actor tasks run until `condition` holds.
@MainActor
private func waitUntil(_ condition: () -> Bool) async throws {
    for _ in 0..<1_000 where condition() == false {
        await Task.yield()
    }
    try #require(condition())
}

private extension Optional where Wrapped == CLLocationCoordinate2D {
    var latitudeAndLongitude: [Double]? { map { [$0.latitude, $0.longitude] } }
}

// MARK: - Tests

@MainActor
@Suite("CoreLocationProvider over a location manager", .timeLimit(.minutes(1)))
struct CoreLocationProviderTests {
    private func provider(_ manager: FakeLocationManager,
                          clock: @escaping () -> Date = { TestDate.reference },
                          timeout: Duration = .seconds(60)) -> CoreLocationProvider {
        CoreLocationProvider(manager: manager, clock: clock, requestTimeout: timeout)
    }

    // MARK: Authorization

    @Test(arguments: [
        (CLAuthorizationStatus.notDetermined, LocationAuthorization.notDetermined),
        (.authorizedWhenInUse, .authorized),
        (.denied, .denied)
    ])
    func startsFromTheManagersStatus(status: CLAuthorizationStatus, expected: LocationAuthorization) {
        #expect(provider(FakeLocationManager(status: status)).authorization == expected)
    }

    @Test
    func waitingCallersShareOnePromptAndAllGetTheAnswer() async throws {
        let manager = FakeLocationManager(status: .notDetermined)
        let provider = provider(manager)

        let first = Task { await provider.requestAuthorization() }
        let second = Task { await provider.requestAuthorization() }
        try await waitUntil { manager.promptCount == 1 }
        // Core Location reports "not determined" right after creation; that
        // is not an answer.
        manager.change(to: .notDetermined)
        await Task.yield()
        manager.change(to: .authorizedWhenInUse)

        #expect(await first.value == .authorized)
        #expect(await second.value == .authorized)
        #expect(manager.promptCount == 1)
        #expect(provider.authorization == .authorized)
    }

    @Test
    func anAnsweredPromptIsNeverShownAgain() async {
        let manager = FakeLocationManager(status: .denied)
        let provider = provider(manager)

        #expect(await provider.requestAuthorization() == .denied)
        #expect(manager.promptCount == 0)
    }

    @Test
    func aChangeInSettingsUpdatesTheAuthorization() {
        let manager = FakeLocationManager(status: .authorizedWhenInUse)
        let provider = provider(manager)

        manager.change(to: .denied)
        #expect(provider.authorization == .denied)

        manager.change(to: .authorizedAlways)
        #expect(provider.authorization == .authorized)
    }

    // MARK: Location

    @Test
    func withoutPermissionThereIsNoLocationAndNoRequest() async {
        let manager = FakeLocationManager(status: .denied)

        #expect(await provider(manager).currentLocation() == nil)
        #expect(manager.locationRequestCount == 0)
    }

    @Test
    func waitingCallersShareOneRequestAndAllGetTheFix() async throws {
        let manager = FakeLocationManager(status: .authorizedWhenInUse)
        let provider = provider(manager)

        let first = Task { await provider.currentLocation() }
        let second = Task { await provider.currentLocation() }
        try await waitUntil { manager.locationRequestCount == 1 }
        manager.deliver(LocationFixtures.warsaw)

        #expect(await first.value.latitudeAndLongitude == [52.2297, 21.0122])
        #expect(await second.value.latitudeAndLongitude == [52.2297, 21.0122])
        #expect(manager.locationRequestCount == 1)
    }

    @Test
    func aRecentFixIsReusedAndAnOldOneIsRefreshed() async throws {
        let manager = FakeLocationManager(status: .authorizedWhenInUse)
        var now = TestDate.reference
        let provider = provider(manager, clock: { now })

        let first = Task { await provider.currentLocation() }
        try await waitUntil { manager.locationRequestCount == 1 }
        manager.deliver(LocationFixtures.warsaw)
        _ = await first.value

        now += CoreLocationProvider.maximumFixAge - 1
        #expect(await provider.currentLocation().latitudeAndLongitude == [52.2297, 21.0122])
        #expect(manager.locationRequestCount == 1)

        now += 1
        let refreshed = Task { await provider.currentLocation() }
        try await waitUntil { manager.locationRequestCount == 2 }
        manager.deliver(LocationFixtures.krakow)
        #expect(await refreshed.value.latitudeAndLongitude == [50.0647, 19.9450])
    }

    @Test
    func aFailedRequestGivesNilAndTheNextOneAsksAgain() async throws {
        let manager = FakeLocationManager(status: .authorizedWhenInUse)
        let provider = provider(manager)

        let failed = Task { await provider.currentLocation() }
        try await waitUntil { manager.locationRequestCount == 1 }
        manager.deliver(nil)
        #expect(await failed.value == nil)

        let retried = Task { await provider.currentLocation() }
        try await waitUntil { manager.locationRequestCount == 2 }
        manager.deliver(LocationFixtures.warsaw)
        #expect(await retried.value.latitudeAndLongitude == [52.2297, 21.0122])
    }

    @Test
    func aRequestThatNeverAnswersTimesOut() async throws {
        let manager = FakeLocationManager(status: .authorizedWhenInUse)
        let provider = provider(manager, timeout: .milliseconds(20))

        let location = await provider.currentLocation()

        #expect(location == nil)
        #expect(manager.locationRequestCount == 1)
        // A fix that arrives after the timeout resumes nobody twice, and is
        // kept for the next caller.
        manager.deliver(LocationFixtures.warsaw)
        #expect(await provider.currentLocation().latitudeAndLongitude == [52.2297, 21.0122])
        #expect(manager.locationRequestCount == 1)
    }
}
