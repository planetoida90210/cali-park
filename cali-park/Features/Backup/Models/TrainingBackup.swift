import Foundation

// MARK: - TrainingBackup
/// Everything the athlete owns in one value: the content of the export file
/// ("Eksport i import treningów" in Profile) and the unit an import replaces.
///
/// Favorite Parks and favorite exercises are included as IDs. Progress (level, streaks, rungs)
/// is never stored; it is recomputed from the log after an import.
nonisolated struct TrainingBackup: Equatable, Sendable {
    var workoutLog: [WorkoutLogEntry]
    var workoutPlans: [WorkoutPlan]
    /// `nil` when the athlete never took the level test.
    var placement: SkillPlacement?
    /// Which rewards were already celebrated; `nil` before the first one.
    var skillProgress: SkillProgress?
    /// `nil` while the implicit default goal applies (nothing saved).
    var weeklyGoal: WeeklyGoalHistory?
    /// Favorite Park IDs in the order they were added. `nil` only when the
    /// file was written before favorites existed: importing it then leaves the
    /// favorites on the phone as they are.
    var favoriteParkIDs: [UUID]?
    /// Favorite exercise IDs in the order they were added. `nil` only when
    /// the file was written before exercise favorites existed: importing it
    /// then leaves them on the phone as they are.
    var favoriteExerciseIDs: [UUID]?

    init(workoutLog: [WorkoutLogEntry] = [],
         workoutPlans: [WorkoutPlan] = [],
         placement: SkillPlacement? = nil,
         skillProgress: SkillProgress? = nil,
         weeklyGoal: WeeklyGoalHistory? = nil,
         favoriteParkIDs: [UUID]? = [],
         favoriteExerciseIDs: [UUID]? = []) {
        self.workoutLog = workoutLog
        self.workoutPlans = workoutPlans
        self.placement = placement
        self.skillProgress = skillProgress
        self.weeklyGoal = weeklyGoal
        self.favoriteParkIDs = favoriteParkIDs
        self.favoriteExerciseIDs = favoriteExerciseIDs
    }

    /// Counts for the import confirmation and the export screen.
    var summary: TrainingBackupSummary {
        TrainingBackupSummary(
            workouts: WorkoutSession.grouped(from: workoutLog).count,
            plans: workoutPlans.count,
            hasPlacement: placement != nil,
            hasWeeklyGoal: weeklyGoal.map { !$0.versions.isEmpty } ?? false,
            favoriteParks: favoriteParkIDs?.count ?? 0,
            favoriteExercises: favoriteExerciseIDs?.count ?? 0
        )
    }
}

// MARK: - TrainingBackupSummary
/// What a backup holds, in words: "142 treningi, 3 plany, test poziomu".
nonisolated struct TrainingBackupSummary: Equatable, Sendable {
    let workouts: Int
    let plans: Int
    let hasPlacement: Bool
    let hasWeeklyGoal: Bool
    let favoriteParks: Int
    let favoriteExercises: Int

    init(workouts: Int,
         plans: Int,
         hasPlacement: Bool,
         hasWeeklyGoal: Bool,
         favoriteParks: Int = 0,
         favoriteExercises: Int = 0) {
        self.workouts = workouts
        self.plans = plans
        self.hasPlacement = hasPlacement
        self.hasWeeklyGoal = hasWeeklyGoal
        self.favoriteParks = favoriteParks
        self.favoriteExercises = favoriteExercises
    }

    var isEmpty: Bool {
        workouts == 0 && plans == 0 && !hasPlacement && !hasWeeklyGoal && favoriteParks == 0 && favoriteExercises == 0
    }

    /// "142 treningi, 3 plany, test poziomu, cel tygodniowy, 2 ulubione Parki,
    /// 5 ulubionych ćwiczeń".
    var text: String {
        var parts = [PolishPlural.workouts(workouts), PolishPlural.plans(plans)]
        if hasPlacement { parts.append(String(localized: "test poziomu")) }
        if hasWeeklyGoal { parts.append(String(localized: "cel tygodniowy")) }
        if favoriteParks > 0 {
            let noun = PolishPlural.form(for: favoriteParks, one: "ulubiony Park", few: "ulubione Parki", many: "ulubionych Parków")
            parts.append("\(favoriteParks) \(noun)")
        }
        if favoriteExercises > 0 {
            let noun = PolishPlural.form(for: favoriteExercises,
                                         one: "ulubione ćwiczenie", few: "ulubione ćwiczenia", many: "ulubionych ćwiczeń")
            parts.append("\(favoriteExercises) \(noun)")
        }
        return parts.joined(separator: ", ")
    }
}
