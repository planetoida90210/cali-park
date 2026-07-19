import Foundation

// MARK: - CelebrationEvent
/// One thing worth celebrating, earned strictly through training: a rung
/// conquered on a path, or a new player level reached.
///
/// The event carries only stable references (a `RungReference`, a level number),
/// never display copy — `CelebrationPresentation` resolves the title, message,
/// and symbol from the catalogs on demand, keeping the event pure and
/// order-comparable. Declarations never produce an event: the reward evaluator
/// scores from logs alone (see `RewardEvaluator`).
enum CelebrationEvent: Equatable, Hashable, Identifiable, Sendable {
    /// A rung conquered through logged training.
    case rungConquered(RungReference)
    /// A new player level reached.
    case levelReached(Int)

    /// A stable identity, so a queue of events stays diffable in SwiftUI.
    var id: String {
        switch self {
        case let .rungConquered(rung): "rung-\(rung.pathID.rawValue)-\(rung.rungIndex)"
        case let .levelReached(level): "level-\(level)"
        }
    }
}
