import SwiftUI

// MARK: - RungCard
/// A rung's card: the exercise, what the rung asks (or how far along it is),
/// and the parallel-track note. Outlined in accent on the current rung.
struct RungCard: View {
    let rung: LadderRung
    let exercise: Exercise?

    private var step: ProgressionStep { rung.step }
    private var displayState: RungDisplayState { rung.displayState }
    private var progress: RungProgress { rung.progress }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise?.name ?? String(localized: "Szczebel"))
                .font(.bodyLarge)
                .foregroundStyle(displayState == .future ? Color.textSecondary : Color.textPrimary)

            Text(subtitle)
                .font(.bodySmall)
                .foregroundStyle(subtitleColor)

            if step.isParallelTrack {
                Text("Tor równoległy — opcjonalny")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textTertiary)
                    .accessibilityAddTraits(.isHeader)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: AppRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .stroke(Color.accent, lineWidth: displayState == .current ? 1 : 0)
        )
        .padding(.bottom, 12)
    }

    private var subtitle: String {
        switch displayState {
        case .conquered: String(localized: "Zaliczone")
        case .current: MeasureFormat.progressLine(progress, side: step.unilateralSide)
        case .future: MeasureFormat.criterion(for: step)
        }
    }

    private var subtitleColor: Color {
        switch displayState {
        case .conquered: Color.accent
        case .current: Color.textSecondary
        case .future: Color.textTertiary
        }
    }
}
