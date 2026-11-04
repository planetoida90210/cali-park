#if DEBUG
import Foundation

// MARK: - InMemoryWeeklyGoalStore
/// Non-persistent store for previews and unit tests.
nonisolated final class InMemoryWeeklyGoalStore: WeeklyGoalStoring {
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
#endif
