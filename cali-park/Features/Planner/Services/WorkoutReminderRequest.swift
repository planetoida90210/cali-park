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
    /// Fire time. For weekly reminders only `weekday`/`hour`/`minute` are set
    /// (with `repeats == true`); for one-off reminders the full calendar date
    /// is set (with `repeats == false`).
    let dateComponents: DateComponents
    let repeats: Bool
}
