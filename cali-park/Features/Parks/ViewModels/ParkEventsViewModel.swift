import Foundation
import SwiftUI

// MARK: - ParkEventsViewModel
@MainActor
final class ParkEventsViewModel: ObservableObject {
    // Published list consumed by UI
    @Published private(set) var events: [ParkEvent] = []
    /// Most recently joined event – used by UI to show global toast.
    @Published var lastJoined: ParkEvent?

    private let parkID: UUID
    private let calendarService: CalendarService

    // MARK: - Init
    init(parkID: UUID, calendarService: CalendarService = CalendarService()) {
        self.parkID = parkID
        self.calendarService = calendarService
        loadMockData()
    }

    // MARK: - Public API
    func refresh() async {
        // Simulated fetch latency (~0.8s)
        try? await Task.sleep(nanoseconds: 800_000_000)
        loadMockData()
    }

    func join(_ event: ParkEvent) async {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
        var updated = events[index]
        guard !updated.isAttending, !updated.isFull else { return }

        // Optimistic UI
        updated.isAttending = true
        updated.attendeeCount += 1
        events[index] = updated

        do {
            // Simulate API latency
            try await Task.sleep(nanoseconds: 500_000_000)
            // Stub calendar integration
            let identifier = try await calendarService.addEvent(updated)
            updated.calendarEventIdentifier = identifier
            events[index] = updated

            // Expose to UI
            lastJoined = updated
        } catch {
            // Rollback on failure
            updated.isAttending = false
            updated.attendeeCount -= 1
            events[index] = updated
        }
    }

    /// Allows user to opt-out from an event they previously joined.
    func leave(_ event: ParkEvent) async {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
        var updated = events[index]
        guard updated.isAttending else { return }

        // Optimistic update
        updated.isAttending = false
        updated.attendeeCount = max(0, updated.attendeeCount - 1)
        events[index] = updated

        do {
            if let id = updated.calendarEventIdentifier {
                try await calendarService.removeEvent(identifier: id)
            }
            // Clear lastJoined if leaving same event
            if lastJoined?.id == updated.id { lastJoined = nil }
        } catch {
            // Rollback on failure
            updated.isAttending = true
            updated.attendeeCount += 1
            events[index] = updated
        }
    }

    // MARK: - Helpers
    private func loadMockData() {
        events = ParkEvent.events(for: parkID)
    }
} 