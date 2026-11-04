import Foundation

// MARK: - WeeklyGoalPreview
/// Preview-only snapshots, so goal views can be eyeballed without a store.
enum WeeklyGoalPreview {
    private static let week = WeeklyGoalEvaluator.week(containing: .now)

    private static let days = WeeklyGoal(id: WeeklyGoal.defaultGoalID, metric: .trainingDays(days: 3))
    private static let pullUps = WeeklyGoal(
        metric: .exerciseVolume(
            exerciseID: ExerciseCatalog.pullUpsID, measurement: .reps, amount: 75
        ))
    private static let plans = WeeklyGoal(metric: .plannedWorkouts(target: .allScheduled))

    private static func snapshot(
        _ goals: [WeeklyGoalProgress],
        status: WeeklyGoalWeekStatus,
        streak: Int,
        pause: WeeklyGoalPause? = nil
    ) -> WeeklyGoalSnapshot {
        WeeklyGoalSnapshot(
            week: WeeklyGoalWeek(
                interval: week, goals: goals, status: status,
                isPaused: pause != nil, isWarmUp: false),
            streak: streak,
            activePause: pause,
            pendingCelebrations: [],
            isDefault: false
        )
    }

    static let running = snapshot(
        [
            WeeklyGoalProgress(goal: days, target: 3, value: 2),
            WeeklyGoalProgress(goal: pullUps, target: 75, value: 40),
            WeeklyGoalProgress(goal: plans, target: 2, value: 1)
        ], status: .inProgress, streak: 4)

    static let met = snapshot(
        [
            WeeklyGoalProgress(goal: days, target: 3, value: 3)
        ], status: .met, streak: 5)

    static let paused = snapshot(
        [WeeklyGoalProgress(goal: days, target: 3, value: 0)],
        status: .paused,
        streak: 5,
        pause: WeeklyGoalPause(start: week.start, plannedEnd: week.end.addingTimeInterval(7 * 86_400))
    )
}
