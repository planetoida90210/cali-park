import Foundation
import Observation

// MARK: - HomeDashboardViewModel
/// Feeds the Home modules (last workout, streak, next workout, hero card) from
/// the app's `TrainingJournal` and `ProgressService`, so a workout saved on
/// any tab shows here without a reload. `reload()` re-reads the plans. The
/// derived state is one `HomeSnapshot`, cached per change. The sheets Home
/// opens get their view models from `AppEnvironment`.
///
/// Everything "today"-relative (hero, streak, next plan, weekly count) reads
/// the cached `now`, which only moves on `reload()`. The view reloads when the
/// scene becomes active and when the calendar day changes, so Home never keeps
/// showing yesterday's state while the app sat in memory overnight.
@MainActor
@Observable
final class HomeDashboardViewModel {
    // MARK: State
    /// Saved workout plans, used to surface the next scheduled workout.
    private(set) var plans: [WorkoutPlan] = [] {
        didSet { if plans != oldValue { plansRevision += 1 } }
    }
    /// Grows whenever `plans` changes, to key the snapshot.
    private var plansRevision = 0
    /// The last snapshot and what it was computed for.
    @ObservationIgnored private var cache: (key: SnapshotKey, snapshot: HomeSnapshot)?
    /// How many snapshots were computed; tests check it stays one per change.
    @ObservationIgnored private(set) var snapshotComputationCount = 0
    /// Set when a store fails to load, for the Home alert.
    var errorMessage: String?
    /// Whether the plans failed to load on the last reload.
    private var plansFailed = false
    /// Whether the Planner's "Czas na Fundamenty" card was dismissed or used,
    /// re-read on `reload()` (Home reappears after the Planner).
    private var hasDismissedGraduation = false
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

    private struct SnapshotKey: Equatable {
        let journal: Int
        let plans: Int
        let progress: Int
        let day: Date
    }

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
    /// Holds the "Czas na Fundamenty" dismissal flag, shared with the Planner.
    private let defaults: UserDefaults

    // MARK: Init
    /// Reads nothing: `HomeView` builds this in its `init`, which SwiftUI may
    /// run many times, so the view calls `reload()` on appear instead (D-6).
    init(journal: TrainingJournal,
         planService: WorkoutPlanService,
         progress: ProgressService,
         goals: WeeklyGoalService,
         defaults: UserDefaults,
         calendar: Calendar = .current,
         clock: @escaping () -> Date = { .now }) {
        self.journal = journal
        self.planService = planService
        self.progress = progress
        self.goals = goals
        self.defaults = defaults
        self.calendar = calendar
        self.clock = clock
        self.now = clock()
    }

    // MARK: Intentions
    /// Re-reads the plans, retries whatever failed to load, and moves `now`
    /// to the current time.
    func reload() {
        now = clock()
        hasDismissedGraduation = defaults.bool(forKey: DefaultsKey.hasDismissedFundamentalsHint.rawValue)
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

    // MARK: Snapshot
    /// Everything Home derives from the journal, the plans and progress, for
    /// `now`'s day. Computed once per journal revision, plans change, progress
    /// revision and day (B-14), not on every render. Reading it in a view body
    /// tracks all of those, so a save anywhere refreshes Home.
    var snapshot: HomeSnapshot {
        let key = SnapshotKey(journal: journal.revision,
                              plans: plansRevision,
                              progress: progress.revision,
                              day: calendar.startOfDay(for: now))
        if let cache, cache.key == key { return cache.snapshot }
        let snapshot = HomeEngine.snapshot(entries: journal.newestFirst,
                                           plans: plans,
                                           progress: progress.snapshot,
                                           calendar: calendar,
                                           today: now)
        cache = (key, snapshot)
        snapshotComputationCount += 1
        return snapshot
    }

    /// The most recent workout for the "Ostatni trening" module.
    var latestWorkout: WorkoutSession? { snapshot.latestWorkout }

    /// The day streak for the "Seria dni" module.
    var streak: WorkoutStreak { snapshot.streak }

    /// Level, XP, badges and the last conquered rung, from the shared progress.
    var achievementsSummary: HomeAchievementsSummary { snapshot.achievements }

    /// A one-line progression nudge for the hero's rest-day / free-training
    /// states ("Jeszcze 2 powtórzenia do 3 × 8 — następny szczebel: …"), or
    /// `nil` when no rung is partway done.
    var progressionHint: String? { snapshot.progressionHint }

    /// The plan the Planner's "Czas na Fundamenty" card is about, while that
    /// card would show (ready to move on, not dismissed). Home's hint slot
    /// then leads to the plans instead of the progression nudge.
    var graduationCandidate: WorkoutPlan? {
        hasDismissedGraduation ? nil : snapshot.graduationCandidate
    }

    /// What the "Następny trening" module shows.
    var nextWorkoutState: NextWorkoutState { snapshot.nextWorkout }

    /// The hero state for the cached `now`.
    func heroState() -> HomeHeroState { snapshot.hero }

    /// The next plan that still needs doing, or `nil` when no plan is
    /// scheduled. A plan already done today moves to its next scheduled day.
    var nextPlannedWorkout: PlanAgenda.Occurrence? {
        nextPlannedWorkout(asOf: now)
    }

    // MARK: Explicit dates
    // The same answers for any reference date, computed on the spot; tests
    // use them to pin the day.

    func streak(asOf reference: Date) -> WorkoutStreak {
        HomeEngine.streak(entries: journal.newestFirst, calendar: calendar, today: reference)
    }

    func nextPlannedWorkout(asOf reference: Date) -> PlanAgenda.Occurrence? {
        PlanAgenda.nextUndone(plans: plans, entries: journal.newestFirst, calendar: calendar, today: reference)
    }

    func nextWorkoutState(asOf reference: Date) -> NextWorkoutState {
        HomeEngine.nextWorkoutState(entries: journal.newestFirst, plans: plans, calendar: calendar, today: reference)
    }

    func heroState(asOf reference: Date) -> HomeHeroState {
        HomeEngine.heroState(entries: journal.newestFirst, plans: plans, calendar: calendar, today: reference)
    }
}
