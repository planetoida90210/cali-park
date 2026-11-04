import SwiftUI

// MARK: - HeroStateContent
/// The inside of the Home hero card: the view for the resolved `HomeHeroState`,
/// with the weekly goal row and the progression hint where that state shows them.
struct HeroStateContent: View {
    let state: HomeHeroState
    /// `nil` hides the goal row (the goal could not be read).
    let weeklyGoal: WeeklyGoalSnapshot?
    /// The one-line progression nudge for rest / free-training days; `nil` hides it.
    let progressionHint: String?
    /// Whether "Czas na Fundamenty" takes the hint's line.
    let showsGraduationHint: Bool
    let now: Date
    /// Starts today's plan.
    let onStartPlan: (WorkoutPlan) -> Void
    /// Opens the weekly goal editor (long press on the goal row).
    let onEditGoal: () -> Void

    var body: some View {
        switch state {
        case .planToday(let plan, let loggedTodayReps, let loggedTodaySeconds):
            HeroPlanTodayView(
                plan: plan,
                loggedTodayReps: loggedTodayReps,
                loggedTodaySeconds: loggedTodaySeconds,
                weeklyGoal: weeklyGoal,
                onEditGoal: onEditGoal,
                now: now,
                onStart: { onStartPlan(plan) }
            )

        case .completedToday(let summary, _):
            HeroCompletedTodayView(
                summary: summary,
                weeklyGoal: weeklyGoal,
                onEditGoal: onEditGoal,
                now: now
            )

        case .restDay(let nextPlan, let date, _):
            HeroRestDayView(
                nextPlan: nextPlan,
                date: date,
                weeklyGoal: weeklyGoal,
                onEditGoal: onEditGoal,
                progressionHint: progressionHint,
                showsGraduationHint: showsGraduationHint,
                now: now
            )

        case .freeMode(let lastWorkout, let suggestion, _):
            HeroFreeModeView(
                lastWorkout: lastWorkout,
                suggestion: suggestion,
                weeklyGoal: weeklyGoal,
                onEditGoal: onEditGoal,
                progressionHint: progressionHint,
                showsGraduationHint: showsGraduationHint,
                now: now
            )

        case .firstRun:
            HeroFirstRunView(weeklyGoal: weeklyGoal, onEditGoal: onEditGoal, now: now)
        }
    }
}
