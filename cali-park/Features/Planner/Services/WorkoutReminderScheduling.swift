import Foundation

// MARK: - ReminderAuthorizationStatus
/// App-level view of notification permission, decoupled from
/// `UNAuthorizationStatus` so view models don't import `UserNotifications`.
enum ReminderAuthorizationStatus: Sendable {
    case notDetermined
    case denied
    case authorized

    /// Whether reminders can actually be delivered.
    var isAuthorized: Bool { self == .authorized }
}

// MARK: - WorkoutReminderScheduling
/// Abstraction over local-reminder scheduling, mirroring the store protocols:
/// UI stays testable with the in-memory stub, and the real
/// `UNUserNotificationCenter` implementation is swapped in via `AppEnvironment`.
protocol WorkoutReminderScheduling: Sendable {
    /// Current permission state without prompting.
    func authorizationStatus() async -> ReminderAuthorizationStatus

    /// Prompts for permission if undetermined; returns whether it's granted.
    @discardableResult
    func requestAuthorization() async -> Bool

    /// Replaces all app-owned pending reminders with those derived from `plans`.
    func reschedule(for plans: [WorkoutPlan]) async

    /// Removes every app-owned pending reminder.
    func cancelAll() async
}

// MARK: - InMemoryReminderScheduler
/// Non-persistent scheduler for previews and unit tests. Records the requests
/// it was last asked to schedule so tests can assert on them without touching
/// the system notification center.
actor InMemoryReminderScheduler: WorkoutReminderScheduling {
    private(set) var scheduledRequests: [WorkoutReminderRequest] = []
    private(set) var rescheduleCount = 0
    private var status: ReminderAuthorizationStatus
    private let grantOnRequest: Bool
    private let calendar: Calendar

    init(status: ReminderAuthorizationStatus = .notDetermined,
         grantOnRequest: Bool = true,
         calendar: Calendar = .current) {
        self.status = status
        self.grantOnRequest = grantOnRequest
        self.calendar = calendar
    }

    func authorizationStatus() async -> ReminderAuthorizationStatus { status }

    @discardableResult
    func requestAuthorization() async -> Bool {
        if status == .notDetermined {
            status = grantOnRequest ? .authorized : .denied
        }
        return status.isAuthorized
    }

    func reschedule(for plans: [WorkoutPlan]) async {
        rescheduleCount += 1
        scheduledRequests = WorkoutReminderPlanner.requests(for: plans, calendar: calendar)
    }

    func cancelAll() async {
        scheduledRequests = []
    }
}
