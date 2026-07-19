import Foundation

// MARK: - HomeAchievementsSummary
/// The real data behind the Home "Osiągnięcia" module: the athlete's level, how
/// far they are into it, how many badges they hold, and the most recent rung
/// they conquered.
///
/// Derived, never persisted. Built by `HomeDashboardViewModel` from the same
/// logs the Skills tab reads (`ProgressionEngine`), so Home and Skills always
/// agree. Declarations never contribute — level, badges, and advances all come
/// from logs alone.
struct HomeAchievementsSummary: Equatable, Sendable {
    /// The athlete's current level (starts at 1).
    let level: Int
    /// XP still needed to reach the next level.
    let xpToNextLevel: Int
    /// Progress through the current level, clamped to `0...1`.
    let progressToNextLevel: Double
    /// Badges earned so far.
    let earnedBadgeCount: Int
    /// Total badges defined.
    let totalBadgeCount: Int
    /// The most recently conquered rung, or `nil` for a fresh journal.
    let lastAdvancement: Advancement?

    /// A resolved, display-ready description of one conquered rung.
    struct Advancement: Equatable, Sendable {
        /// The rung's exercise name, e.g. "Pełne podciągnięcia".
        let title: String
        /// The path it belongs to, e.g. "Podciąganie".
        let pathName: String
        /// The path's SF Symbol, in the app's Watch-Workout style.
        let symbolName: String
    }
}
