import Foundation

// MARK: - UnilateralSide
/// How a one-sided exercise is counted: per arm, per leg, or per side.
///
/// A target like "3 × 5" on a unilateral exercise means 3 × 5 on each side.
/// The log format has one value per set, so the athlete logs the weaker
/// side's result; separate left/right logging would change the log schema.
nonisolated enum UnilateralSide: String, Codable, Sendable {
    case arm
    case leg
    case side

    /// The suffix appended to a criterion: "3 × 5 na rękę".
    var label: String {
        switch self {
        case .arm: "na rękę"
        case .leg: "na nogę"
        case .side: "na stronę"
        }
    }
}
