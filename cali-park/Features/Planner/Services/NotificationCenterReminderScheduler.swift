import Foundation
import os
import UserNotifications

// MARK: - UserNotificationCentering
/// The slice of `UNUserNotificationCenter` the reminder scheduler needs, in
/// app terms. The app uses `SystemNotificationCenter`; tests use a fake, so the
/// diffing, the pending cap and the serialization are testable without the
/// system.
nonisolated protocol UserNotificationCentering: Sendable {
    func authorizationStatus() async -> ReminderAuthorizationStatus
    /// Prompts for alert + sound permission (no badge: the app never sets one).
    func requestAuthorization() async throws -> Bool
    /// Identifiers of every pending request, including other features' ones.
    func pendingRequestIDs() async -> [String]
    /// Registers the request, replacing a pending one with the same id.
    func add(_ request: WorkoutReminderRequest) async throws
    func removePendingRequests(withIDs ids: [String]) async
}

// MARK: - SystemNotificationCenter
/// `UserNotificationCentering` backed by `UNUserNotificationCenter.current()`.
nonisolated struct SystemNotificationCenter: UserNotificationCentering {
    private var center: UNUserNotificationCenter { .current() }

    func authorizationStatus() async -> ReminderAuthorizationStatus {
        let settings = await center.notificationSettings()
        return Self.map(settings.authorizationStatus)
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }

    func pendingRequestIDs() async -> [String] {
        await center.pendingNotificationRequests().map(\.identifier)
    }

    func add(_ request: WorkoutReminderRequest) async throws {
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: request.dateComponents, repeats: false)
        try await center.add(UNNotificationRequest(identifier: request.id, content: content, trigger: trigger))
    }

    func removePendingRequests(withIDs ids: [String]) async {
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    private static func map(_ status: UNAuthorizationStatus) -> ReminderAuthorizationStatus {
        switch status {
        case .notDetermined: .notDetermined
        case .denied: .denied
        case .authorized, .provisional, .ephemeral: .authorized
        @unknown default: .denied
        }
    }
}

// MARK: - NotificationCenterReminderScheduler
/// Default `WorkoutReminderScheduling`. It only touches reminders whose
/// identifier begins with `plan-`, so it never clears other features'
/// notifications.
///
/// Each reschedule diffs instead of wiping: it removes owned requests that are
/// no longer wanted, then adds (or replaces) the wanted ones, at most
/// `WorkoutReminderPlanner.pendingLimit` and soonest first. Reschedules are
/// chained, so two quick saves can never interleave their remove and add steps
/// and leave a stale set behind.
///
/// The diff is also the migration from the old repeating weekly reminders
/// (`plan-<uuid>-wd<N>`): no wanted id has that shape any more, so the first
/// sync after the update removes them.
actor NotificationCenterReminderScheduler: WorkoutReminderScheduling {
    private static let ownedPrefix = "plan-"

    private let center: UserNotificationCentering
    private let calendar: Calendar
    private let clock: @Sendable () -> Date
    private let logger = AppLog.logger(category: "Reminders")
    /// The latest queued reschedule; the next one waits for it.
    private var lastRun: Task<Void, Error>?

    init(center: UserNotificationCentering,
         calendar: Calendar = .current,
         clock: @escaping @Sendable () -> Date = { .now }) {
        self.center = center
        self.calendar = calendar
        self.clock = clock
    }

    func authorizationStatus() async -> ReminderAuthorizationStatus {
        await center.authorizationStatus()
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization()
        } catch {
            logger.error("Notification authorization request failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func reschedule(for plans: [WorkoutPlan], entries: [WorkoutLogEntry]) async throws {
        // Set synchronously on the actor, before any suspension, so calls
        // queue in the order they arrive.
        let previous = lastRun
        let run = Task {
            _ = await previous?.result
            try await apply(plans, entries: entries)
        }
        lastRun = run
        try await run.value
    }

    /// One reschedule: compute the wanted set, drop stale owned requests, then
    /// register the wanted ones. Without permission nothing is added (the
    /// next foreground sync adds them once the user allows notifications).
    private func apply(_ plans: [WorkoutPlan], entries: [WorkoutLogEntry]) async throws {
        let wanted = WorkoutReminderPlanner.requests(for: plans, entries: entries, calendar: calendar, asOf: clock())
        let wantedIDs = Set(wanted.map(\.id))

        let stale = await center.pendingRequestIDs()
            .filter { $0.hasPrefix(Self.ownedPrefix) && !wantedIDs.contains($0) }
        if !stale.isEmpty {
            await center.removePendingRequests(withIDs: stale)
        }

        guard !wanted.isEmpty, await center.authorizationStatus().isAuthorized else { return }

        var failed: [String] = []
        for request in wanted {
            do {
                try await center.add(request)
            } catch {
                failed.append(request.id)
                logger.error("Could not schedule reminder \(request.id, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
        if !failed.isEmpty {
            throw ReminderSchedulingError(failedRequestIDs: failed)
        }
    }
}
