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
    private let store: WorkoutPlanStoring

    // MARK: Init
    init(store: WorkoutPlanStoring) {
        self.store = store
        reload()
    }

    // MARK: Intentions
    /// Re-reads the store; call on appear so plans saved in the editor show up.
    func reload() {
        do {
            plans = try store.load().sorted { $0.createdAt > $1.createdAt }
            hasLoadError = false
        } catch {
            // Alert once per failure streak, not on every appear.
            if !hasLoadError { errorMessage = StoreLoadFailure.message }
            hasLoadError = true
        }
    }

    func delete(_ plan: WorkoutPlan) {
        do {
            try store.delete(id: plan.id)
            plans.removeAll { $0.id == plan.id }
        } catch {
            errorMessage = "Nie udało się usunąć planu."
        }
    }

    /// Short Polish recurrence summary for a plan row.
    func scheduleSummary(for plan: WorkoutPlan) -> String {
        WorkoutScheduleFormatter.summary(plan.schedule)
    }
}
