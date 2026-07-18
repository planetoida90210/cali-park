import Foundation

// MARK: - PlayerLevel
/// The athlete's level derived from total experience points.
///
/// The curve is a widening quadratic: reaching level `L` costs
/// `500 · (L - 1)²` XP, so early levels come fast and later ones ask for real
/// volume. `PlayerLevel` owns its own curve; `ProgressionEngine` supplies the
/// XP. It is derived state, never persisted.
struct PlayerLevel: Equatable, Sendable {
    /// The current level, starting at 1.
    let level: Int
    /// Total accumulated experience points.
    let totalXP: Int
    /// XP threshold at which this level began.
    let xpAtLevelStart: Int
    /// XP threshold at which the next level begins.
    let xpAtNextLevel: Int

    /// XP earned since the current level began.
    var xpIntoLevel: Int { totalXP - xpAtLevelStart }

    /// XP span of the current level.
    var xpSpanForLevel: Int { xpAtNextLevel - xpAtLevelStart }

    /// XP still needed to reach the next level.
    var xpToNextLevel: Int { max(0, xpAtNextLevel - totalXP) }

    /// Progress through the current level, clamped to `0...1`.
    var progressToNextLevel: Double {
        guard xpSpanForLevel > 0 else { return 0 }
        return min(1, Double(xpIntoLevel) / Double(xpSpanForLevel))
    }

    /// The XP needed to *reach* a given level (level 1 starts at 0).
    static func threshold(forLevel level: Int) -> Int {
        guard level > 1 else { return 0 }
        let steps = level - 1
        return 500 * steps * steps
    }

    /// The level for a total XP amount, with its surrounding thresholds.
    static func forXP(_ xp: Int) -> PlayerLevel {
        let clampedXP = max(0, xp)
        var level = 1
        while threshold(forLevel: level + 1) <= clampedXP {
            level += 1
        }
        return PlayerLevel(
            level: level,
            totalXP: clampedXP,
            xpAtLevelStart: threshold(forLevel: level),
            xpAtNextLevel: threshold(forLevel: level + 1)
        )
    }
}
