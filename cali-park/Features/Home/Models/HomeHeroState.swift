import Foundation

// MARK: - HomeHeroState
/// What the Home hero should say right now, resolved from the workout log and
/// the user's plans. A plain value describing the state — the view that renders
/// it (Sprint H2) stays "dumb" and switches on these cases. Deciding which case
/// applies lives in `HomeDashboardViewModel.heroState(asOf:)`.
///
/// Weekly pull-ups and the goal ring never live *inside* these cases: they stay
/// on the view model and the hero view demotes them to a secondary line where
/// they fit (completed / rest / free mode).
enum HomeHeroState: Equatable {
    /// A plan is scheduled for today and hasn't been completed yet. `plan`
    /// drives the big "Rozpocznij" call to action; `loggedTodayReps` is any
    /// progress already logged today (0 when the day is still untouched).
    case planToday(plan: WorkoutPlan, loggedTodayReps: Int)

    /// Today's training is done — either the scheduled plan or a free workout.
    /// `summary` is the session/workout to celebrate; `streak` is the run kept
    /// alive by finishing today.
    case completedToday(summary: HomeDashboardViewModel.LatestWorkout, streak: WorkoutStreak)

    /// Nothing scheduled for today, but a future plan exists. Shows the streak
    /// and when the `nextPlan` comes up (`date`).
    case restDay(nextPlan: WorkoutPlan, date: Date, streak: WorkoutStreak)

    /// No plans at all, yet the journal has history. Shows the streak, the last
    /// workout, and a `suggestion` for what to train next (`nil` when the
    /// heuristic can't pick one).
    case freeMode(lastWorkout: HomeDashboardViewModel.LatestWorkout, suggestion: Exercise?, streak: WorkoutStreak)

    /// A fresh start: no plans and an empty journal. Invites the user to plan or
    /// start a quick workout.
    case firstRun
}
