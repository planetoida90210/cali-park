import SwiftUI

// MARK: - RungRow
/// One rung on the ladder: its rail marker and its card, opening the rung's
/// detail when tapped.
struct RungRow: View {
    let rung: LadderRung
    let onSelect: () -> Void

    private var step: ProgressionStep { rung.step }
    private var displayState: RungDisplayState { rung.displayState }
    private var progress: RungProgress { rung.progress }

    private var exercise: Exercise? {
        ExerciseCatalog.exercise(withID: step.exerciseID)
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 12) {
                RungRail(displayState: displayState, fraction: progress.fractionComplete, isFirst: rung.isFirst, isLast: rung.isLast)
                RungCard(rung: rung, exercise: exercise)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise?.name ?? String(localized: "Szczebel")). \(stateLabel)")
        .accessibilityHint("Otwórz szczegóły i trenuj")
    }

    private var stateLabel: String {
        switch displayState {
        case .conquered: String(localized: "Zaliczone")
        case .current: String(localized: "Trenujesz teraz. Cel: \(MeasureFormat.spokenCriterion(for: step))")
        case .future: String(localized: "Cel: \(MeasureFormat.spokenCriterion(for: step))")
        }
    }
}
