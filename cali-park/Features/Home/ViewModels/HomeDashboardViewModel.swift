import Foundation
import Observation

// MARK: - HomeDashboardViewModel
/// Feeds the Home modules (last workout, streak, next workout, hero card) from
/// the app's `TrainingJournal` and `ProgressService`, so a workout saved on
/// any tab shows here without a reload. `reload()` re-reads the plans. The
/// derived state is one `HomeSnapshot`, computed once per change off the main
/// actor (see `snapshot`). The sheets Home opens get their view models from
/// `AppEnvironment`.
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
    /// The snapshot shown and what it was computed for. Not observed: the
    /// first one is stored while a view body reads it. Views track
    /// `publications` instead.
    @ObservationIgnored private var cache: (key: SnapshotKey, snapshot: HomeSnapshot)?
    /// Grows when a snapshot computed off the main actor lands, so the views
    /// that read `snapshot` render it.
    private var publications = 0
    /// The computation in flight and the inputs it is for.
    @ObservationIgnored private var pending: (key: SnapshotKey, task: Task<Void, Never>)?
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

    /// The inputs of a snapshot. The journal is keyed through progress: every
    /// journal change publishes a new progress snapshot, so keying on both
    /// would compute Home twice per save, once with the old progress.
    private struct SnapshotKey: Equatable {
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
    init(
        journal: TrainingJournal,
        planService: WorkoutPlanService,
        progress: ProgressService,
        goals: WeeklyGoalService,
        defaults: UserDefaults,
        calendar: Calendar = .current,
        clock: @escaping () -> Date = { .now }
    ) {
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
    /// `now`'s day. Computed once per progress revision (so once per journal
    /// change), plans change and day (B-14), not on every render. Reading it
    /// in a view body tracks all of those, so a save anywhere refreshes Home.
    ///
    /// `HomeEngine.snapshot` takes about 30 ms on a 10,000-entry journal, so
    /// after a change it runs off the main actor and this keeps returning the
    /// previous snapshot until the new one lands (a moment later, never an
    /// empty Home). Only the very first read computes on the spot: there is
    /// nothing earlier to show, and the journal is already loaded. The latest
    /// inputs win: a change cancels the computation in flight. Tests
    /// `await settle()`.
    var snapshot: HomeSnapshot {
        _ = publications
        let key = currentKey
        guard let cache else {
            let snapshot = currentInput().snapshot()
            cache = (key, snapshot)
            snapshotComputationCount += 1
            return snapshot
        }
        if cache.key == key {
            // Back to the inputs on screen: anything in flight is older.
            cancelPending()
        } else if pending?.key != key {
            startComputing(for: key)
        }
        return cache.snapshot
    }

    /// Waits until `snapshot` reflects every change made so far, progress
    /// included.
    func settle() async {
        await progress.settle()
        _ = snapshot
        while let pending { await pending.task.value }
    }

    private var currentKey: SnapshotKey {
        SnapshotKey(
            plans: plansRevision,
            progress: progress.revision,
            day: calendar.startOfDay(for: now))
    }

    private func currentInput() -> SnapshotInput {
        SnapshotInput(
            entries: journal.newestFirst, plans: plans, progress: progress.snapshot,
            calendar: calendar, today: now)
    }

    /// Computes the snapshot for `key` off the main actor and publishes it,
    /// unless newer inputs replaced it meanwhile. Called while a view body
    /// reads `snapshot`, so it changes no observed state until the result
    /// lands.
    private func startComputing(for key: SnapshotKey) {
        pending?.task.cancel()
        let input = currentInput()
        let task = Task { [weak self] in
            let snapshot = await Self.compute(input)
            guard let self, self.pending?.key == key, let snapshot else { return }
            self.pending = nil
            self.cache = (key, snapshot)
            self.snapshotComputationCount += 1
            self.publications += 1
        }
        pending = (key, task)
    }

    private func cancelPending() {
        pending?.task.cancel()
        pending = nil
    }

    /// `HomeEngine.snapshot` on the cooperative pool, or `nil` when newer
    /// inputs cancelled it before it started.
    @concurrent
    private nonisolated static func compute(_ input: SnapshotInput) async -> HomeSnapshot? {
        guard !Task.isCancelled else { return nil }
        return input.snapshot()
    }

    /// Everything a snapshot is computed from, copied off the main actor.
    private nonisolated struct SnapshotInput: Sendable {
        let entries: [WorkoutLogEntry]
        let plans: [WorkoutPlan]
        let progress: ProgressSnapshot
        let calendar: Calendar
        let today: Date

        func snapshot() -> HomeSnapshot {
            HomeEngine.snapshot(entries: entries, plans: plans, progress: progress, calendar: calendar, today: today)
        }
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
