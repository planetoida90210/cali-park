import SwiftUI

// MARK: - SkillPathsView
/// The Skills tab: the athlete's level and XP up top, then a card per
/// progression path showing where they train now and how close the next rung
/// is. Tapping a card opens its ladder. Paths are independent, so the grid never
/// implies one unlocks another.
struct SkillPathsView: View {
    @State private var viewModel: SkillPathsViewModel
    @State private var showingCalibration = false
    @State private var hasOfferedCalibration = false

    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
        _viewModel = State(initialValue: environment.makeSkillPathsViewModel())
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    SkillLevelHeader(level: viewModel.level)

                    if !viewModel.hasPlacement {
                        CalibrationPrompt { showingCalibration = true }
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.summaries) { summary in
                            NavigationLink(value: summary.id) {
                                SkillPathCard(summary: summary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Skille")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCalibration = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(Color.accent)
                    }
                    .accessibilityLabel("Ustaw poziom")
                }
            }
            .navigationDestination(for: ProgressionPathID.self) { pathID in
                PathDetailView(environment: environment, pathID: pathID)
            }
            .onAppear {
                viewModel.load()
                if !viewModel.hasPlacement, !hasOfferedCalibration {
                    hasOfferedCalibration = true
                    showingCalibration = true
                }
            }
            .sheet(isPresented: $showingCalibration, onDismiss: { viewModel.load() }) {
                PlacementCalibrationSheet(viewModel: environment.makePlacementCalibrationViewModel())
            }
        }
    }
}

// MARK: - SkillLevelHeader
/// Level and XP progress. Numbers animate on change so a fresh workout reads as
/// forward motion.
private struct SkillLevelHeader: View {
    let level: PlayerLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Poziom \(level.level)")
                .font(.title1)
                .foregroundStyle(Color.textPrimary)
                .contentTransition(.numericText())

            ProgressView(value: level.progressToNextLevel)
                .tint(Color.accent)

            Text("\(level.xpToNextLevel) XP do poziomu \(level.level + 1)")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Poziom \(level.level)")
        .accessibilityValue("\(level.xpToNextLevel) XP do poziomu \(level.level + 1)")
    }
}

// MARK: - CalibrationPrompt
/// First-contact nudge for athletes who skipped onboarding placement.
private struct CalibrationPrompt: View {
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ustaw swój poziom")
                .font(.title3)
                .foregroundStyle(Color.textPrimary)

            Text("Zaczniesz od właściwego szczebla, nie od zera.")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)

            Button(action: action) {
                Text("Ustaw poziom")
                    .font(.buttonMedium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accent)
                    .foregroundStyle(Color.black)
                    .clipShape(.rect(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: 12))
    }
}

// MARK: - SkillPathCard
private struct SkillPathCard: View {
    let summary: SkillPathSummary

    private var currentExercise: Exercise? {
        ExerciseCatalog.exercise(withID: summary.currentStep.exerciseID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ExerciseIconView(symbolName: summary.path.symbolName, size: .row)

            Text(summary.path.name)
                .font(.bodyLarge)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)

            if summary.state.isComplete {
                Label("Ukończone", systemImage: "checkmark.seal.fill")
                    .font(.bodySmall)
                    .foregroundStyle(Color.accent)
            } else {
                Text(currentExercise?.name ?? "")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ProgressView(value: summary.currentProgress.fractionComplete)
                    .tint(Color.accent)

                Text(ProgressionFormat.criterion(summary.currentStep.criterion))
                    .font(.bodySmall)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .padding(12)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        if summary.state.isComplete {
            return "\(summary.path.name). Ukończone."
        }
        return "\(summary.path.name). Teraz: \(currentExercise?.name ?? ""). Cel: \(ProgressionFormat.spokenCriterion(summary.currentStep.criterion))."
    }
}

// MARK: - Preview
#Preview("Świeżak — bez placementu") {
    SkillPathsView(environment: .previewEmpty)
        .preferredColorScheme(.dark)
}

#Preview("Placement średni") {
    SkillPathsView(environment: .seeded(
        placement: SkillPlacement(declaredRungByPath: [
            .pullUp: 4, .pushUp: 3, .dip: 2, .legs: 2
        ])
    ))
    .preferredColorScheme(.dark)
}

#Preview("Weteran — w połowie statyk") {
    SkillPathsView(environment: .skillsVeteran)
        .preferredColorScheme(.dark)
}
