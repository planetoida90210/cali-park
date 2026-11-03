import Foundation
import os

// MARK: - ReminderSyncResult
/// Whether the pending reminders now match the saved plans.
enum ReminderSyncResult: Equatable, Sendable {
    case synced
    /// The plans could not be read, or some reminders could not be scheduled.
    /// Pending reminders are left as they were rather than wiped.
    case failed
}

// MARK: - WorkoutPlanService
/// The one owner of plan changes: view models save and delete plans through
/// it, and it re-syncs local reminders after every change. `syncReminders()`
/// also runs on launch and on foreground, to repair drift (an interval plan's
/// dated reminders running out, a permission granted in Settings, a missed
/// reschedule).
///
/// Every sync reads the plans from the store when it runs, and syncs run one
/// after another, so the last one always reflects the latest saved state.
@MainActor
final class WorkoutPlanService {
    private let store: WorkoutPlanStoring
    private let scheduler: WorkoutReminderScheduling
    private let logger = AppLog.logger(category: "WorkoutPlanService")
    /// The latest queued sync; the next one waits for it.
    private var lastSync: Task<ReminderSyncResult, Never>?

    init(store: WorkoutPlanStoring, scheduler: WorkoutReminderScheduling) {
        self.store = store
        self.scheduler = scheduler
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

    /// Rebuilds the pending reminders from the saved plans. Never prompts for
    /// permission. When the plans can't be read it leaves reminders alone, so
    /// a broken file never cancels them.
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
        let plans: [WorkoutPlan]
        do {
            plans = try store.load()
        } catch {
            logger.error("Reminders not synced, plans unreadable: \(error.localizedDescription, privacy: .public)")
            return .failed
        }
        do {
            try await scheduler.reschedule(for: plans)
            return .synced
        } catch {
            logger.error("Reminders not synced: \(String(describing: error), privacy: .public)")
            return .failed
        }
    }
}
