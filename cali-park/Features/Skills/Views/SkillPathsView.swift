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
                        SkillCalibrationPrompt { showingCalibration = true }
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.summaries) { summary in
                            NavigationLink(value: summary.id) {
                                SkillPathCard(summary: summary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("skills.path.\(summary.id.rawValue)")
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

#if DEBUG
// MARK: - Preview
#Preview("Świeżak — bez placementu") {
    SkillPathsView(environment: .previewEmpty)
        .preferredColorScheme(.dark)
}

#Preview("Placement średni") {
    SkillPathsView(
        environment: .seeded(
            placement: SkillPlacement(declaredRungByPath: [
                .pullUp: 4, .pushUp: 3, .dip: 2, .legs: 2
            ])
        )
    )
    .preferredColorScheme(.dark)
}

#Preview("Weteran — w połowie statyk") {
    SkillPathsView(environment: .skillsVeteran)
        .preferredColorScheme(.dark)
}
#endif
