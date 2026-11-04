import Foundation
@testable import cali_park

// MARK: - Workout log store doubles
// Shared by every suite that needs a log store which fails, refuses writes or
// reports how often it was read and written.

/// A journal file that exists but cannot be read; writes fail the same way.
struct UnreadableWorkoutLogStore: WorkoutLogStoring {
    struct Unreadable: Error {}
    func load() throws -> [WorkoutLogEntry] { throw Unreadable() }
    func append(_ entry: WorkoutLogEntry) throws { throw Unreadable() }
    func append(contentsOf entries: [WorkoutLogEntry]) throws { throw Unreadable() }
    func delete(id: UUID) throws { throw Unreadable() }
    func delete(ids: Set<UUID>) throws { throw Unreadable() }
    func replaceAll(with entries: [WorkoutLogEntry]) throws { throw Unreadable() }
}

/// Reads `entries` but refuses every write, so nothing it returns ever changes.
struct ReadOnlyWorkoutLogStore: WorkoutLogStoring {
    struct WriteRefused: Error {}
    var entries: [WorkoutLogEntry] = []

    func load() -> [WorkoutLogEntry] { entries }
    func append(_ entry: WorkoutLogEntry) throws { throw WriteRefused() }
    func append(contentsOf entries: [WorkoutLogEntry]) throws { throw WriteRefused() }
    func delete(id: UUID) throws { throw WriteRefused() }
    func delete(ids: Set<UUID>) throws { throw WriteRefused() }
    func replaceAll(with entries: [WorkoutLogEntry]) throws { throw WriteRefused() }
}

/// An in-memory log store that counts reads and whole-file writes. Every
/// mutating call is one write, like one rewrite of the file store's JSON.
final class SpyWorkoutLogStore: WorkoutLogStoring {
    /// What one write did.
    enum Write: Equatable {
        case append([UUID])
        case delete(Set<UUID>)
        case replaceAll([UUID])
    }

    private(set) var entries: [WorkoutLogEntry]
    private(set) var loadCount = 0
    private(set) var writes: [Write] = []

    init(initial: [WorkoutLogEntry] = []) { entries = initial }

    var writeCount: Int { writes.count }

    func load() -> [WorkoutLogEntry] {
        loadCount += 1
        return entries
    }

    func append(_ entry: WorkoutLogEntry) throws {
        writes.append(.append([entry.id]))
        entries.append(entry)
    }

    func append(contentsOf newEntries: [WorkoutLogEntry]) throws {
        writes.append(.append(newEntries.map(\.id)))
        entries.append(contentsOf: newEntries)
    }

    func delete(id: UUID) throws {
        writes.append(.delete([id]))
        entries.removeAll { $0.id == id }
    }

    func delete(ids: Set<UUID>) throws {
        writes.append(.delete(ids))
        entries.removeAll { ids.contains($0.id) }
    }

    func replaceAll(with newEntries: [WorkoutLogEntry]) throws {
        writes.append(.replaceAll(newEntries.map(\.id)))
        entries = newEntries
    }
}
