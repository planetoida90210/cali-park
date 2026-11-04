#if DEBUG
import Foundation

// MARK: - InMemoryFavoriteParkStore
/// Non-persistent store for previews and unit tests. `failure` makes every
/// call throw, like a broken file.
nonisolated final class InMemoryFavoriteParkStore: FavoriteParkStoring {
    struct Failure: Error {}

    private var ids: [UUID]
    var failure: Failure?
    /// How many times `replaceAll` succeeded, so tests can assert writes.
    private(set) var saveCount = 0

    init(initial: [UUID] = [], failure: Failure? = nil) {
        ids = initial
        self.failure = failure
    }

    func load() throws -> [UUID] {
        if let failure { throw failure }
        return ids
    }

    func replaceAll(with ids: [UUID]) throws {
        if let failure { throw failure }
        self.ids = ids
        saveCount += 1
    }
}
#endif
