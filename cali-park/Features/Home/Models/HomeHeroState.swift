import Foundation

// MARK: - HomeHeroState
/// What the Home hero should say right now, resolved from the workout log and
/// the user's plans. A plain value describing the state — the view that renders
/// it (`ContextualHeroView`) stays "dumb" and switches on these cases. Deciding which case
/// applies lives in `HomeDashboardViewModel.heroState(asOf:)`.
///
/// The weekly goal and its week streak never live *inside* these cases: they
/// stay on the view model and the hero view shows them as a secondary row
/// in every state. The hero no longer shows the
/// day `streak` carried here (ticket 027: rest days are part of training); the
/// "Seria dni" module still does.
nonisolated enum HomeHeroState: Equatable {
    /// A plan is scheduled for today and hasn't been completed yet. `plan`
    /// drives the big "Rozpocznij" call to action; `loggedTodayReps` and
    /// `loggedTodaySeconds` are any progress already logged today, holds kept
    /// apart from reps (both 0 when the day is still untouched).
    case planToday(plan: WorkoutPlan, loggedTodayReps: Int, loggedTodaySeconds: Int = 0)

    /// Today's training is done — either the scheduled plan or a free workout.
    /// `summary` is the session/workout to celebrate; `streak` is the run kept
    /// alive by finishing today.
    case completedToday(summary: WorkoutSession, streak: WorkoutStreak)

    /// Nothing scheduled for today, but a future plan exists. Shows the streak
    /// and when the `nextPlan` comes up (`date`).
    case restDay(nextPlan: WorkoutPlan, date: Date, streak: WorkoutStreak)

    /// No plans at all, yet the journal has history. Shows the streak, the last
    /// workout, and a `suggestion` for what to train next (`nil` when the
    /// heuristic can't pick one).
    case freeMode(lastWorkout: WorkoutSession, suggestion: Exercise?, streak: WorkoutStreak)

    /// A fresh start: no plans and an empty journal. Invites the user to plan or
    /// start a quick workout.
    case firstRun
}
