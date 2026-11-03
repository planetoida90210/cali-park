import Foundation
import Observation

// MARK: - WorkoutPlansViewModel
/// Drives the "Plany treningowe" list: loads saved plans (newest first),
/// deletes on swipe, and formats each plan's schedule for display.
@MainActor
@Observable
final class WorkoutPlansViewModel {
    // MARK: State
    private(set) var plans: [WorkoutPlan] = []
    var errorMessage: String?
    /// Whether the last reload failed; the list then keeps its previous plans.
    private(set) var hasLoadError = false

    // MARK: Dependencies
    private let service: WorkoutPlanService

    // MARK: Init
    init(service: WorkoutPlanService) {
        self.service = service
        reload()
    }

    // MARK: Intentions
    /// Re-reads the store; call on appear so plans saved in the editor show up.
    func reload() {
        do {
            plans = try service.loadPlans().sorted { $0.createdAt > $1.createdAt }
            hasLoadError = false
        } catch {
            // Alert once per failure streak, not on every appear.
            if !hasLoadError { errorMessage = StoreLoadFailure.message }
            hasLoadError = true
        }
    }

    /// Deletes the plan and its reminders. The row goes at once; when the
    /// delete fails the list reloads to bring it back.
    func delete(_ plan: WorkoutPlan) async {
        plans.removeAll { $0.id == plan.id }
        do {
            let reminders = try await service.delete(id: plan.id)
            if reminders == .failed, plan.reminderTime != nil {
                errorMessage = "Plan usunięty, ale nie udało się odwołać jego przypomnień."
            }
        } catch {
            errorMessage = "Nie udało się usunąć planu."
            reload()
        }
    }

    /// Short Polish recurrence summary for a plan row.
    func scheduleSummary(for plan: WorkoutPlan) -> String {
        WorkoutScheduleFormatter.summary(plan.schedule)
    }

    /// The reminder's time for a plan row, e.g. "18:30", or `nil` when the
    /// plan has no reminder.
    func reminderSummary(for plan: WorkoutPlan) -> String? {
        guard let time = plan.reminderTime, let hour = time.hour, let minute = time.minute else { return nil }
        return String(format: "%02d:%02d", hour, minute)
    }
}
