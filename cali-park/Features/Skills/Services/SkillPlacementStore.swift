import Foundation

// MARK: - PlacementStoring
/// Abstraction over `SkillPlacement` persistence, mirroring `WorkoutLogStoring`
/// and `WorkoutPlanStoring`: view models stay testable with the in-memory stub,
/// and the backend can be swapped later (local JSON now → account sync later).
///
/// Placement is training data (declared rungs and owned equipment), not a
/// secret — no tokens, credentials, or entitlement flags belong here — so a
/// plain JSON file in the store directory is the right store.
protocol PlacementStoring {
    /// The saved placement, or `nil` when the athlete never declared one (used
    /// to prompt calibration on first contact with the Skills tab). Throws when
    /// a saved placement exists but cannot be read — that is not "never declared".
    func load() throws -> SkillPlacement?

    /// Persists the placement, replacing any previous declaration.
    func save(_ placement: SkillPlacement) throws

    /// Replaces the saved value; `nil` deletes it, as if nothing had ever
    /// been saved (importing a backup).
    func replace(with placement: SkillPlacement?) throws
}

// MARK: - Default replace
extension PlacementStoring {
    /// Fallback replace: saves a value, and refuses to delete one, since this
    /// store has no way to. Conformers that can delete should override this.
    func replace(with placement: SkillPlacement?) throws {
        if let placement {
            try save(placement)
        } else if try load() != nil {
            throw StoreReplaceError.cannotDelete
        }
    }
}

// MARK: - FileSkillPlacementStore
/// Default `PlacementStoring` implementation: a single JSON file in the app's
/// store directory, through `JSONFileStore`. Deliberately not Core Data —
/// one small value per user.
struct FileSkillPlacementStore: PlacementStoring {
    private let file: JSONFileStore<SkillPlacement>

    init(directory: URL, fileName: String = StoreFile.skillPlacement.fileName) {
        file = JSONFileStore(
            fileURL: directory.appending(path: fileName),
            logCategory: "SkillPlacementStore",
            schemaVersion: SkillPlacement.schemaVersion
        )
    }

    func load() throws -> SkillPlacement? {
        try file.read()
    }

    func save(_ placement: SkillPlacement) throws {
        try file.write(placement)
    }

    func replace(with placement: SkillPlacement?) throws {
        if let placement { try file.write(placement) } else { try file.remove() }
    }
}

// MARK: - InMemorySkillPlacementStore
/// Non-persistent store for previews and unit tests.
final class InMemorySkillPlacementStore: PlacementStoring {
    private var placement: SkillPlacement?

    init(initial: SkillPlacement? = nil) {
        placement = initial
    }

    func load() -> SkillPlacement? { placement }

    func save(_ placement: SkillPlacement) throws {
        self.placement = placement
    }

    func replace(with placement: SkillPlacement?) throws {
        self.placement = placement
    }
}
