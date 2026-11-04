import Foundation

// MARK: - WeeklyGoalStoring
/// Persistence for the weekly goal: goal versions, pauses and shown
/// celebrations (`WeeklyGoalHistory`).
protocol WeeklyGoalStoring {
    /// The saved history, or `nil` when nothing was saved yet (the implicit
    /// default goal applies). Throws when a saved history exists but cannot be
    /// read; callers must show an error, never fall back to the default.
    func load() throws -> WeeklyGoalHistory?

    /// Replaces the saved history.
    func save(_ history: WeeklyGoalHistory) throws

    /// Replaces the saved value; `nil` deletes it, as if nothing had ever
    /// been saved (importing a backup).
    func replace(with history: WeeklyGoalHistory?) throws
}

// MARK: - Default replace
extension WeeklyGoalStoring {
    /// Fallback replace: saves a value, and refuses to delete one, since this
    /// store has no way to. Conformers that can delete should override this.
    func replace(with history: WeeklyGoalHistory?) throws {
        if let history {
            try save(history)
        } else if try load() != nil {
            throw StoreReplaceError.cannotDelete
        }
    }
}

// MARK: - FileWeeklyGoalStore
/// Default `WeeklyGoalStoring` implementation: one JSON file in the app's
/// store directory, through `JSONFileStore` (versioned envelope,
/// quarantine of unreadable files, writes refused while the file is broken).
struct FileWeeklyGoalStore: WeeklyGoalStoring {
    private let file: JSONFileStore<WeeklyGoalHistory>

    init(directory: URL, fileName: String = StoreFile.weeklyGoal.fileName) {
        file = JSONFileStore(fileURL: directory.appending(path: fileName), logCategory: "WeeklyGoalStore")
    }

    func load() throws -> WeeklyGoalHistory? {
        try file.read()
    }

    func save(_ history: WeeklyGoalHistory) throws {
        try file.write(history)
    }

    func replace(with history: WeeklyGoalHistory?) throws {
        if let history { try file.write(history) } else { try file.remove() }
    }
}

// MARK: - InMemoryWeeklyGoalStore
/// Non-persistent store for previews and unit tests.
final class InMemoryWeeklyGoalStore: WeeklyGoalStoring {
    private var history: WeeklyGoalHistory?
    /// How many times `save` ran, so tests can assert nothing was written.
    private(set) var saveCount = 0

    init(initial: WeeklyGoalHistory? = nil) {
        history = initial
    }

    func load() -> WeeklyGoalHistory? { history }

    func save(_ history: WeeklyGoalHistory) throws {
        self.history = history
        saveCount += 1
    }

    func replace(with history: WeeklyGoalHistory?) throws {
        self.history = history
        saveCount += 1
    }
}
