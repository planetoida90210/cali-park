import Foundation

// MARK: - FavoritesStoring
/// Abstraction over favorite parks persistence so `ParksViewModel` stays testable
/// (in-memory stub in tests) and the storage backend can be swapped later
/// (UserDefaults now → backend/account sync when available).
///
/// Favorite parks are *not* secret, so `UserDefaults` is an acceptable store here.
protocol FavoritesStoring {
    /// Returns the persisted favorite park identifiers, or `nil` if nothing has
    /// ever been saved (used to seed defaults on first launch).
    func loadFavorites() -> Set<UUID>?

    /// Persists the full set of favorite park identifiers.
    func saveFavorites(_ ids: Set<UUID>)
}

// MARK: - UserDefaultsFavoritesStore
/// Default `FavoritesStoring` implementation backed by `UserDefaults`.
struct UserDefaultsFavoritesStore: FavoritesStoring {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "favoriteParkIDs") {
        self.defaults = defaults
        self.key = key
    }

    func loadFavorites() -> Set<UUID>? {
        guard let raw = defaults.array(forKey: key) as? [String] else { return nil }
        return Set(raw.compactMap(UUID.init(uuidString:)))
    }

    func saveFavorites(_ ids: Set<UUID>) {
        defaults.set(ids.map(\.uuidString), forKey: key)
    }
}

// MARK: - InMemoryFavoritesStore
/// Non-persistent store for previews and unit tests.
final class InMemoryFavoritesStore: FavoritesStoring {
    private var storage: Set<UUID>?

    init(initial: Set<UUID>? = nil) {
        storage = initial
    }

    func loadFavorites() -> Set<UUID>? { storage }

    func saveFavorites(_ ids: Set<UUID>) { storage = ids }
}
