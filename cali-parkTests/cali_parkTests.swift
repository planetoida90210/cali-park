//
//  cali_parkTests.swift
//  cali-parkTests
//
//  Created by Emanuel Delawarski on 04/05/2025.
//

import CoreLocation
import Testing
@testable import cali_park

// MARK: - Test Fixtures

private let idAlpha = UUID(uuidString: "C0000000-0000-4000-8000-000000000001")!
private let idBeta = UUID(uuidString: "C0000000-0000-4000-8000-000000000002")!
private let idGamma = UUID(uuidString: "C0000000-0000-4000-8000-000000000003")!

/// User location coincides with Alpha, so distance ordering is deterministic:
/// Alpha (0 km) < Gamma (~11 km) < Beta (~111 km).
private let testUserLocation = CLLocation(latitude: 52.0, longitude: 21.0)

private func makeTestParks() -> [Park] {
    [
        Park(id: idAlpha, name: "Alpha", city: "Warsaw",
             coordinate: CLLocationCoordinate2D(latitude: 52.0, longitude: 21.0),
             rating: 3.0, description: "", isFavorite: false),
        Park(id: idBeta, name: "Beta", city: "Kraków",
             coordinate: CLLocationCoordinate2D(latitude: 53.0, longitude: 21.0),
             rating: 4.8, description: "", isFavorite: true),
        Park(id: idGamma, name: "Gamma", city: "Warsaw",
             coordinate: CLLocationCoordinate2D(latitude: 52.1, longitude: 21.0),
             rating: 4.0, description: "", isFavorite: false)
    ]
}

@MainActor
private func makeParksViewModel(favorites: Set<UUID>? = nil) -> ParksViewModel {
    ParksViewModel(parks: makeTestParks(),
                   favoritesStore: InMemoryFavoritesStore(initial: favorites),
                   userLocation: testUserLocation)
}

// MARK: - ParksViewModel: filtering, sorting, favorites

@MainActor
struct ParksViewModelTests {
    @Test(arguments: [
        (ParksViewModel.Tab.nearest, [idAlpha, idGamma, idBeta]),
        (ParksViewModel.Tab.popular, [idBeta, idGamma, idAlpha]),
        (ParksViewModel.Tab.favorites, [idBeta])
    ])
    func tabOrdersAndFilters(tab: ParksViewModel.Tab, expected: [UUID]) {
        let vm = makeParksViewModel()
        vm.selectedTab = tab
        #expect(vm.displayedParks.map(\.id) == expected)
    }

    @Test(arguments: [
        ("warsaw", 2), // matches city "Warsaw": Alpha + Gamma
        ("beta", 1),   // matches name "Beta"
        ("kraków", 1),
        ("zzz", 0)
    ])
    func searchFiltersByNameOrCity(query: String, expectedCount: Int) {
        let vm = makeParksViewModel()
        vm.searchText = query
        #expect(vm.displayedParks.count == expectedCount)
    }

    @Test
    func togglingFavoritePersistsAcrossRefresh() throws {
        let store = InMemoryFavoritesStore()
        let vm = ParksViewModel(parks: makeTestParks(),
                                favoritesStore: store,
                                userLocation: testUserLocation)

        let alpha = try #require(vm.parks.first { $0.id == idAlpha })
        #expect(alpha.isFavorite == false)

        vm.toggleFavorite(for: alpha)
        #expect(store.loadFavorites()?.contains(idAlpha) == true)

        // refresh() must NOT wipe favorites anymore.
        vm.refresh()
        let refreshedAlpha = try #require(vm.parks.first { $0.id == idAlpha })
        #expect(refreshedAlpha.isFavorite == true)

        vm.selectedTab = .favorites
        #expect(vm.displayedParks.contains { $0.id == idAlpha })
    }

    @Test
    func seedFavoritesArePersistedOnFirstLaunch() {
        let store = InMemoryFavoritesStore() // nothing persisted yet
        _ = ParksViewModel(parks: makeTestParks(),
                           favoritesStore: store,
                           userLocation: testUserLocation)
        // Beta is favorite in the seed data → becomes the persisted default set.
        #expect(store.loadFavorites() == [idBeta])
    }
}

// MARK: - Stable mock identity & relations

struct MockRelationTests {
    @Test
    func userMockIdentityIsStable() {
        #expect(User.mock.id == User.mock.id)
    }

    @Test(arguments: [Park.mockParkID1, Park.mockParkID2])
    func parkExistsForStableID(parkID: UUID) {
        #expect(Park.mock.contains { $0.id == parkID })
    }

    @Test
    func eventsResolveByStableParkID() {
        let parkID = Park.mockParkID1
        let events = ParkEvent.events(for: parkID)
        #expect(events.isEmpty == false)
        #expect(events.allSatisfy { $0.parkID == parkID })
    }

    @Test
    func reviewMocksResolveByStableParkID() {
        let parkID = Park.mockParkID1
        let reviews = ParkReview.mocks(for: parkID)
        #expect(reviews.isEmpty == false)
        #expect(reviews.allSatisfy { $0.parkID == parkID })
    }
}

// MARK: - ParkReviewsViewModel: error surfacing & cancellation

@MainActor
struct ParkReviewsViewModelTests {
    @Test
    func fetchFailureSurfacesErrorMessage() async {
        let vm = ParkReviewsViewModel(parkID: Park.mockParkID1,
                                      service: FailingReviewsService())
        await vm.load()
        #expect(vm.errorMessage != nil)
        #expect(vm.reviews.isEmpty)
    }

    /// A cancelled (stale) load must not overwrite data from a newer request.
    @Test
    func cancelledLoadDoesNotOverwriteExistingData() async {
        let baseline = [ParkReview(parkID: Park.mockParkID1, userID: UUID(), rating: 4, comment: "baseline")]
        let stale = [ParkReview(parkID: Park.mockParkID1, userID: UUID(), rating: 1, comment: "stale")]
        let service = GatedReviewsService(defaultResult: baseline)

        let vm = ParkReviewsViewModel(parkID: Park.mockParkID1, service: service)
        await service.waitForDefaultServed(count: 1) // init load consumed the default

        // Deterministically establish the baseline.
        await vm.load()
        #expect(vm.reviews == baseline)

        // Start a load that we will cancel while it is suspended on the gate.
        await service.arm(1)
        let staleTask = Task { await vm.load() }
        await service.waitForGated(count: 1)
        staleTask.cancel()
        await service.resume(index: 0, with: stale)
        _ = await staleTask.value

        // The cancelled load returned `stale`, but the guard must have dropped it.
        #expect(vm.reviews == baseline)
    }
}

// MARK: - Test Doubles

/// Always fails – used to verify error surfacing.
private struct FailingReviewsService: ReviewsServicing {
    struct SampleError: Error {}
    func fetchReviews(for parkID: UUID) async throws -> [ParkReview] { throw SampleError() }
    func submit(_ review: ParkReview) async throws -> [ParkReview] { throw SampleError() }
}

/// Deterministic stub: unarmed calls return `defaultResult` immediately; armed
/// calls suspend on a continuation until the test resumes them. No `Task.sleep`.
private actor GatedReviewsService: ReviewsServicing {
    private let defaultResult: [ParkReview]
    private var armed = 0
    private var gates: [CheckedContinuation<[ParkReview], Error>] = []
    private var defaultServed = 0
    private var gateWaiters: [CheckedContinuation<Void, Never>] = []
    private var defaultWaiters: [CheckedContinuation<Void, Never>] = []

    init(defaultResult: [ParkReview]) {
        self.defaultResult = defaultResult
    }

    func arm(_ count: Int) {
        armed += count
    }

    func waitForGated(count: Int) async {
        while gates.count < count {
            await withCheckedContinuation { gateWaiters.append($0) }
        }
    }

    func waitForDefaultServed(count: Int) async {
        while defaultServed < count {
            await withCheckedContinuation { defaultWaiters.append($0) }
        }
    }

    func resume(index: Int, with reviews: [ParkReview]) {
        guard gates.indices.contains(index) else { return }
        gates[index].resume(returning: reviews)
    }

    // MARK: ReviewsServicing
    func fetchReviews(for parkID: UUID) async throws -> [ParkReview] {
        if armed > 0 {
            armed -= 1
            return try await withCheckedThrowingContinuation { continuation in
                gates.append(continuation)
                if !gateWaiters.isEmpty { gateWaiters.removeFirst().resume() }
            }
        } else {
            defaultServed += 1
            if !defaultWaiters.isEmpty { defaultWaiters.removeFirst().resume() }
            return defaultResult
        }
    }

    func submit(_ review: ParkReview) async throws -> [ParkReview] {
        defaultResult
    }
}
