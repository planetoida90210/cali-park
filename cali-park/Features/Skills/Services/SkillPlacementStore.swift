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
    /// to prompt calibration on first contact with the Skills tab).
    func load() -> SkillPlacement?

    /// Persists the placement, replacing any previous declaration.
    func save(_ placement: SkillPlacement) throws
}

// MARK: - FileSkillPlacementStore
/// Default `PlacementStoring` implementation: a single JSON file in the app's
/// documents directory. Deliberately not Core Data — one small value per user.
struct FileSkillPlacementStore: PlacementStoring {
    private let fileURL: URL

    init(directory: URL = .documentsDirectory, fileName: String = "skill-placement.json") {
        fileURL = directory.appending(path: fileName)
    }

    func load() -> SkillPlacement? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? Self.decoder.decode(SkillPlacement.self, from: data)
    }

    func save(_ placement: SkillPlacement) throws {
        let data = try Self.encoder.encode(placement)
        try data.write(to: fileURL, options: .atomic)
    }

    // ISO 8601 dates keep the JSON file human-readable and stable across formats.
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
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
