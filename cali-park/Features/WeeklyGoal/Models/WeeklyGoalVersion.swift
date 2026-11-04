import Foundation

// MARK: - WeeklyGoalVersion
/// The goal set in force from `effectiveFrom` until the next version. Keeping
/// every version lets a closed week be judged by the goals that applied when it
/// ended, so changing a goal never rewrites history.
nonisolated struct WeeklyGoalVersion: Codable, Equatable, Sendable {
    var effectiveFrom: Date
    /// One to three goals. The first is the primary goal: it fills the hero
    /// ring and drives the week streak.
    var goals: [WeeklyGoal]

    init(effectiveFrom: Date, goals: [WeeklyGoal]) {
        precondition(!goals.isEmpty, "A goal version needs at least one goal")
        self.effectiveFrom = effectiveFrom
        self.goals = goals
    }

    var primary: WeeklyGoal { goals[0] }

    // MARK: Codable
    private enum CodingKeys: String, CodingKey {
        case effectiveFrom
        case goals
    }

    /// Rejects a version without goals, so a damaged file is quarantined
    /// instead of crashing on `primary`.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        effectiveFrom = try container.decode(Date.self, forKey: .effectiveFrom)
        let goals = try container.decode([WeeklyGoal].self, forKey: .goals)
        guard !goals.isEmpty else {
            throw DecodingError.dataCorruptedError(
                forKey: .goals, in: container, debugDescription: "A goal version needs at least one goal"
            )
        }
        self.goals = goals
    }
}
