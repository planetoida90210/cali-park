import Foundation
@testable import cali_park

// MARK: - Test wiring for WorkoutPlanService
@MainActor
extension WorkoutPlanService {
    /// A service over `store` with an in-memory scheduler, for view model
    /// tests that don't look at reminders.
    static func testing(_ store: WorkoutPlanStoring,
                        scheduler: WorkoutReminderScheduling = InMemoryReminderScheduler()) -> WorkoutPlanService {
        WorkoutPlanService(store: store, scheduler: scheduler)
    }
}
