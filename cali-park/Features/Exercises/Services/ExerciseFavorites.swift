import Foundation
import Observation

// MARK: - ExerciseFavorites
/// The athlete's favorite exercises, listed first in every exercise picker
/// and in the Exercises tab, and carried in the training backup. Created once
/// in `AppEnvironment`; the only write path to `FavoriteExerciseStoring`, so
/// every screen sees a change (an import too) by observation.
///
/// Any catalog exercise can be a favorite, progression variants included
/// ("Podciągnięcia australijskie"). IDs of exercises missing from the catalog
/// are kept silently: the screens simply don't show them.
@MainActor
@Observable
final class ExerciseFavorites {
    /// Alert text when the saved favorites can't be read.
    static let loadFailureMessage = String(localized: "Nie udało się odczytać ulubionych ćwiczeń. Nie zostały usunięte.")
    /// Alert text when a change can't be saved.
    static let saveFailureMessage = String(localized: "Nie udało się zapisać ulubionego ćwiczenia. Spróbuj ponownie.")

    /// Favorite exercise IDs in the order they were added.
    private(set) var ids: [UUID] = []
    /// Set while the saved list can't be read; `ids` is then empty and every
    /// write is refused, so the file is never overwritten.
    private(set) var loadFailure: StoreLoadFailure?

    private let store: FavoriteExerciseStoring

    init(store: FavoriteExerciseStoring) {
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

    /// Adds an exercise at the end or removes it. Throws (and changes
    /// nothing) when the list can't be read or saved.
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

    /// Like `toggle`, but returns the alert text for a failure instead of
    /// throwing, for the screens' star buttons and menus.
    func toggleReportingFailure(_ id: UUID) -> String? {
        do {
            try toggle(id)
            return nil
        } catch is StoreLoadFailure {
            return Self.loadFailureMessage
        } catch {
            return Self.saveFailureMessage
        }
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
