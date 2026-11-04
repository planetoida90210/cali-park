import Foundation

// MARK: - InMemoryWorkoutLogStore
/// Non-persistent store for previews and unit tests.
nonisolated final class InMemoryWorkoutLogStore: WorkoutLogStoring {
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
