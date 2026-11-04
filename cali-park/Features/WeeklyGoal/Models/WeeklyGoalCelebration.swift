import Foundation

// MARK: - WeeklyGoalCelebration
/// One shown "goal met" celebration: a goal in the week starting at `weekStart`.
nonisolated struct WeeklyGoalCelebration: Codable, Hashable, Sendable {
    let weekStart: Date
    let goalID: UUID
}
