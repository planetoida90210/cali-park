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
}

// MARK: - FileWeeklyGoalStore
/// Default `WeeklyGoalStoring` implementation: one JSON file in the app's
/// documents directory, through `JSONFileStore` (versioned envelope,
/// quarantine of unreadable files, writes refused while the file is broken).
struct FileWeeklyGoalStore: WeeklyGoalStoring {
    private let file: JSONFileStore<WeeklyGoalHistory>

    init(directory: URL = .documentsDirectory, fileName: String = "weekly-goal.json") {
        file = JSONFileStore(fileURL: directory.appending(path: fileName), logCategory: "WeeklyGoalStore")
    }

    func load() throws -> WeeklyGoalHistory? {
        try file.read()
    }

    func save(_ history: WeeklyGoalHistory) throws {
        try file.write(history)
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
}
