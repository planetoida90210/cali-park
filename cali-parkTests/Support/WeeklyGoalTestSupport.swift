import Foundation

@testable import cali_park

// MARK: - WeeklyGoalFixtures
/// Shared fixtures for the weekly goal tests: a gregorian UTC calendar whose
/// first weekday is Sunday (so Monday-first weeks never come from the locale),
/// fixed dates around November 2026, and entry/plan builders.
enum WeeklyGoalFixtures {
    static let calendar = TestCalendar.utc

    /// A UTC date at whole seconds.
    static func date(
        _ year: Int, _ month: Int, _ day: Int,
        _ hour: Int = 12, _ minute: Int = 0, _ second: Int = 0
    ) -> Date {
        TestDate.at(year, month, day, hour, minute, second, in: calendar)
    }

    /// Monday 2026-11-02 00:00, the start of the reference week.
    static let monday = date(2026, 11, 2, 0)

    /// `monday` shifted by whole weeks, plus `days` and `hour` (noon by default).
    static func day(week: Int = 0, _ days: Int = 0, hour: Int = 12) -> Date {
        calendar.date(byAdding: DateComponents(day: week * 7 + days, hour: hour), to: monday)!
    }

    /// The week starting `week` weeks after the reference Monday.
    static func week(_ week: Int) -> DateInterval {
        WeeklyGoalEvaluator.week(containing: day(week: week), calendar: calendar)
    }

    /// One pull-up set logged at `date`.
    static func entry(
        at date: Date,
        exercise: UUID = ExerciseCatalog.pullUpsID,
        sets: [LoggedSet] = [LoggedSet(reps: 8)],
        plan: WorkoutPlan? = nil
    ) -> WorkoutLogEntry {
        WorkoutLogEntry(exerciseID: exercise, date: date, sets: sets, planID: plan?.id)
    }

    /// One workout on each of `days` (offsets from Monday) of week `week`.
    static func trained(week: Int, days: [Int]) -> [WorkoutLogEntry] {
        days.map { entry(at: day(week: week, $0)) }
    }

    static func goal(_ metric: WeeklyGoal.Metric, id: UUID = UUID()) -> WeeklyGoal {
        WeeklyGoal(id: id, metric: metric)
    }

    static func days(_ count: Int, id: UUID = WeeklyGoal.defaultGoalID) -> WeeklyGoal {
        WeeklyGoal(id: id, metric: .trainingDays(days: count))
    }

    static func version(_ goals: [WeeklyGoal], from date: Date) -> WeeklyGoalVersion {
        WeeklyGoalVersion(effectiveFrom: date, goals: goals)
    }
}

// MARK: - Failing stores

/// A weekly goal store whose saved file cannot be read.
final class BrokenWeeklyGoalStore: WeeklyGoalStoring {
    struct Failure: Error {}
    func load() throws -> WeeklyGoalHistory? { throw Failure() }
    func save(_ history: WeeklyGoalHistory) throws { throw Failure() }
}

/// Reads fine but refuses every write.
final class ReadOnlyWeeklyGoalStore: WeeklyGoalStoring {
    struct Failure: Error {}
    private let history: WeeklyGoalHistory?
    init(initial: WeeklyGoalHistory? = nil) { history = initial }
    func load() -> WeeklyGoalHistory? { history }
    func save(_ history: WeeklyGoalHistory) throws { throw Failure() }
}
