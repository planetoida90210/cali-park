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

// MARK: - Schedules from fixture dates
extension WorkoutSchedule {
    /// A one-off schedule on the day `date` falls on in `calendar`.
    static func once(_ date: Date, in calendar: Calendar) -> WorkoutSchedule {
        .once(CalendarDay(date, in: calendar))
    }

    /// An interval schedule anchored on the day `date` falls on in `calendar`.
    static func everyNDays(_ interval: Int, from date: Date, in calendar: Calendar) -> WorkoutSchedule {
        .everyNDays(interval, from: CalendarDay(date, in: calendar))
    }
}
