import Foundation
import Observation
import os

// MARK: - WeeklyGoalService
/// The app's one view of the weekly goal: the current week, the week streak,
/// the pause, and the met goals still to celebrate. Shared by Home (hero ring,
/// "Cel tygodniowy") and the app-wide `RewardCenter`, which shows a met goal
/// in the same overlay queue as conquered rungs.
///
/// The snapshot is `WeeklyGoalEvaluator.snapshot(...)`, recomputed once per
/// journal revision or `reload()`, from the journal's entries (never the raw
/// log store), the saved goal history and the plans.
@MainActor
@Observable
final class WeeklyGoalService {
    // MARK: State
    /// The saved history; `nil` while it cannot be read, so the default goal is
    /// never shown in place of a saved one.
    private(set) var history: WeeklyGoalHistory?
    /// Why the history could not be read; `nil` when it was.
    private(set) var loadFailure: StoreLoadFailure?
    /// The plans, for the "all scheduled" goal. Kept as last read on failure.
    private var plans: [WorkoutPlan] = []
    /// The reference instant, moved by `reload()` and by every journal change.
    private var now: Date
    /// Grows on every `reload()`.
    private var inputsRevision = 0
    /// Goals whose celebration was dismissed while the mark could not be saved,
    /// so a failed write does not bring the overlay straight back.
    private var dismissed: Set<WeeklyGoalCelebration> = []
    @ObservationIgnored private var cache: (key: Key, snapshot: WeeklyGoalSnapshot)?

    // MARK: Dependencies
    private let journal: TrainingJournal
    private let store: WeeklyGoalStoring
    private let planService: WorkoutPlanService
    private let calendar: Calendar
    private let clock: () -> Date
    private let logger = AppLog.logger(category: "WeeklyGoalService")

    private struct Key: Equatable {
        let journal: Int
        let inputs: Int
        let now: Date
    }

    // MARK: Init
    init(
        journal: TrainingJournal,
        store: WeeklyGoalStoring,
        planService: WorkoutPlanService,
        calendar: Calendar = .current,
        clock: @escaping () -> Date = { .now }
    ) {
        self.journal = journal
        self.store = store
        self.planService = planService
        self.calendar = calendar
        self.clock = clock
        self.now = clock()
        reload()
        // A workout logged late on Sunday counts for the week it was logged in.
        journal.onChange { [weak self] in
            guard let self else { return }
            self.now = self.clock()
        }
        // Records the new schedules, so closed weeks keep the plans they had.
        planService.onPlansChange { [weak self] in
            self?.reload()
        }
    }

    // MARK: Output
    /// The weekly goal now, or `nil` while the history cannot be read.
    var snapshot: WeeklyGoalSnapshot? {
        guard let history else { return nil }
        let key = Key(journal: journal.revision, inputs: inputsRevision, now: now)
        if let cache, cache.key == key { return cache.snapshot }
        let snapshot = WeeklyGoalEvaluator.snapshot(
            history: history, entries: journal.entries, plans: plans, calendar: calendar, asOf: now
        )
        cache = (key, snapshot)
        return snapshot
    }

    /// The met goal to celebrate now, or `nil`. One at a time, primary first.
    var pendingCelebration: WeeklyGoalProgress? {
        remainingCelebrations.first
    }

    /// Whether another met goal waits behind `pendingCelebration`.
    var hasQueuedCelebrations: Bool {
        remainingCelebrations.count > 1
    }

    private var remainingCelebrations: [WeeklyGoalProgress] {
        guard let snapshot else { return [] }
        let weekStart = snapshot.week.interval.start
        return snapshot.pendingCelebrations.filter {
            !dismissed.contains(WeeklyGoalCelebration(weekStart: weekStart, goalID: $0.goal.id))
        }
    }

    // MARK: Intentions
    /// Re-reads the history and the plans and moves `now` to the current time.
    /// Call on appear, on return to the app, and after the editor saved.
    func reload() {
        now = clock()
        let loadedPlans = try? planService.loadPlans()
        if let loadedPlans { plans = loadedPlans }
        do {
            history = try store.load() ?? .empty
            loadFailure = nil
        } catch {
            logger.error("Weekly goal unreadable: \(String(describing: error), privacy: .public)")
            history = nil
            loadFailure = StoreLoadFailure(error)
        }
        if let loadedPlans { recordPlanSchedules(loadedPlans) }
        inputsRevision += 1
    }

    /// Saves the plans' schedules with the goal when they changed since the
    /// last record, so a closed week's "all scheduled" target keeps the plans
    /// of that week. Only with a readable history and plans; a failed write
    /// is logged and tried again on the next reload.
    private func recordPlanSchedules(_ plans: [WorkoutPlan]) {
        guard let history, let updated = history.recordingPlans(plans, at: now, calendar: calendar) else { return }
        do {
            try store.save(updated)
            self.history = updated
        } catch {
            logger.error("Cannot record plan schedules: \(String(describing: error), privacy: .public)")
        }
    }

    /// Records the celebration on screen as shown, so it plays once per goal
    /// per week. Re-reads the history first so a change saved elsewhere is
    /// kept; a failed write only means it may play again after a relaunch.
    func dismissCelebration() {
        guard let shown = pendingCelebration, let weekStart = snapshot?.week.interval.start else { return }
        dismissed.insert(WeeklyGoalCelebration(weekStart: weekStart, goalID: shown.goal.id))
        do {
            let saved = try store.load() ?? .empty
            try store.save(saved.markingCelebrated(goalID: shown.goal.id, weekStart: weekStart, calendar: calendar))
            reload()
        } catch {
            logger.error("Cannot mark goal celebration as shown: \(String(describing: error), privacy: .public)")
        }
    }
}
