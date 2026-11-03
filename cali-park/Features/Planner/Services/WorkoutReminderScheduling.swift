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

// MARK: - ReminderSchedulingError
/// Some reminders could not be registered. The others were, so the error
/// lists only the failed request identifiers.
struct ReminderSchedulingError: Error, Equatable {
    let failedRequestIDs: [String]
}

// MARK: - WorkoutReminderScheduling
/// Abstraction over local-reminder scheduling, mirroring the store protocols:
/// UI stays testable with the in-memory stub, and the real
/// `UNUserNotificationCenter` implementation is swapped in via `AppEnvironment`.
protocol WorkoutReminderScheduling: Sendable {
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

extension WorkoutReminderScheduling {
    /// Reschedules as if nothing were done yet.
    func reschedule(for plans: [WorkoutPlan]) async throws {
        try await reschedule(for: plans, entries: [])
    }
}

// MARK: - InMemoryReminderScheduler
/// Non-persistent scheduler for previews and unit tests. Records the requests
/// it was last asked to schedule so tests can assert on them without touching
/// the system notification center.
actor InMemoryReminderScheduler: WorkoutReminderScheduling {
    private(set) var scheduledRequests: [WorkoutReminderRequest] = []
    private(set) var rescheduleCount = 0
    private(set) var authorizationRequestCount = 0
    private var status: ReminderAuthorizationStatus
    private let grantOnRequest: Bool
    private var failsToSchedule: Bool
    private let calendar: Calendar
    private let clock: @Sendable () -> Date

    init(status: ReminderAuthorizationStatus = .notDetermined,
         grantOnRequest: Bool = true,
         failsToSchedule: Bool = false,
         calendar: Calendar = .current,
         clock: @escaping @Sendable () -> Date = { .now }) {
        self.status = status
        self.grantOnRequest = grantOnRequest
        self.failsToSchedule = failsToSchedule
        self.calendar = calendar
        self.clock = clock
    }

    func authorizationStatus() async -> ReminderAuthorizationStatus { status }

    @discardableResult
    func requestAuthorization() async -> Bool {
        authorizationRequestCount += 1
        if status == .notDetermined {
            status = grantOnRequest ? .authorized : .denied
        }
        return status.isAuthorized
    }

    func reschedule(for plans: [WorkoutPlan], entries: [WorkoutLogEntry]) async throws {
        rescheduleCount += 1
        let requests = WorkoutReminderPlanner.requests(for: plans, entries: entries, calendar: calendar, asOf: clock())
        if failsToSchedule {
            throw ReminderSchedulingError(failedRequestIDs: requests.map(\.id))
        }
        scheduledRequests = requests
    }

    /// Lets a test make later reschedules fail or succeed.
    func setFailsToSchedule(_ fails: Bool) {
        failsToSchedule = fails
    }
}
