import Foundation

// MARK: - WorkoutLogStoring
/// Abstraction over workout log persistence so view models stay testable
/// (in-memory stub in tests) and the backend can be swapped later
/// (local JSON now → Supabase/Firebase when the backend lands).
protocol WorkoutLogStoring {
    /// Returns all persisted entries; empty when nothing has been logged yet.
    /// Throws when saved entries exist but cannot be read, so callers never
    /// mistake a broken file for an empty journal.
    func load() throws -> [WorkoutLogEntry]

    /// Persists a new entry.
    func append(_ entry: WorkoutLogEntry) throws

    /// Persists several entries at once — used to save a whole quick-workout
    /// session in a single write so it is all-or-nothing.
    func append(contentsOf entries: [WorkoutLogEntry]) throws

    /// Removes the entry with the given identifier; no-op if absent.
    func delete(id: UUID) throws

    /// Removes every entry whose identifier is in `ids` in one write, so a
    /// whole workout is deleted all-or-nothing. Absent identifiers are skipped.
    func delete(ids: Set<UUID>) throws

    /// Replaces the whole journal with `entries` (importing a backup).
    func replaceAll(with entries: [WorkoutLogEntry]) throws
}

// MARK: - Default batch append
extension WorkoutLogStoring {
    /// Fallback batch append for stores without an optimized version.
    /// Not atomic — conformers that can write once should override this.
    func append(contentsOf entries: [WorkoutLogEntry]) throws {
        for entry in entries {
            try append(entry)
        }
    }

    /// Fallback batch delete for stores without an optimized version.
    /// Not atomic — conformers that can write once should override this.
    func delete(ids: Set<UUID>) throws {
        for id in ids {
            try delete(id: id)
        }
    }

    /// Fallback replace for stores without an optimized version: deletes every
    /// entry, then appends the new ones. Not atomic — conformers that can
    /// write once should override this.
    func replaceAll(with entries: [WorkoutLogEntry]) throws {
        for entry in try load() {
            try delete(id: entry.id)
        }
        try append(contentsOf: entries)
    }
}

// MARK: - FileWorkoutLogStore
/// Default `WorkoutLogStoring` implementation: a single JSON file in the
/// app's store directory, through `JSONFileStore`. Adequate for a personal
/// training log (tens–hundreds of entries); deliberately not Core Data. A file
/// that cannot be read makes every call throw instead of being overwritten.
struct FileWorkoutLogStore: WorkoutLogStoring {
    private let file: JSONFileStore<[WorkoutLogEntry]>

    init(directory: URL, fileName: String = StoreFile.workoutLog.fileName) {
        file = JSONFileStore(fileURL: directory.appending(path: fileName), logCategory: "WorkoutLogStore")
    }

    func load() throws -> [WorkoutLogEntry] {
        try file.read() ?? []
    }

    func append(_ entry: WorkoutLogEntry) throws {
        try file.update(initial: []) { $0.append(entry) }
    }

    /// One atomic write for the whole session — no partial persistence if the
    /// write fails midway.
    func append(contentsOf newEntries: [WorkoutLogEntry]) throws {
        guard !newEntries.isEmpty else { return }
        try file.update(initial: []) { $0.append(contentsOf: newEntries) }
    }

    func delete(id: UUID) throws {
        try file.update(initial: []) { $0.removeAll { $0.id == id } }
    }

    /// One atomic write for the whole set of entries.
    func delete(ids: Set<UUID>) throws {
        guard !ids.isEmpty else { return }
        try file.update(initial: []) { $0.removeAll { ids.contains($0.id) } }
    }

    /// One atomic write. Refused while the existing file is unreadable.
    func replaceAll(with entries: [WorkoutLogEntry]) throws {
        try file.write(entries)
    }
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

    func delete(ids: Set<UUID>) throws {
        entries.removeAll { ids.contains($0.id) }
    }

    func replaceAll(with entries: [WorkoutLogEntry]) throws {
        self.entries = entries
    }
}
