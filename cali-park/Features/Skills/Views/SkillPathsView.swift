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

    @Environment(\.dynamicTypeSize) private var typeSize

    /// Two cards per row; one at accessibility text sizes, where a half-width
    /// card would cut the path and rung names.
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: typeSize.isAccessibilitySize ? 1 : 2)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    SkillLevelHeader(level: viewModel.level)

                    if viewModel.needsCalibration {
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

                    BadgesSectionView(earned: viewModel.badges)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Ścieżki")
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
                if viewModel.needsCalibration, !hasOfferedCalibration {
                    hasOfferedCalibration = true
                    showingCalibration = true
                }
            }
            .sheet(isPresented: $showingCalibration) {
                PlacementCalibrationSheet(viewModel: environment.makePlacementCalibrationViewModel())
            }
            .errorAlert($viewModel.errorMessage, hint: "Spróbuj ponownie.")
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
                .font(.appTitle)
                .foregroundStyle(Color.textPrimary)
                .contentTransition(.numericText())
                .accessibilityAddTraits(.isHeader)

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
        .clipShape(.rect(cornerRadius: AppRadius.medium))
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
                .font(.appTitle3)
                .foregroundStyle(Color.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text("Zaczniesz od właściwego szczebla, nie od zera.")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)

            Button("Ustaw poziom", action: action)
                .buttonStyle(.accent(.compact))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: AppRadius.medium))
    }
}

// MARK: - SkillPathCard
private struct SkillPathCard: View {
    let summary: SkillPathSummary

    @Environment(\.dynamicTypeSize) private var typeSize

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
                    // Two lines tall side by side, so the bars of cards in one row
                    // line up whether the rung name wraps or not. Cards are alone
                    // in their row at accessibility sizes, so the name may wrap further.
                    .lineLimit(typeSize.isAccessibilitySize ? 4 : 2, reservesSpace: !typeSize.isAccessibilitySize)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ProgressView(value: summary.currentProgress.fractionComplete)
                    .tint(Color.accent)

                Text(MeasureFormat.criterion(for: summary.currentStep))
                    .font(.bodySmall)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .padding(12)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        if summary.state.isComplete {
            return String(localized: "\(summary.path.name). Ukończone.")
        }
        let current = currentExercise?.name ?? ""
        let criterion = MeasureFormat.spokenCriterion(for: summary.currentStep)
        return String(localized: "\(summary.path.name). Teraz: \(current). Cel: \(criterion).")
    }
}

#if DEBUG
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
#endif
