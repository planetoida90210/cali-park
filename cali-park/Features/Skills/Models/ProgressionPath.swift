import Foundation

// MARK: - ProgressionPath
/// A single calisthenics progression: an ordered ladder of steps from the
/// easiest regression up to the skill.
///
/// Paths are independent of one another. `recommendedBase` is a purely
/// informational hint shown as a neutral note (e.g. "most people build the
/// muscle-up on solid pull-ups and dips"); it is deliberately not a
/// relationship and never gates or locks anything.
struct ProgressionPath: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: ProgressionPathID
    /// Polish display name, e.g. "Podciąganie".
    var name: String
    /// SF Symbol from the `figure.*` family, matching the Watch-Workout style
    /// used across the app.
    var symbolName: String
    /// Rungs from easiest regression to the skill, in training order.
    var steps: [ProgressionStep]
    /// Optional, non-binding note about movements people usually build this on.
    /// Never a prerequisite.
    var recommendedBase: String?

    init(id: ProgressionPathID,
         name: String,
         symbolName: String,
         steps: [ProgressionStep],
         recommendedBase: String? = nil) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.steps = steps
        self.recommendedBase = recommendedBase
    }
}
