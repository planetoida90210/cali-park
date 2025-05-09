import Foundation

// MARK: - ReviewsServicing protocol
/// Abstraction layer for fetching & submitting park reviews.
/// Allows easy replacement of implementation (e.g. Supabase RPC) without touching the UI.
protocol ReviewsServicing {
    /// Returns list of reviews for given park. Order decided by backend (usually newest first).
    func fetchReviews(for parkID: UUID) async throws -> [ParkReview]

    /// Submits new or updated review. Backend decides if this is create or update based on userID.
    /// Returns refreshed list of reviews.
    func submit(_ review: ParkReview) async throws -> [ParkReview]
}

// MARK: - ReviewsService (stub)
/// A simple in-memory store mimicking latency. Swappable with real network layer.
actor ReviewsService: ReviewsServicing {
    // Simulated database: parkID → reviews list
    private var storage: [UUID: [ParkReview]] = [:]

    // MARK: Init with mock data
    init(seedParks: [Park] = Park.mock) {
        for park in seedParks {
            storage[park.id] = ParkReview.mocks(for: park.id)
        }
    }

    // MARK: ReviewsServicing
    func fetchReviews(for parkID: UUID) async throws -> [ParkReview] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        return storage[parkID] ?? []
    }

    func submit(_ review: ParkReview) async throws -> [ParkReview] {
        try await Task.sleep(nanoseconds: 350_000_000)
        var list = storage[review.parkID] ?? []
        // Remove existing review by same user if exists (one per user rule)
        list.removeAll { $0.userID == review.userID }
        list.append(review)
        storage[review.parkID] = list
        return list
    }
} 