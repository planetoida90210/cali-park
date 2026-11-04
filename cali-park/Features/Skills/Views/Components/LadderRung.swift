import SwiftUI

// MARK: - LadderRung
/// A single rung resolved for display: its step, how it reads, and where it
/// sits on the rail.
struct LadderRung: Identifiable {
    let step: ProgressionStep
    let displayState: RungDisplayState
    let progress: RungProgress
    let isFirst: Bool
    let isLast: Bool

    var id: UUID { step.id }
}
