import Foundation

// MARK: - WorkoutLogStoring
/// Abstraction over workout log persistence so view models stay testable
/// (in-memory stub in tests) and the backend can be swapped later
/// (local JSON now → Supabase/Firebase when the backend lands).
protocol WorkoutLogStoring {
    /// Returns all persisted entries; empty when nothing has been logged yet.
    func load() -> [WorkoutLogEntry]

    /// Persists a new entry.
    func append(_ entry: WorkoutLogEntry) throws

    /// Removes the entry with the given identifier; no-op if absent.
    func delete(id: UUID) throws
}

// MARK: - FileWorkoutLogStore
/// Default `WorkoutLogStoring` implementation: a single JSON file in the
/// app's documents directory. Adequate for a personal training log
/// (tens–hundreds of entries); deliberately not Core Data.
struct FileWorkoutLogStore: WorkoutLogStoring {
    private let fileURL: URL

    init(directory: URL = .documentsDirectory, fileName: String = "workout-log.json") {
        fileURL = directory.appending(path: fileName)
    }

    func load() -> [WorkoutLogEntry] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? Self.decoder.decode([WorkoutLogEntry].self, from: data)) ?? []
    }

    func append(_ entry: WorkoutLogEntry) throws {
        var entries = load()
        entries.append(entry)
        try save(entries)
    }

    func delete(id: UUID) throws {
        var entries = load()
        entries.removeAll { $0.id == id }
        try save(entries)
    }

    private func save(_ entries: [WorkoutLogEntry]) throws {
        let data = try Self.encoder.encode(entries)
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

// MARK: - InMemoryWorkoutLogStore
/// Non-persistent store for previews and unit tests.
final class InMemoryWorkoutLogStore: WorkoutLogStoring {
    private var entries: [WorkoutLogEntry]

    init(initial: [WorkoutLogEntry] = []) {
        entries = initial
    }

    func load() -> [WorkoutLogEntry] { entries }

    func append(_ entry: WorkoutLogEntry) throws {
        entries.append(entry)
    }

    func delete(id: UUID) throws {
        entries.removeAll { $0.id == id }
    }
}
