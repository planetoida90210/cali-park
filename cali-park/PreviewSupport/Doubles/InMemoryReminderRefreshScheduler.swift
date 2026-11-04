#if DEBUG
import Foundation

// MARK: - InMemoryReminderRefreshScheduler
/// Counts refresh requests, for previews and unit tests.
@MainActor
final class InMemoryReminderRefreshScheduler: ReminderRefreshScheduling {
    private(set) var scheduleCount = 0

    nonisolated init() {}

    func scheduleNextRefresh() {
        scheduleCount += 1
    }
}
#endif
