import Foundation

// MARK: - WorkoutReminderRequest
/// A single local reminder derived from a `WorkoutPlan`, described without any
/// dependency on `UserNotifications`. This keeps the scheduling logic pure and
/// testable: `WorkoutReminderPlanner` builds these values, and the concrete
/// scheduler turns them into `UNNotificationRequest`s.
struct WorkoutReminderRequest: Equatable, Sendable {
    /// Stable identifier so rescheduling replaces the matching pending
    /// notification instead of duplicating it. Always starts with `plan-` so
    /// the scheduler can clear only the reminders it owns.
    let id: String
    let planID: UUID
    let title: String
    let body: String
    /// Fire time: the full calendar date (`year`/`month`/`day`/`hour`/
    /// `minute`). Reminders never repeat, so a day the plan is already done
    /// can simply have none.
    let dateComponents: DateComponents
}
