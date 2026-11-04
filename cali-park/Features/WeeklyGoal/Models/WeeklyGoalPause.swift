import Foundation

// MARK: - WeeklyGoalPause
/// A break from the weekly goal (illness, travel), at most 90 days. A week the
/// pause touches is neutral: it neither counts toward the goal nor breaks the
/// week streak, unless the goal was met anyway, which still counts.
///
/// The pause ends by itself at `plannedEnd`, or earlier when the athlete ends
/// it (`endedAt`).
struct WeeklyGoalPause: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    /// Start of the first paused day.
    let start: Date
    /// Start of the first day after the pause, at most 90 days after `start`.
    var plannedEnd: Date
    /// When the athlete ended the pause early, or `nil`.
    var endedAt: Date?

    init(id: UUID = UUID(), start: Date, plannedEnd: Date, endedAt: Date? = nil) {
        self.id = id
        self.start = start
        self.plannedEnd = plannedEnd
        self.endedAt = endedAt
    }

    /// The longest pause the athlete can set.
    static let maximumDays = 90

    /// The instant the pause stops applying (exclusive).
    var end: Date {
        guard let endedAt else { return plannedEnd }
        return min(plannedEnd, endedAt)
    }

    /// Whether the pause applies at `date`.
    func isActive(at date: Date) -> Bool {
        start <= date && date < end
    }

    /// Whether the pause touches any part of `interval`.
    func overlaps(_ interval: DateInterval) -> Bool {
        start < interval.end && end > interval.start
    }
}
