import Foundation

// MARK: - TrainingBackup
/// Everything the athlete owns in one value: the content of the export file
/// ("Eksport i import treningów" in Profile) and the unit an import replaces.
///
/// There are no favorite Parks to include: the read-only map of OSM Parks has
/// none yet (the placeholder favorites were removed with it). Progress (level,
/// streaks, rungs) is never stored; it is recomputed from the log after an
/// import.
struct TrainingBackup: Equatable, Sendable {
    var workoutLog: [WorkoutLogEntry]
    var workoutPlans: [WorkoutPlan]
    /// `nil` when the athlete never took the level test.
    var placement: SkillPlacement?
    /// Which rewards were already celebrated; `nil` before the first one.
    var skillProgress: SkillProgress?
    /// `nil` while the implicit default goal applies (nothing saved).
    var weeklyGoal: WeeklyGoalHistory?

    init(workoutLog: [WorkoutLogEntry] = [],
         workoutPlans: [WorkoutPlan] = [],
         placement: SkillPlacement? = nil,
         skillProgress: SkillProgress? = nil,
         weeklyGoal: WeeklyGoalHistory? = nil) {
        self.workoutLog = workoutLog
        self.workoutPlans = workoutPlans
        self.placement = placement
        self.skillProgress = skillProgress
        self.weeklyGoal = weeklyGoal
    }

    /// Counts for the import confirmation and the export screen.
    var summary: TrainingBackupSummary {
        TrainingBackupSummary(
            workouts: WorkoutSession.grouped(from: workoutLog).count,
            plans: workoutPlans.count,
            hasPlacement: placement != nil,
            hasWeeklyGoal: weeklyGoal.map { !$0.versions.isEmpty } ?? false
        )
    }
}

// MARK: - TrainingBackupSummary
/// What a backup holds, in words: "142 treningi, 3 plany, test poziomu".
struct TrainingBackupSummary: Equatable, Sendable {
    let workouts: Int
    let plans: Int
    let hasPlacement: Bool
    let hasWeeklyGoal: Bool

    var isEmpty: Bool { workouts == 0 && plans == 0 && !hasPlacement && !hasWeeklyGoal }

    /// "142 treningi, 3 plany, test poziomu, cel tygodniowy".
    var text: String {
        var parts = [PolishPlural.workouts(workouts), PolishPlural.plans(plans)]
        if hasPlacement { parts.append("test poziomu") }
        if hasWeeklyGoal { parts.append("cel tygodniowy") }
        return parts.joined(separator: ", ")
    }
}
