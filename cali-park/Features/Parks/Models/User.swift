import Foundation

// MARK: - User DTO
/// Minimal representation of an app user, used mainly for event participants lists.
/// For the UI-first phase contains only a subset of fields expected from backend.
struct User: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var avatarURL: URL?
    var bio: String?

    // MARK: - Mock
    /// Stable identity — a computed property returned a new UUID on every access,
    /// which broke "current user" matching (e.g. finding own review by `userID`).
    static let mock = User(
        id: UUID(uuidString: "B2000000-0000-4000-8000-000000000001")!,
        name: "Anon",
        avatarURL: nil,
        bio: "Lubiący kalistenikę bywalec parków"
    )
} 