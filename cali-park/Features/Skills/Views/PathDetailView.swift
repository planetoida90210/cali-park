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

    /// A projection of the shared progress snapshot; rewards live in the
    /// app-wide `RewardCenter`, so this screen keeps no reward state.
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
                        PathBaseHintNote(text: base)
                    }

                    PathLadder(summary: summary, viewModel: viewModel) { step in
                        selectedStep = step
                    }

                    PathCalibrationButton { showingCalibration = true }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(summary?.path.name ?? String(localized: "Ścieżka"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.load() }
        .sheet(item: $selectedStep) { step in
            // Every rung resolves (ProgressionCatalogTests); never show another
            // exercise's sheet in its place.
            if let exercise = ExerciseCatalog.exercise(withID: step.exerciseID) {
                StepDetailSheetView(
                    exercise: exercise,
                    step: step,
                    viewModel: viewModel,
                    environment: environment
                )
            }
        }
        .sheet(isPresented: $showingCalibration) {
            PlacementCalibrationSheet(viewModel: environment.makePlacementCalibrationViewModel())
        }
    }
}

#if DEBUG
// MARK: - Preview
#Preview {
    let environment = AppEnvironment.seeded(
        logs: [
            WorkoutLogEntry(
                exerciseID: ExerciseCatalog.pullUpsID,
                sets: [LoggedSet(reps: 6), LoggedSet(reps: 6), LoggedSet(reps: 6)]
            )
        ],
        placement: SkillPlacement(declaredRungByPath: [.pullUp: 3])
    )
    NavigationStack {
        PathDetailView(environment: environment, pathID: .pullUp)
    }
    .preferredColorScheme(.dark)
}

#Preview("AX5") {
    let environment = AppEnvironment.seeded(
        logs: [
            WorkoutLogEntry(
                exerciseID: ExerciseCatalog.pullUpsID,
                sets: [LoggedSet(reps: 6), LoggedSet(reps: 6), LoggedSet(reps: 6)]
            )
        ],
        placement: SkillPlacement(declaredRungByPath: [.pullUp: 3])
    )
    NavigationStack {
        PathDetailView(environment: environment, pathID: .pullUp)
    }
    .dynamicTypeSize(.accessibility5)
    .preferredColorScheme(.dark)
}
#endif
