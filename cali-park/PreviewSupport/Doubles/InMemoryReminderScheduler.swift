#if DEBUG
import Foundation

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

    init(
        status: ReminderAuthorizationStatus = .notDetermined,
        grantOnRequest: Bool = true,
        failsToSchedule: Bool = false,
        calendar: Calendar = .current,
        clock: @escaping @Sendable () -> Date = { .now }
    ) {
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
#endif
