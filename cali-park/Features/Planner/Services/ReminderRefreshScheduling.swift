import BackgroundTasks
import Foundation
import os

// MARK: - ReminderRefreshScheduling
/// Asks iOS to wake the app in the background to top up dated reminders.
/// Pending reminders only reach `WorkoutReminderPlanner.pendingLimit`
/// occurrences ahead, so without the app opening they would run out.
@MainActor
protocol ReminderRefreshScheduling {
    /// Requests the next background reminder sync, about a day from now.
    /// Replaces any earlier request. iOS decides when (or whether) it runs.
    func scheduleNextRefresh()
}

// MARK: - AppRefreshScheduler
/// `ReminderRefreshScheduling` backed by `BGTaskScheduler`. The app handles
/// `taskIdentifier` with SwiftUI's `.backgroundTask(.appRefresh(...))`, and the
/// identifier is listed under `BGTaskSchedulerPermittedIdentifiers` in
/// `Info.plist`.
struct AppRefreshScheduler: ReminderRefreshScheduling {
    /// The bundle ID plus `.reminders-refresh`. `Info.plist` builds the same
    /// value from `$(PRODUCT_BUNDLE_IDENTIFIER)`, so changing the bundle ID
    /// changes both.
    nonisolated static let taskIdentifier = taskIdentifier(bundleIdentifier: Bundle.main.bundleIdentifier ?? "")

    nonisolated static func taskIdentifier(bundleIdentifier: String) -> String {
        "\(bundleIdentifier).reminders-refresh"
    }

    /// Roughly a day: the pending reminders reach much further than that.
    nonisolated static let interval: TimeInterval = 24 * 60 * 60

    private let logger = AppLog.logger(category: "Reminders")

    /// Nonisolated so it can be a default argument of `AppEnvironment.init`.
    nonisolated init() {}

    /// The refresh request for `now`, separate from submitting so it is
    /// testable.
    nonisolated static func request(after now: Date = .now) -> BGAppRefreshTaskRequest {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = now.addingTimeInterval(interval)
        return request
    }

    func scheduleNextRefresh() {
        do {
            try BGTaskScheduler.shared.submit(Self.request())
        } catch {
            // Expected on the simulator and when Background App Refresh is
            // off; launch and foreground syncs still top reminders up.
            logger.notice("Background reminder refresh not scheduled: \(error.localizedDescription, privacy: .public)")
        }
    }
}
