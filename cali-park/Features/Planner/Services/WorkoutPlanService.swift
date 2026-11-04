import Foundation
import os

// MARK: - ReminderSyncResult
/// Whether the pending reminders now match the saved plans.
nonisolated enum ReminderSyncResult: Equatable, Sendable {
    case synced
    /// The plans could not be read, or some reminders could not be scheduled.
    /// Pending reminders are left as they were rather than wiped.
    case failed
}

// MARK: - WorkoutPlanService
/// The one owner of plan changes: view models save and delete plans through
/// it, and it re-syncs local reminders after every change. `syncReminders()`
/// also runs on launch, on foreground, in a background app refresh and after
/// every workout log change, to keep the dated reminders topped up, drop the
/// one for a plan just done today, and repair drift (a permission granted in
/// Settings, a missed reschedule).
///
/// Every sync reads the plans and the log entries when it runs, and syncs run
/// one after another, so the last one always reflects the latest saved state.
/// In the app the entries come from the `TrainingJournal` in memory, so a
/// sync never decodes the whole log file again (audit D-7).
@MainActor
final class WorkoutPlanService {
    private let store: WorkoutPlanStoring
    /// The saved log entries; throws when the log can't be read.
    private let logEntries: @MainActor () throws -> [WorkoutLogEntry]
    private let scheduler: WorkoutReminderScheduling
    private let refreshScheduler: ReminderRefreshScheduling
    private let logger = AppLog.logger(category: "WorkoutPlanService")
    /// The latest queued sync; the next one waits for it.
    private var lastSync: Task<ReminderSyncResult, Never>?

    /// `logEntries` is only read, to skip reminders on days a plan is done.
    init(store: WorkoutPlanStoring,
         logEntries: @escaping @MainActor () throws -> [WorkoutLogEntry],
         scheduler: WorkoutReminderScheduling,
         refreshScheduler: ReminderRefreshScheduling) {
        self.store = store
        self.logEntries = logEntries
        self.scheduler = scheduler
        self.refreshScheduler = refreshScheduler
    }

    /// Reads the entries from the log store itself on every sync.
    convenience init(store: WorkoutPlanStoring,
                     logStore: WorkoutLogStoring,
                     scheduler: WorkoutReminderScheduling,
                     refreshScheduler: ReminderRefreshScheduling) {
        self.init(store: store, logEntries: { try logStore.load() },
                  scheduler: scheduler, refreshScheduler: refreshScheduler)
    }

    // MARK: Plans

    /// Every saved plan. Throws when saved plans exist but cannot be read.
    func loadPlans() throws -> [WorkoutPlan] {
        try store.load()
    }

    /// Inserts or replaces the plan, then re-syncs reminders. Throws only when
    /// the plan was not saved; a reminder failure is the returned result.
    @discardableResult
    func save(_ plan: WorkoutPlan) async throws -> ReminderSyncResult {
        try store.save(plan)
        return await syncReminders()
    }

    /// Removes the plan, then re-syncs reminders so its reminders go too.
    /// Throws only when the plan was not deleted.
    @discardableResult
    func delete(id: UUID) async throws -> ReminderSyncResult {
        try store.delete(id: id)
        return await syncReminders()
    }

    // MARK: Reminders

    /// Rebuilds the pending reminders from the saved plans and the workout
    /// log, then asks for the next background refresh. Never prompts for
    /// permission. When the plans can't be read it leaves reminders alone, so
    /// a broken file never cancels them. When the log can't be read it
    /// schedules as if nothing were done: a reminder too many beats none.
    @discardableResult
    func syncReminders() async -> ReminderSyncResult {
        let previous = lastSync
        let run = Task { [weak self] () -> ReminderSyncResult in
            _ = await previous?.value
            guard let self else { return .failed }
            return await self.performSync()
        }
        lastSync = run
        return await run.value
    }

    func reminderAuthorizationStatus() async -> ReminderAuthorizationStatus {
        await scheduler.authorizationStatus()
    }

    /// Asks for notification permission (the system prompts only once).
    func requestReminderAuthorization() async -> Bool {
        await scheduler.requestAuthorization()
    }

    private func performSync() async -> ReminderSyncResult {
        defer { refreshScheduler.scheduleNextRefresh() }

        let plans: [WorkoutPlan]
        do {
            plans = try store.load()
        } catch {
            logger.error("Reminders not synced, plans unreadable: \(error.localizedDescription, privacy: .public)")
            return .failed
        }
        let entries: [WorkoutLogEntry]
        do {
            entries = try logEntries()
        } catch {
            logger.error("Workout log unreadable, reminders scheduled as if nothing were done: \(error.localizedDescription, privacy: .public)")
            entries = []
        }
        do {
            try await scheduler.reschedule(for: plans, entries: entries)
            return .synced
        } catch {
            logger.error("Reminders not synced: \(String(describing: error), privacy: .public)")
            return .failed
        }
    }
}
