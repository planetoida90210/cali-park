import Foundation
import Observation

// MARK: - HomeDashboardViewModel
/// Feeds the Home modules (Quick Log, streak, next workout, hero card) from
/// the app's `TrainingJournal` and `ProgressService`, so a workout saved on
/// any tab shows here without a reload. `reload()` re-reads the plans.
///
/// Everything "today"-relative (hero, streak, next plan, weekly count) reads
/// the cached `now`, which only moves on `reload()`. The view reloads when the
/// scene becomes active and when the calendar day changes, so Home never keeps
/// showing yesterday's state while the app sat in memory overnight.
@MainActor
@Observable
final class HomeDashboardViewModel {
    // MARK: State
    /// Every logged entry, newest first.
    var entries: [WorkoutLogEntry] { journal.newestFirst }
    /// Saved workout plans, used to surface the next scheduled workout.
    private(set) var plans: [WorkoutPlan] = []
    /// Set when a store fails to load, for the Home alert.
    var errorMessage: String?
    /// Whether the plans failed to load on the last reload.
    private var plansFailed = false
    /// Whether any store failed to load. Data that did load is shown; the
    /// rest keeps its previous value (empty on first load).
    var hasLoadError: Bool { plansFailed || goals.loadFailure != nil || progress.hasLoadError }
    /// Whether the current failure streak was already announced.
    @ObservationIgnored private var hasAlertedLoadError = false
    /// The reference instant for every "today" question, refreshed by
    /// `reload()` from the injected clock. Observed, so moving it re-renders
    /// Home even when no data changed (e.g. after midnight).
    private(set) var now: Date
    /// The weekly goal: current week, week streak, pause and pending
    /// celebrations. `nil` while the goal store cannot be read, so Home never
    /// shows the default goal in place of a saved one. A met goal celebrates
    /// through the app-wide `RewardCenter`.
    var weeklyGoal: WeeklyGoalSnapshot? { goals.snapshot }

    // MARK: Dependencies
    private let journal: TrainingJournal
    /// Reads plans and owns saving them (with their reminders).
    private let planService: WorkoutPlanService
    /// Level, badges, the last advancement and the hint, shared with Skills.
    private let progress: ProgressService
    /// The weekly goal, shared with the reward overlay.
    private let goals: WeeklyGoalService
    let calendar: Calendar
    /// Wall-clock source; tests inject a controllable one.
    private let clock: () -> Date

    // MARK: Init
    /// Reads nothing: `HomeView` builds this in its `init`, which SwiftUI may
    /// run many times, so the view calls `reload()` on appear instead (D-6).
    init(journal: TrainingJournal,
         planService: WorkoutPlanService,
         progress: ProgressService,
         goals: WeeklyGoalService,
         calendar: Calendar = .current,
         clock: @escaping () -> Date = { .now }) {
        self.journal = journal
        self.planService = planService
        self.progress = progress
        self.goals = goals
        self.calendar = calendar
        self.clock = clock
        self.now = clock()
    }

    // MARK: Intentions
    /// Re-reads the plans, retries whatever failed to load, and moves `now`
    /// to the current time.
    func reload() {
        now = clock()
        progress.reloadIfFailed()
        do {
            plans = try planService.loadPlans()
            plansFailed = false
        } catch {
            plansFailed = true
        }
        goals.reload()
        // Alert once per failure streak, not on every appear.
        if hasLoadError, !hasAlertedLoadError { errorMessage = StoreLoadFailure.message }
        hasAlertedLoadError = hasLoadError
    }

    /// SetPad session for logging straight from Home (Quick Log).
    func makeWorkoutLogViewModel(exercise: Exercise) -> WorkoutLogViewModel {
        WorkoutLogViewModel(exercise: exercise, journal: journal)
    }

    /// Quick workout session started from Home (Quick Log).
    func makeQuickWorkoutViewModel() -> QuickWorkoutViewModel {
        QuickWorkoutViewModel(journal: journal)
    }

    /// Quick workout session seeded with a plan's exercises; the user confirms
    /// each exercise's sets on the SetPad before finishing. Items from a
    /// program follow the athlete's current rung. When a store failed to
    /// load, the ladder state is unknown, so items keep their stored exercise.
    func makeQuickWorkoutViewModel(plan: WorkoutPlan) -> QuickWorkoutViewModel {
        let pathStates = hasLoadError ? nil : progress.snapshot.pathStates
        return QuickWorkoutViewModel(journal: journal, plan: plan, pathStates: pathStates, logs: entries)
    }

    /// Detail screen for a workout opened from the "Ostatni trening" card.
    func makeWorkoutSessionDetailViewModel(sessionID: UUID) -> WorkoutSessionDetailViewModel {
        WorkoutSessionDetailViewModel(sessionID: sessionID, journal: journal)
    }

    /// Editor for a brand-new plan, started straight from Home when nothing is
    /// scheduled yet ("Zaplanuj trening").
    func makePlanEditorViewModel() -> PlanEditorViewModel {
        PlanEditorViewModel(plan: nil, service: planService, calendar: calendar)
    }

    // MARK: Last workout
    func exercise(for entry: WorkoutLogEntry) -> Exercise? {
        ExerciseCatalog.exercise(withID: entry.exerciseID)
    }

    /// The most recent workout for the Home preview: a whole session when the
    /// latest entry belongs to one, otherwise the single standalone entry.
    var latestWorkout: WorkoutSession? {
        WorkoutSession.latest(in: entries)
    }

    // MARK: Streak
    var streak: WorkoutStreak {
        streak(asOf: now)
    }

    /// Testable core of `streak` with an explicit reference date, computed on
    /// the injected calendar so streak math is deterministic in tests.
    func streak(asOf reference: Date) -> WorkoutStreak {
        WorkoutStreak.compute(from: entries.map(\.date), calendar: calendar, today: reference)
    }

    // MARK: Skills bridge
    /// Real achievements for the Home module: level, XP to the next level, badge
    /// count, and the most recent conquered rung — all from logs, so Home mirrors
    /// the Skills tab. Declarations grant nothing here.
    var achievementsSummary: HomeAchievementsSummary {
        let snapshot = progress.snapshot
        let level = snapshot.level
        let badges = snapshot.badges
        let advancement = snapshot.lastAdvancement.flatMap(resolveAdvancement)
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
    /// `nil` when no rung is partway done. Uses the placement as a floor, like
    /// the Skills tab, from the same shared snapshot.
    var progressionHint: String? {
        progress.snapshot.hint.flatMap(ProgressionFormat.hintLine)
    }

    /// Resolves a rung reference into display names from the catalogs.
    private func resolveAdvancement(_ reference: RungReference) -> HomeAchievementsSummary.Advancement? {
        guard let path = ProgressionCatalog.path(withID: reference.pathID),
              let step = reference.step,
              let exercise = ExerciseCatalog.exercise(withID: step.exerciseID)
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
    typealias PlannedWorkout = PlanAgenda.Occurrence

    /// The next plan that still needs doing, or `nil` when no plan is
    /// scheduled. A plan already done today moves to its next scheduled day,
    /// so a second plan due today becomes reachable. Ties break on creation
    /// order for a stable result.
    var nextPlannedWorkout: PlannedWorkout? {
        nextPlannedWorkout(asOf: now)
    }

    /// Testable core of `nextPlannedWorkout` with an explicit reference date.
    func nextPlannedWorkout(asOf reference: Date) -> PlannedWorkout? {
        PlanAgenda.nextUndone(plans: plans, entries: entries, calendar: calendar, today: reference)
    }

    /// The plans due on `reference`'s day, split by whether they are done.
    func plansToday(asOf reference: Date) -> PlanAgenda.Day {
        PlanAgenda.day(reference, plans: plans, entries: entries, calendar: calendar)
    }

    // MARK: Next workout module
    /// What the "Następny trening" module shows.
    enum NextWorkoutState: Equatable {
        /// A plan to start: the first undone plan due today, else the next
        /// scheduled one.
        case planned(PlannedWorkout)
        /// Every plan due today is done. `next` is the following plan, if any,
        /// shown for information only (no start button, so today's plan is
        /// not logged twice by accident).
        case doneToday(plans: [WorkoutPlan], next: PlannedWorkout?)
        /// No plans: the untrained-group suggestion.
        case suggestion(Exercise)
        /// Nothing to suggest yet.
        case empty
    }

    var nextWorkoutState: NextWorkoutState {
        nextWorkoutState(asOf: now)
    }

    /// Testable core of `nextWorkoutState` with an explicit reference date.
    func nextWorkoutState(asOf reference: Date) -> NextWorkoutState {
        let today = plansToday(asOf: reference)
        let next = nextPlannedWorkout(asOf: reference)
        if today.isAllDone {
            return .doneToday(plans: today.due, next: next)
        }
        if let next {
            return .planned(next)
        }
        if let suggestion = suggestedExercise {
            return .suggestion(suggestion)
        }
        return .empty
    }

    // MARK: Hero state
    /// The hero state for the cached `now`.
    func heroState() -> HomeHeroState {
        heroState(asOf: now)
    }

    /// The contextual hero state for `reference`'s day, resolved from logs and
    /// plans. Pure and deterministic given the injected `calendar` and the
    /// explicit date, so it can be exhaustively tested. Decision tree: an
    /// undone plan today → trained today (every plan due today done, or a
    /// free workout)? → any plan ahead? → empty journal?
    func heroState(asOf reference: Date) -> HomeHeroState {
        let entriesToday = entries.filter { calendar.isDate($0.date, inSameDayAs: reference) }

        // Q1 — is a plan due today and not done yet? Offer the first one.
        if let planToday = plansToday(asOf: reference).undone.first {
            // Holds count too: a hold-only start is still a start (B-12).
            return .planToday(
                plan: planToday,
                loggedTodayReps: entriesToday.reduce(0) { $0 + $1.totalReps },
                loggedTodaySeconds: entriesToday.reduce(0) { $0 + $1.totalSeconds }
            )
        }

        // Q2 — every plan due today is done, or we trained without a plan.
        // A done plan always has an entry today, so this covers both.
        if !entriesToday.isEmpty {
            return completedTodayState(asOf: reference)
        }

        // Q3 — nothing today; is any plan scheduled at all?
        if let planned = nextPlannedWorkout(asOf: reference) {
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
