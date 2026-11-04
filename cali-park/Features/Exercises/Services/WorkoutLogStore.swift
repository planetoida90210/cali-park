import Foundation

// MARK: - WorkoutLogStoring
/// Abstraction over workout log persistence so view models stay testable
/// (in-memory stub in tests) and the backend can be swapped later
/// (local JSON now → Supabase/Firebase when the backend lands).
///
/// Writes are `async`: a multi-year journal takes longer than a frame to
/// rewrite (C-8, D-7), so the file store does that work off the main actor.
/// They run in the order `TrainingJournal` issues them; the store itself does
/// not order concurrent calls. `load()` stays synchronous: the journal reads
/// once at launch, before the first screen, so it never shows an empty journal
/// while the file loads.
nonisolated protocol WorkoutLogStoring {
    /// Returns all persisted entries; empty when nothing has been logged yet.
    /// Throws when saved entries exist but cannot be read, so callers never
    /// mistake a broken file for an empty journal.
    func load() throws -> [WorkoutLogEntry]

    /// Persists a new entry.
    func append(_ entry: WorkoutLogEntry) async throws

    /// Persists several entries at once — used to save a whole quick-workout
    /// session in a single write so it is all-or-nothing.
    func append(contentsOf entries: [WorkoutLogEntry]) async throws

    /// Removes the entry with the given identifier; no-op if absent.
    func delete(id: UUID) async throws

    /// Removes every entry whose identifier is in `ids` in one write, so a
    /// whole workout is deleted all-or-nothing. Absent identifiers are skipped.
    func delete(ids: Set<UUID>) async throws

    /// Replaces the whole journal with `entries` (importing a backup).
    func replaceAll(with entries: [WorkoutLogEntry]) async throws
}

// MARK: - Default batch append
nonisolated extension WorkoutLogStoring {
    /// Fallback batch append for stores without an optimized version.
    /// Not atomic — conformers that can write once should override this.
    func append(contentsOf entries: [WorkoutLogEntry]) async throws {
        for entry in entries {
            try await append(entry)
        }
    }

    /// Fallback batch delete for stores without an optimized version.
    /// Not atomic — conformers that can write once should override this.
    func delete(ids: Set<UUID>) async throws {
        for id in ids {
            try await delete(id: id)
        }
    }

    /// Fallback replace for stores without an optimized version: deletes every
    /// entry, then appends the new ones. Not atomic — conformers that can
    /// write once should override this.
    func replaceAll(with entries: [WorkoutLogEntry]) async throws {
        for entry in try load() {
            try await delete(id: entry.id)
        }
        try await append(contentsOf: entries)
    }
}

// MARK: - FileWorkoutLogStore
/// Default `WorkoutLogStoring` implementation: a single JSON file in the
/// app's store directory, through `JSONFileStore`. Deliberately not Core Data.
/// Every write rewrites the whole file off the main actor; see the measured
/// limit in `docs/audit/STATUS.md` (C-8, D-7). A file that cannot be read
/// makes every call throw instead of being overwritten.
nonisolated struct FileWorkoutLogStore: WorkoutLogStoring {
    private let file: JSONFileStore<[WorkoutLogEntry]>

    init(directory: URL, fileName: String = StoreFile.workoutLog.fileName) {
        file = JSONFileStore(fileURL: directory.appending(path: fileName), logCategory: "WorkoutLogStore")
    }

    func load() throws -> [WorkoutLogEntry] {
        try file.read() ?? []
    }

    func append(_ entry: WorkoutLogEntry) async throws {
        try await file.update(initial: []) { $0.append(entry) }
    }

    /// One atomic write for the whole session — no partial persistence if the
    /// write fails midway.
    func append(contentsOf newEntries: [WorkoutLogEntry]) async throws {
        guard !newEntries.isEmpty else { return }
        try await file.update(initial: []) { $0.append(contentsOf: newEntries) }
    }

    func delete(id: UUID) async throws {
        try await file.update(initial: []) { $0.removeAll { $0.id == id } }
    }

    /// One atomic write for the whole set of entries.
    func delete(ids: Set<UUID>) async throws {
        guard !ids.isEmpty else { return }
        try await file.update(initial: []) { $0.removeAll { ids.contains($0.id) } }
    }

    /// One atomic write. Refused while the existing file is unreadable.
    func replaceAll(with entries: [WorkoutLogEntry]) async throws {
        try await file.write(entries)
    }
}
