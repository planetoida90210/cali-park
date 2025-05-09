import Foundation

// MARK: - CalendarService (Stub)
/// Placeholder service that will later integrate with EventKit.
/// Currently simulates latency and returns a random event identifier.
actor CalendarService {
    /// Simulates adding the event to the user's calendar and returns fake identifier.
    func addEvent(_ event: ParkEvent) async throws -> String {
        // Simulate network / EventKit delay
        try await Task.sleep(nanoseconds: 250_000_000)
        return UUID().uuidString
    }

    /// Simulates removing an event from user's calendar.
    func removeEvent(identifier: String) async throws {
        try await Task.sleep(nanoseconds: 150_000_000)
        // noop
    }
} 