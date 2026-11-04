import SwiftUI

// MARK: - RungDisplayState
/// How a rung reads on the ladder. There is deliberately no "locked" case —
/// future rungs are dimmed, not gated.
enum RungDisplayState {
    case conquered
    case current
    case future
}
