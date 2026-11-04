import Foundation

// MARK: - InMemoryWorkoutPlanStore
/// Non-persistent store for previews and unit tests.
nonisolated final class InMemoryWorkoutPlanStore: WorkoutPlanStoring {
    private var plans: [WorkoutPlan]

    init(initial: [WorkoutPlan] = []) {
        plans = initial
    }

    func load() -> [WorkoutPlan] { plans }

    func save(_ plan: WorkoutPlan) throws {
        if let index = plans.firstIndex(where: { $0.id == plan.id }) {
            plans[index] = plan
        } else {
            plans.append(plan)
        }
    }

    func delete(id: UUID) throws {
        plans.removeAll { $0.id == id }
    }

    func replaceAll(with plans: [WorkoutPlan]) throws {
        self.plans = plans
    }
}
