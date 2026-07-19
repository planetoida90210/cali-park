import Foundation
import Observation

// MARK: - HomeDashboardViewModel
/// Feeds the Home modules (Quick Log, streak, next workout, hero card) from
/// the same `WorkoutLogStoring` the Exercises tab writes to. Reload on appear
/// picks up entries saved while another tab was active.
@MainActor
@Observable
final class HomeDashboardViewModel {
    // MARK: State
    private(set) var entries: [WorkoutLogEntry] = []
    /// Saved workout plans, used to surface the next scheduled workout.
    private(set) var plans: [WorkoutPlan] = []
    /// The athlete's declared placement, cached on reload so the achievements
    /// module and hero hint read it without touching disk on every render.
    private var placement: SkillPlacement?

    // MARK: Dependencies
    private let store: WorkoutLogStoring
    private let planStore: WorkoutPlanStoring
    private let placementStore: PlacementStoring
    private let calendar: Calendar

    // MARK: Init
    init(store: WorkoutLogStoring,
         planStore: WorkoutPlanStoring,
         placementStore: PlacementStoring = InMemorySkillPlacementStore(),
         calendar: Calendar = .current) {
        self.store = store
        self.planStore = planStore
        self.placementStore = placementStore
        self.calendar = calendar
        reload()
    }

    // MARK: Intentions
    func reload() {
        entries = store.load().sorted { $0.date > $1.date }
        plans = planStore.load()
        placement = placementStore.load()
    }

    /// SetPad session for logging straight from Home (Quick Log).
    func makeWorkoutLogViewModel(exercise: Exercise) -> WorkoutLogViewModel {
        WorkoutLogViewModel(exercise: exercise, store: store)
    }

    /// Quick workout session started from Home (Quick Log).
    func makeQuickWorkoutViewModel() -> QuickWorkoutViewModel {
        QuickWorkoutViewModel(store: store)
    }

    /// Quick workout session seeded with a plan's exercises; the user confirms
    /// each exercise's sets on the SetPad before finishing.
    func makeQuickWorkoutViewModel(plan: WorkoutPlan) -> QuickWorkoutViewModel {
        QuickWorkoutViewModel(store: store, plan: plan)
    }

    /// Editor for a brand-new plan, started straight from Home when nothing is
    /// scheduled yet ("Zaplanuj trening").
    func makePlanEditorViewModel() -> PlanEditorViewModel {
        PlanEditorViewModel(plan: nil, store: planStore)
    }

    // MARK: Last workout
    var latestEntry: WorkoutLogEntry? {
        entries.first
    }

    func exercise(for entry: WorkoutLogEntry) -> Exercise? {
        ExerciseCatalog.exercise(withID: entry.exerciseID)
    }

    /// The most recent workout for the Home preview: a whole session when the
    /// latest entry belongs to one, otherwise the single standalone entry.
    struct LatestWorkout: Equatable {
        let date: Date
        let entries: [WorkoutLogEntry]

        var isSession: Bool { entries.count > 1 }
        var totalReps: Int { entries.reduce(0) { $0 + $1.totalReps } }
        var totalSeconds: Int { entries.reduce(0) { $0 + $1.totalSeconds } }
    }

    var latestWorkout: LatestWorkout? {
        guard let latest = entries.first else { return nil }

        if let sessionID = latest.sessionID {
            let sessionEntries = entries.filter { $0.sessionID == sessionID }
            return LatestWorkout(
                date: sessionEntries.map(\.date).max() ?? latest.date,
                entries: sessionEntries
            )
        }

        return LatestWorkout(date: latest.date, entries: [latest])
    }

    /// The exercise Quick Log should open: the last logged one,
    /// falling back to pull-ups for a fresh journal.
    var quickLogExercise: Exercise {
        if let latestEntry, let exercise = exercise(for: latestEntry) {
            return exercise
        }
        return ExerciseCatalog.exercise(withID: ExerciseCatalog.pullUpsID) ?? ExerciseCatalog.all[0]
    }

    // MARK: Streak
    var streak: WorkoutStreak {
        streak(asOf: .now)
    }

    /// Testable core of `streak` with an explicit reference date, computed on
    /// the injected calendar so streak math is deterministic in tests.
    func streak(asOf reference: Date) -> WorkoutStreak {
        WorkoutStreak.compute(from: entries.map(\.date), calendar: calendar, today: reference)
    }

    // MARK: Hero card
    /// Pull-up reps logged in the current calendar week.
    var weeklyPullUps: Int {
        guard let week = Calendar.current.dateInterval(of: .weekOfYear, for: .now) else { return 0 }
        return entries
            .filter { $0.exerciseID == ExerciseCatalog.pullUpsID && week.contains($0.date) }
            .reduce(0) { $0 + $1.totalReps }
    }

    // MARK: Skills bridge
    /// Real achievements for the Home module: level, XP to the next level, badge
    /// count, and the most recent conquered rung — all from logs, so Home mirrors
    /// the Skills tab. Declarations grant nothing here.
    var achievementsSummary: HomeAchievementsSummary {
        let level = ProgressionEngine.playerLevel(for: entries)
        let badges = ProgressionEngine.earnedBadges(from: entries, calendar: calendar)
        let advancement = ProgressionEngine.lastAdvancement(from: entries)
            .flatMap(resolveAdvancement)
        return HomeAchievementsSummary(
            level: level.level,
            xpToNextLevel: level.xpToNextLevel,
            progressToNextLevel: level.progressToNextLevel,
            earnedBadgeCount: badges.count,
            totalBadgeCount: Badge.allCases.count,
            lastAdvancement: advancement
        )
    }

    /// A one-line progression nudge for the hero's rest-day / free-training
    /// states ("Jeszcze 2 powtórzenia do 3 × 8 — następny szczebel: …"), or
    /// `nil` when no rung is partway done. Uses the cached placement as a floor,
    /// like the Skills tab.
    var progressionHint: String? {
        ProgressionEngine.mostActionableHint(logs: entries, placement: placement)
            .flatMap(ProgressionFormat.hintLine)
    }

    /// Resolves a rung reference into display names from the catalogs.
    private func resolveAdvancement(_ reference: RungReference) -> HomeAchievementsSummary.Advancement? {
        guard let path = ProgressionCatalog.path(withID: reference.pathID),
              reference.rungIndex < path.steps.count,
              let exercise = ExerciseCatalog.exercise(withID: path.steps[reference.rungIndex].exerciseID)
        else { return nil }
        return HomeAchievementsSummary.Advancement(
            title: exercise.name,
            pathName: path.name,
            symbolName: path.symbolName
        )
    }

    // MARK: Next workout
    /// Heuristic suggestion: the muscle group that has gone untrained the
    /// longest (never-trained groups win), represented by a basic catalog
    /// exercise. `nil` until the journal has at least one entry.
    var suggestedExercise: Exercise? {
        guard !entries.isEmpty else { return nil }

        var lastTrained: [MuscleGroup: Date] = [:]
        for entry in entries {
            guard let exercise = exercise(for: entry) else { continue }
            for group in exercise.muscleGroups {
                lastTrained[group] = max(lastTrained[group] ?? .distantPast, entry.date)
            }
        }

        let staleGroups = MuscleGroup.allCases.sorted {
            (lastTrained[$0] ?? .distantPast) < (lastTrained[$1] ?? .distantPast)
        }

        for group in staleGroups {
            // Prefer a basic exercise that targets the group primarily.
            if let match = ExerciseCatalog.all.first(where: {
                $0.category == .basic && $0.muscleGroups.first == group
            }) {
                return match
            }
            if let match = ExerciseCatalog.all.first(where: {
                $0.category == .basic && $0.muscleGroups.contains(group)
            }) {
                return match
            }
        }
        return nil
    }

    // MARK: Next planned workout
    /// The soonest scheduled workout: an active plan paired with its next day.
    struct PlannedWorkout: Equatable {
        let plan: WorkoutPlan
        let date: Date
    }

    /// The active plan whose next occurrence is soonest, or `nil` when no plan
    /// is scheduled. Ties break on creation order for a stable result.
    var nextPlannedWorkout: PlannedWorkout? {
        nextPlannedWorkout(asOf: .now)
    }

    /// Testable core of `nextPlannedWorkout` with an explicit reference date.
    func nextPlannedWorkout(asOf reference: Date) -> PlannedWorkout? {
        plans
            .compactMap { plan -> PlannedWorkout? in
                guard let date = plan.nextOccurrence(onOrAfter: reference, calendar: calendar) else { return nil }
                return PlannedWorkout(plan: plan, date: date)
            }
            .min {
                $0.date != $1.date ? $0.date < $1.date : $0.plan.createdAt < $1.plan.createdAt
            }
    }

    // MARK: Hero state
    /// The contextual hero state for `reference`'s day, resolved from logs and
    /// plans. Pure and deterministic given the injected `calendar` and the
    /// explicit date, so it can be exhaustively tested. Mirrors the decision
    /// tree in the plan: plan today → done? → trained today? → any plan? →
    /// empty journal?
    func heroState(asOf reference: Date = .now) -> HomeHeroState {
        let entriesToday = entries.filter { calendar.isDate($0.date, inSameDayAs: reference) }
        let planned = nextPlannedWorkout(asOf: reference)
        let planToday = planned.flatMap { calendar.isDate($0.date, inSameDayAs: reference) ? $0.plan : nil }

        // Q1 — is a plan scheduled for today?
        if let planToday {
            let planDoneToday = entriesToday.contains { $0.planID == planToday.id }
            if planDoneToday {
                return completedTodayState(asOf: reference)
            }
            let loggedTodayReps = entriesToday.reduce(0) { $0 + $1.totalReps }
            return .planToday(plan: planToday, loggedTodayReps: loggedTodayReps)
        }

        // Q2 — no plan today, but did we log a workout today anyway?
        if !entriesToday.isEmpty {
            return completedTodayState(asOf: reference)
        }

        // Q3 — nothing today; is any plan scheduled at all?
        if let planned {
            return .restDay(nextPlan: planned.plan, date: planned.date, streak: streak(asOf: reference))
        }

        // Q4 — no plans; does the journal hold any history?
        if let lastWorkout = latestWorkout {
            return .freeMode(lastWorkout: lastWorkout, suggestion: suggestedExercise, streak: streak(asOf: reference))
        }

        return .firstRun
    }

    /// Builds the "done today" state, falling back to `firstRun` only in the
    /// impossible case of a completed day with no recoverable summary.
    private func completedTodayState(asOf reference: Date) -> HomeHeroState {
        guard let lastWorkout = latestWorkout else { return .firstRun }
        return .completedToday(summary: lastWorkout, streak: streak(asOf: reference))
    }
}
