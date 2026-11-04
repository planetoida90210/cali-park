import Foundation

// MARK: - WeeklyGoalProgress
/// One goal's progress in one week.
nonisolated struct WeeklyGoalProgress: Identifiable, Equatable, Sendable {
    let goal: WeeklyGoal
    /// What the week asks for. `0` only for "all scheduled" with nothing
    /// scheduled that week.
    let target: Int
    /// What was done so far.
    let value: Int

    var id: UUID { goal.id }

    var isMet: Bool { target > 0 && value >= target }

    /// Progress from 0 to 1, for rings and bars.
    var fraction: Double {
        guard target > 0 else { return 0 }
        return min(1, Double(value) / Double(target))
    }
}

// MARK: - WeeklyGoalWeekStatus
/// How a week went for the primary goal. Only `met` extends the week streak and
/// only `missed` breaks it; every other status is neutral.
nonisolated enum WeeklyGoalWeekStatus: Equatable, Sendable {
    /// The primary goal was reached.
    case met
    /// The current week, not reached yet.
    case inProgress
    /// A closed week that fell short.
    case missed
    /// A pause touched the week and the goal was not reached.
    case paused
    /// The first, partial week after the goal was set, not reached.
    case warmUp
    /// "All scheduled" with no plan scheduled that week.
    case nothingScheduled

    /// Whether the week leaves the streak as it is.
    var isNeutral: Bool {
        switch self {
        case .met, .missed: false
        case .inProgress, .paused, .warmUp, .nothingScheduled: true
        }
    }
}

// MARK: - WeeklyGoalWeek
/// One Monday–Sunday week judged against the goals in force for it.
nonisolated struct WeeklyGoalWeek: Equatable, Sendable {
    /// Monday 00:00 to the next Monday 00:00.
    let interval: DateInterval
    /// Every goal's progress, primary first.
    let goals: [WeeklyGoalProgress]
    /// The primary goal's verdict for the week.
    let status: WeeklyGoalWeekStatus
    /// Whether a pause touches this week.
    let isPaused: Bool
    /// Whether this is the first, partial week after the goal was set.
    let isWarmUp: Bool

    var primary: WeeklyGoalProgress { goals[0] }
}

// MARK: - WeeklyGoalSnapshot
/// Everything Home shows about the weekly goal right now.
nonisolated struct WeeklyGoalSnapshot: Equatable, Sendable {
    /// The current week, judged by the latest goals.
    let week: WeeklyGoalWeek
    /// Weeks in a row with the primary goal met; neutral weeks are skipped.
    let streak: Int
    /// The pause in force now, if any.
    let activePause: WeeklyGoalPause?
    /// Goals met this week whose celebration has not been shown yet.
    let pendingCelebrations: [WeeklyGoalProgress]
    /// Whether the goals are still the implicit default (nothing saved).
    let isDefault: Bool
}
