import Foundation
import UserNotifications

// MARK: - NotificationCenterReminderScheduler
/// Default `WorkoutReminderScheduling` backed by `UNUserNotificationCenter`.
/// Stateless (all state lives in the notification center), so it's safely
/// `Sendable`. Only touches reminders whose identifier begins with `plan-`, so
/// it never clears notifications owned by other features.
struct NotificationCenterReminderScheduler: WorkoutReminderScheduling {
    private static let ownedPrefix = "plan-"

    private var center: UNUserNotificationCenter { .current() }

    func authorizationStatus() async -> ReminderAuthorizationStatus {
        let settings = await center.notificationSettings()
        return Self.map(settings.authorizationStatus)
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted ?? false
    }

    func reschedule(for plans: [WorkoutPlan]) async {
        await cancelAll()

        let requests = WorkoutReminderPlanner.requests(for: plans)
        for request in requests {
            let content = UNMutableNotificationContent()
            content.title = request.title
            content.body = request.body
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: request.dateComponents,
                                                         repeats: request.repeats)
            let notification = UNNotificationRequest(identifier: request.id,
                                                     content: content,
                                                     trigger: trigger)
            try? await center.add(notification)
        }
    }

    func cancelAll() async {
        let pending = await center.pendingNotificationRequests()
        let ownedIDs = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.ownedPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ownedIDs)
    }

    // MARK: Mapping

    private static func map(_ status: UNAuthorizationStatus) -> ReminderAuthorizationStatus {
        switch status {
        case .notDetermined: .notDetermined
        case .denied: .denied
        case .authorized, .provisional, .ephemeral: .authorized
        @unknown default: .denied
        }
    }
}
