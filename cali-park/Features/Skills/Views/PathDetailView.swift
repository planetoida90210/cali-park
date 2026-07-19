import SwiftUI

// MARK: - PathDetailView
/// One progression path as a vertical ladder: conquered rungs in accent, the
/// current rung highlighted with its progress, and future rungs dimmed but fully
/// described and tappable. The ladder is a map, never a gate — there are no lock
/// icons anywhere, and any rung opens for logging.
///
/// The optional base hint is a neutral note, never a prerequisite. "Ustaw
/// poziom" opens the placement calibration for this and every other path.
struct PathDetailView: View {
    let environment: AppEnvironment
    let pathID: ProgressionPathID

    @State private var viewModel: SkillPathsViewModel
    @State private var selectedStep: ProgressionStep?
    @State private var showingCalibration = false

    init(environment: AppEnvironment, pathID: ProgressionPathID) {
        self.environment = environment
        self.pathID = pathID
        _viewModel = State(initialValue: environment.makeSkillPathsViewModel())
    }

    private var summary: SkillPathSummary? {
        viewModel.summary(for: pathID)
    }

    var body: some View {
        ScrollView {
            if let summary {
                VStack(alignment: .leading, spacing: 24) {
                    if let base = summary.path.recommendedBase {
                        BaseHintNote(text: base)
                    }

                    Ladder(summary: summary, viewModel: viewModel) { step in
                        selectedStep = step
                    }

                    CalibrationButton { showingCalibration = true }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(summary?.path.name ?? "Ścieżka")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.load() }
        .onChange(of: selectedStep) { _, step in
            // Returning from a training sheet may have logged new sets.
            if step == nil { viewModel.load() }
        }
        .sheet(item: $selectedStep) { step in
            StepDetailSheetView(
                exercise: ExerciseCatalog.exercise(withID: step.exerciseID) ?? ExerciseCatalog.all[0],
                step: step,
                progress: viewModel.rungProgress(for: step),
                environment: environment
            )
        }
        .sheet(isPresented: $showingCalibration, onDismiss: { viewModel.load() }) {
            PlacementCalibrationSheet(viewModel: environment.makePlacementCalibrationViewModel())
        }
        .rewardOverlay(viewModel)
    }
}

// MARK: - Ladder
private struct Ladder: View {
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
            let progress = displayState == .current
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

// MARK: - LadderRung
/// A single rung resolved for display: its step, how it reads, and where it
/// sits on the rail.
private struct LadderRung: Identifiable {
    let step: ProgressionStep
    let displayState: RungDisplayState
    let progress: RungProgress
    let isFirst: Bool
    let isLast: Bool

    var id: UUID { step.id }
}

// MARK: - RungDisplayState
/// How a rung reads on the ladder. There is deliberately no "locked" case —
/// future rungs are dimmed, not gated.
private enum RungDisplayState {
    case conquered
    case current
    case future
}

// MARK: - RungRow
private struct RungRow: View {
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
                card
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise?.name ?? "Szczebel"). \(stateLabel)")
        .accessibilityHint("Otwórz szczegóły i trenuj")
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise?.name ?? "Szczebel")
                .font(.bodyLarge)
                .foregroundStyle(displayState == .future ? Color.textSecondary : Color.textPrimary)

            Text(subtitle)
                .font(.bodySmall)
                .foregroundStyle(subtitleColor)

            if step.isParallelTrack {
                Text("Tor równoległy — opcjonalny")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accent, lineWidth: displayState == .current ? 1 : 0)
        )
        .padding(.bottom, 12)
    }

    private var subtitle: String {
        switch displayState {
        case .conquered: "Zaliczone"
        case .current: ProgressionFormat.progressLine(progress)
        case .future: ProgressionFormat.criterion(step.criterion)
        }
    }

    private var subtitleColor: Color {
        switch displayState {
        case .conquered: Color.accent
        case .current: Color.textSecondary
        case .future: Color.textTertiary
        }
    }

    private var stateLabel: String {
        switch displayState {
        case .conquered: "Zaliczone"
        case .current: "Trenujesz teraz. Cel: \(ProgressionFormat.spokenCriterion(step.criterion))"
        case .future: "Cel: \(ProgressionFormat.spokenCriterion(step.criterion))"
        }
    }
}

// MARK: - RungRail
/// The timeline column: a marker per rung joined by a continuous line. The
/// connectors meet the marker at its edges and stop there — never crossing over
/// it — so every marker reads cleanly, filled or hollow. The line runs accent up
/// to the conquered rungs and dims beyond.
private struct RungRail: View {
    let displayState: RungDisplayState
    let fraction: Double
    let isFirst: Bool
    let isLast: Bool

    /// Gap from the top of the rail down to the marker, matched to the card's
    /// own top padding so the marker lines up with the rung's title.
    private let markerTopInset: CGFloat = 12

    private var lineColor: Color {
        displayState == .conquered ? Color.accent : Color.divider
    }

    var body: some View {
        VStack(spacing: 0) {
            connector
                .frame(height: markerTopInset)
                .opacity(isFirst ? 0 : 1)

            marker

            connector
                .frame(maxHeight: .infinity)
                .opacity(isLast ? 0 : 1)
        }
        .frame(width: 28)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var connector: some View {
        Rectangle()
            .fill(lineColor)
            .frame(width: 2)
    }

    @ViewBuilder
    private var marker: some View {
        switch displayState {
        case .conquered:
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Color.accent)
        case .current:
            ZStack {
                Circle()
                    .stroke(Color.divider, lineWidth: 3)
                Circle()
                    .trim(from: 0, to: max(0.02, fraction))
                    .stroke(Color.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 24, height: 24)
        case .future:
            Circle()
                .stroke(Color.divider, lineWidth: 2)
                .frame(width: 20, height: 20)
        }
    }
}

// MARK: - BaseHintNote
/// A neutral, non-binding note about movements people usually build this path
/// on. Never a prerequisite.
private struct BaseHintNote: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundStyle(Color.textSecondary)
            Text(text)
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: 12))
    }
}

// MARK: - CalibrationButton
private struct CalibrationButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Ustaw poziom", systemImage: "slider.horizontal.3")
                .font(.buttonMedium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(Color.accent)
                .background(Color.componentBackground)
                .clipShape(.rect(cornerRadius: 12))
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        PathDetailView(
            environment: .seeded(
                logs: [
                    WorkoutLogEntry(
                        exerciseID: ExerciseCatalog.pullUpsID,
                        sets: [LoggedSet(reps: 6), LoggedSet(reps: 6), LoggedSet(reps: 6)]
                    )
                ],
                placement: SkillPlacement(declaredRungByPath: [.pullUp: 3])
            ),
            pathID: .pullUp
        )
    }
    .preferredColorScheme(.dark)
}
