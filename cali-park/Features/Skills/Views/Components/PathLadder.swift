import SwiftUI

// MARK: - PathLadder
struct PathLadder: View {
    let summary: SkillPathSummary
    let viewModel: SkillPathsViewModel
    let onSelect: (ProgressionStep) -> Void

    /// One presentable rung per ladder step, resolved once so the row views stay
    /// index-free.
    private var rungs: [LadderRung] {
        let steps = summary.path.steps
        return steps.indices.map { index in
            let step = steps[index]
            let displayState: RungDisplayState
            if summary.state.isConquered(rungAt: index) {
                displayState = .conquered
            } else if summary.state.isCurrent(rungAt: index) {
                displayState = .current
            } else {
                displayState = .future
            }
            let progress =
                displayState == .current
                ? summary.currentProgress
                : viewModel.rungProgress(for: step)
            return LadderRung(
                step: step,
                displayState: displayState,
                progress: progress,
                isFirst: index == 0,
                isLast: index == steps.count - 1
            )
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(rungs) { rung in
                RungRow(rung: rung) { onSelect(rung.step) }
            }
        }
    }
}
