import Foundation

// MARK: - ProfileStatistics
/// The numbers at the top of Profile, all derived from the workout log (and
/// the weekly goal for the week streak). Never persisted.
struct ProfileStatistics: Equatable, Sendable {
    /// Workouts as the athlete counts them: a quick-workout session is one,
    /// a standalone log is one (`WorkoutSession.grouped`).
    let workouts: Int
    /// Consecutive days with a workout, still alive today.
    let dayStreak: Int
    /// The longest run of consecutive training days ever.
    let longestDayStreak: Int
    /// Weeks in a row with the primary weekly goal met; `nil` while the goal
    /// cannot be read.
    let weekStreak: Int?
    let level: PlayerLevel

    static let empty = ProfileStatistics(
        workouts: 0, dayStreak: 0, longestDayStreak: 0, weekStreak: 0, level: .forXP(0)
    )
}
