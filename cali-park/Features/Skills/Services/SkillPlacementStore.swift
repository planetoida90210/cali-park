import Foundation

// MARK: - PlacementStoring
/// Abstraction over `SkillPlacement` persistence, mirroring `WorkoutLogStoring`
/// and `WorkoutPlanStoring`: view models stay testable with the in-memory stub,
/// and the backend can be swapped later (local JSON now → account sync later).
///
/// Placement is training data (declared rungs and owned equipment), not a
/// secret — no tokens, credentials, or entitlement flags belong here — so a
/// plain JSON file in the documents directory is the right store.
protocol PlacementStoring {
    /// The saved placement, or `nil` when the athlete never declared one (used
    /// to prompt calibration on first contact with the Skills tab). Throws when
    /// a saved placement exists but cannot be read — that is not "never declared".
    func load() throws -> SkillPlacement?

    /// Persists the placement, replacing any previous declaration.
    func save(_ placement: SkillPlacement) throws
}

// MARK: - FileSkillPlacementStore
/// Default `PlacementStoring` implementation: a single JSON file in the app's
/// documents directory, through `JSONFileStore`. Deliberately not Core Data —
/// one small value per user.
struct FileSkillPlacementStore: PlacementStoring {
    private let file: JSONFileStore<SkillPlacement>

    init(directory: URL = .documentsDirectory, fileName: String = "skill-placement.json") {
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
}
