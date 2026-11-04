import Foundation

// MARK: - ReminderAuthorizationStatus
/// App-level view of notification permission, decoupled from
/// `UNAuthorizationStatus` so view models don't import `UserNotifications`.
nonisolated enum ReminderAuthorizationStatus: Sendable {
    case notDetermined
    case denied
    case authorized

    /// Whether reminders can actually be delivered.
    var isAuthorized: Bool { self == .authorized }
}

// MARK: - ReminderSchedulingError
/// Some reminders could not be registered. The others were, so the error
/// lists only the failed request identifiers.
nonisolated struct ReminderSchedulingError: Error, Equatable {
    let failedRequestIDs: [String]
}

// MARK: - WorkoutReminderScheduling
/// Abstraction over local-reminder scheduling, mirroring the store protocols:
/// UI stays testable with the in-memory stub, and the real
/// `UNUserNotificationCenter` implementation is swapped in via `AppEnvironment`.
nonisolated protocol WorkoutReminderScheduling: Sendable {
    /// Current permission state without prompting.
    func authorizationStatus() async -> ReminderAuthorizationStatus

    /// Prompts for permission if undetermined; returns whether it's granted.
    /// A failed request counts as not granted.
    @discardableResult
    func requestAuthorization() async -> Bool

    /// Makes the app-owned pending reminders match those derived from
    /// `plans`, leaving out days on which `entries` show the plan done. Calls
    /// never interleave: a second call starts after the first one finished.
    /// Throws `ReminderSchedulingError` when some reminders could not be
    /// registered.
    func reschedule(for plans: [WorkoutPlan], entries: [WorkoutLogEntry]) async throws
}

nonisolated extension WorkoutReminderScheduling {
    /// Reschedules as if nothing were done yet.
    func reschedule(for plans: [WorkoutPlan]) async throws {
        try await reschedule(for: plans, entries: [])
    }
}
