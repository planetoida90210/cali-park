import Foundation
@testable import cali_park

// MARK: - Test wiring for WorkoutPlanService
@MainActor
extension WorkoutPlanService {
    /// A service over `store` with an empty in-memory log and in-memory
    /// schedulers, for tests that don't look at every collaborator.
    static func testing(_ store: WorkoutPlanStoring,
                        logStore: WorkoutLogStoring = InMemoryWorkoutLogStore(),
                        scheduler: WorkoutReminderScheduling = InMemoryReminderScheduler(),
                        refreshScheduler: ReminderRefreshScheduling = InMemoryReminderRefreshScheduler()) -> WorkoutPlanService {
        WorkoutPlanService(store: store, logStore: logStore, scheduler: scheduler, refreshScheduler: refreshScheduler)
    }
}
