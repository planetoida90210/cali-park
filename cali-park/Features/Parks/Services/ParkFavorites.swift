import Foundation
import Observation

// MARK: - ParkFavorites
/// The athlete's favorite Parks, shared by the Parks tab and the training
/// backup. Created once in `AppEnvironment`; the only write path to
/// `FavoriteParkStoring`, so every screen sees a change (an import too) by
/// observation.
///
/// IDs of Parks missing from the current snapshot are kept silently: the
/// screens simply don't show them, and they come back if the Park does.
@MainActor
@Observable
final class ParkFavorites {
    /// Alert text when the saved favorites can't be read.
    static let loadFailureMessage = String(localized: "Nie udało się odczytać ulubionych Parków. Nie zostały usunięte.")
    /// Alert text when a change can't be saved.
    static let saveFailureMessage = String(localized: "Nie udało się zapisać ulubionego Parku. Spróbuj ponownie.")

    /// Favorite Park IDs in the order they were added.
    private(set) var ids: [UUID] = []
    /// Set while the saved list can't be read; `ids` is then empty and every
    /// write is refused, so the file is never overwritten.
    private(set) var loadFailure: StoreLoadFailure?

    private let store: FavoriteParkStoring

    init(store: FavoriteParkStoring) {
        self.store = store
        reload()
    }

    func reload() {
        do {
            ids = try store.load()
            loadFailure = nil
        } catch {
            ids = []
            loadFailure = StoreLoadFailure(error)
        }
    }

    func contains(_ id: UUID) -> Bool {
        ids.contains(id)
    }

    /// Adds or removes a Park. Throws (and changes nothing) when the list
    /// can't be read or saved.
    func toggle(_ id: UUID) throws {
        try readable()
        var updated = ids
        if let index = updated.firstIndex(of: id) {
            updated.remove(at: index)
        } else {
            updated.append(id)
        }
        try store.replaceAll(with: updated)
        ids = updated
    }

    // MARK: Backup

    /// The saved list, for an export. Throws when it can't be read, so an
    /// export never silently leaves favorites out.
    func currentIDs() throws -> [UUID] {
        try readable()
        return ids
    }

    /// Replaces the whole list (importing a backup).
    func replaceAll(with ids: [UUID]) throws {
        try store.replaceAll(with: ids)
        self.ids = ids
        loadFailure = nil
    }

    private func readable() throws {
        if loadFailure != nil { reload() }
        if let loadFailure { throw loadFailure }
    }
}
