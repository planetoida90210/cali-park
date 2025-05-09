import Foundation

// MARK: - User DTO
/// Minimal representation of an app user, used mainly for event participants lists.
/// For the UI-first phase contains only a subset of fields expected from backend.
struct User: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var avatarURL: URL?

    // MARK: - Mock
    static var mock: User {
        User(id: UUID(), name: "Anon", avatarURL: nil)
    }
} 