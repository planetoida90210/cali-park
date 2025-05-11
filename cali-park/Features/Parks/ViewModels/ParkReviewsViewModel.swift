import Foundation
import Combine

// Sorting options for reviews
enum ReviewSortOption: String, CaseIterable, Identifiable {
    case newest = "Najnowsze"
    case ratingHigh = "Najwyższa ocena"
    case ratingLow = "Najniższa ocena"

    var id: Self { self }
}

// MARK: - ParkReviewsViewModel
@MainActor
final class ParkReviewsViewModel: ObservableObject {
    // MARK: Published
    @Published private(set) var reviews: [ParkReview] = []
    /// Review created by CURRENT logged-in user (nil if none yet).
    @Published private(set) var userReview: ParkReview?
    /// Local flag to drive loading states in UI.
    @Published var isBusy: Bool = false

    // Pagination & filtering
    @Published var showOnlyWithComment: Bool = false {
        didSet { resetPagination() }
    }
    private let pageSize: Int = 5
    @Published private(set) var currentPage: Int = 0

    // Sorting
    @Published var sortOption: ReviewSortOption = .newest {
        didSet { resetPagination() }
    }

    var filteredReviews: [ParkReview] {
        showOnlyWithComment ? reviews.filter { !$0.comment.isEmpty } : reviews
    }

    private var sortedReviews: [ParkReview] {
        switch sortOption {
        case .newest:
            return filteredReviews.sorted { $0.createdAt > $1.createdAt }
        case .ratingHigh:
            return filteredReviews.sorted { $0.rating > $1.rating }
        case .ratingLow:
            return filteredReviews.sorted { $0.rating < $1.rating }
        }
    }

    var loadedReviews: [ParkReview] {
        let end = min(sortedReviews.count, (currentPage + 1) * pageSize)
        return Array(sortedReviews.prefix(end))
    }

    var hasMore: Bool {
        (currentPage + 1) * pageSize < sortedReviews.count
    }

    // MARK: Private
    private let parkID: UUID
    private let currentUserID: UUID
    private let service: ReviewsServicing

    // MARK: Computed helpers
    var averageRating: Double {
        guard !reviews.isEmpty else { return 0 }
        let sum = reviews.reduce(0) { $0 + $1.rating }
        return Double(sum) / Double(reviews.count)
    }

    // MARK: Init
    init(parkID: UUID,
         currentUserID: UUID = User.mock.id,
         service: ReviewsServicing = ReviewsService()) {
        self.parkID = parkID
        self.currentUserID = currentUserID
        self.service = service
        Task { await load() }
    }

    // MARK: Public API
    func load() async {
        isBusy = true
        defer { isBusy = false }
        do {
            reviews = try await service.fetchReviews(for: parkID)
            userReview = reviews.first(where: { $0.userID == currentUserID })
            resetPagination()
        } catch {
            // TODO: handle error (e.g., via AlertPublisher) – UI-first skip for now
        }
    }

    /// Adds new or updates existing review for the current user.
    func submit(rating: Int, comment: String) async {
        var review = ParkReview(
            parkID: parkID,
            userID: currentUserID,
            rating: rating,
            comment: comment,
            createdAt: Date(),
            updatedAt: Date()
        )

        isBusy = true
        defer { isBusy = false }
        do {
            let refreshed = try await service.submit(review)
            reviews = refreshed
            userReview = reviews.first(where: { $0.userID == currentUserID })
        } catch {
            // TODO: error handling
        }
    }

    func loadMore() {
        guard hasMore else { return }
        currentPage += 1
    }

    private func resetPagination() {
        currentPage = 0
    }
} 