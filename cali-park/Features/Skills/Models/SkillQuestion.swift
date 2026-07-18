import Foundation

// MARK: - SkillQuestion
/// A yes/no onboarding checkbox: "can you already do this skill?".
///
/// Checking it declares a starting rung on the skill's path, so everything below
/// counts as conquered. A skill may share a path with a `RepCountQuestion` — the
/// pistol squat and the squat count both place `legs` — in which case the
/// calibration keeps the higher rung.
struct SkillQuestion: Identifiable, Sendable {
    /// Stable identifier for the checkbox state; kept distinct from `path` since
    /// several skills can target the same path.
    let id: String
    /// The path this skill places.
    let path: ProgressionPathID
    /// The checkbox label, e.g. "Muscle-up".
    let label: String
    /// The starting rung declared when the athlete checks this skill. Always
    /// greater than zero, so the declaration actually moves the starting point.
    let rung: Int
}
