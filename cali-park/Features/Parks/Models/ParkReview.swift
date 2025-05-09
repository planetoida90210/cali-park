import Foundation

// MARK: - ParkReview Model
/// User-generated review for a specific park. Ready for Supabase (or any backend) integration.
/// The client never calculates averages – server responsibility.
struct ParkReview: Identifiable, Codable, Equatable, Hashable {
    // MARK: Stored properties
    let id: UUID
    let parkID: UUID
    let userID: UUID

    /// Rating from 1 to 5 stars (inclusive).
    var rating: Int {
        didSet { rating = max(1, min(5, rating)) }
    }

    /// Optional short comment limited to 140 characters (back-end validated as well).
    var comment: String {
        didSet { comment = String(comment.prefix(140)) }
    }

    /// Date when the review was originally created.
    let createdAt: Date
    /// Date when the review was last updated (if ever).
    var updatedAt: Date?

    // MARK: Init
    init(id: UUID = UUID(),
         parkID: UUID,
         userID: UUID,
         rating: Int,
         comment: String = "",
         createdAt: Date = Date(),
         updatedAt: Date? = nil) {
        self.id = id
        self.parkID = parkID
        self.userID = userID
        self.rating = max(1, min(5, rating))
        self.comment = String(comment.prefix(140))
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Mock Data
extension ParkReview {
    /// Returns deterministic mock reviews for previews / offline mode.
    static func mocks(for parkID: UUID) -> [ParkReview] {
        let users = [User.mock, User.mock]
        return [
            ParkReview(parkID: parkID, userID: users[0].id, rating: 5,
                        comment: "Świetny park! Dużo sprzętu i czystość na medal."),
            ParkReview(parkID: parkID, userID: users[1].id, rating: 4,
                        comment: "Fajnie, ale przydałoby się więcej drążków niskich dla początkujących.")
        ]
    }
} 