import SwiftUI

// MARK: - ProfileView
/// The Profile tab (ticket 025): statistics, the weekly goal, a shortcut to
/// the workout history, export and import, help and feedback, and "O apce".
/// There is no Account in this build, so no name, sign-in or logout.
/// Celebrations come from the app-wide `.rewardOverlay()` on the tab root.
struct ProfileView: View {
    @State private var viewModel: ProfileViewModel
    /// The open weekly goal editor.
    @State private var goalEditor: WeeklyGoalEditorViewModel?
    @Environment(\.scenePhase) private var scenePhase

    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
        _viewModel = State(initialValue: environment.makeProfileViewModel())
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ProfileStatisticsGrid(statistics: viewModel.statistics)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section("Cel tygodniowy") {
                    weeklyGoalRow
                }

                Section {
                    NavigationLink(value: ProfileRoute.history) {
                        ProfileRowLabel(title: "Historia treningów", systemImage: "clock.arrow.circlepath")
                    }
                    NavigationLink(value: ProfileRoute.backup) {
                        ProfileRowLabel(title: "Eksport i import treningów", systemImage: "square.and.arrow.up.on.square")
                    }
                }
                .listRowBackground(Color.componentBackground)

                Section {
                    NavigationLink(value: ProfileRoute.help) {
                        ProfileRowLabel(title: "Pomoc i opinie", systemImage: "questionmark.bubble")
                    }
                    NavigationLink(value: ProfileRoute.about) {
                        ProfileRowLabel(title: "O apce", systemImage: "info.circle")
                    }
                }
                .listRowBackground(Color.componentBackground)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: ProfileRoute.self) { route in
                switch route {
                case .history:
                    WorkoutHistoryView(viewModel: environment.makeWorkoutHistoryViewModel())
                case .backup:
                    TrainingBackupView(viewModel: environment.makeTrainingBackupViewModel())
                case .help:
                    HelpFeedbackView()
                case .about:
                    AboutView()
                }
            }
            .sheet(item: $goalEditor, onDismiss: { viewModel.reload() }) { editor in
                WeeklyGoalEditorView(viewModel: editor)
            }
            .onAppear { viewModel.reload() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { viewModel.reload() }
            }
            .alert(viewModel.errorMessage ?? "", isPresented: errorBinding) {
                Button("Rozumiem", role: .cancel) {}
            } message: {
                Text("Spróbuj ponownie.")
            }
        }
    }

    // MARK: Weekly goal
    private var weeklyGoalRow: some View {
        Button {
            goalEditor = environment.makeWeeklyGoalEditorViewModel()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "target")
                    .foregroundStyle(Color.accent)
                    .frame(width: 28)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.weeklyGoalTitle ?? "Cel tygodniowy")
                        .font(.bodyLarge)
                        .foregroundStyle(Color.textPrimary)
                    Text(viewModel.weeklyGoalProgressText.map { "Ten tydzień: \($0)" } ?? "Nie udało się odczytać celu")
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                Text("Zmień")
                    .font(.buttonSmall)
                    .foregroundStyle(Color.accent)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Otwiera edycję celu tygodniowego")
        .listRowBackground(Color.componentBackground)
    }

    // Bridges the optional `errorMessage` to a Bool binding for `.alert`.
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}

// MARK: - ProfileRowLabel
private struct ProfileRowLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label {
            Text(title)
                .font(.bodyLarge)
                .foregroundStyle(Color.textPrimary)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(Color.accent)
        }
    }
}

// MARK: - ProfileStatisticsGrid
/// Four tiles: workouts, day streak, week streak, level with XP progress.
private struct ProfileStatisticsGrid: View {
    let statistics: ProfileStatistics

    var body: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                tile(value: "\(statistics.workouts)",
                     caption: PolishPlural.form(for: statistics.workouts, one: "trening", few: "treningi", many: "treningów"),
                     systemImage: "figure.strengthtraining.functional")
                tile(value: "\(statistics.dayStreak)",
                     caption: "seria dni · rekord \(statistics.longestDayStreak)",
                     systemImage: "flame.fill")
            }
            GridRow {
                tile(value: statistics.weekStreak.map(String.init) ?? "–",
                     caption: "seria tygodni z celem",
                     systemImage: "calendar")
                levelTile
            }
        }
    }

    private func tile(value: String, caption: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.accent)
                .accessibilityHidden(true)
            Text(value)
                .font(.title1)
                .foregroundStyle(Color.textPrimary)
                .monospacedDigit()
            Text(caption)
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
        }
        // Fills the grid cell, so both tiles in a row share one height.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private var levelTile: some View {
        let level = statistics.level
        return VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "trophy.fill")
                .foregroundStyle(Color.accent)
                .accessibilityHidden(true)
            Text("Poziom \(level.level)")
                .font(.title3)
                .foregroundStyle(Color.textPrimary)
            ProgressView(value: level.progressToNextLevel)
                .tint(Color.accent)
            Text("\(level.totalXP) XP · \(level.xpToNextLevel) do następnego")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                // Wraps instead of truncating "do następnego" in the half-width tile.
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Poziom \(level.level), \(level.totalXP) XP, \(level.xpToNextLevel) XP do następnego poziomu")
    }
}

// MARK: - Preview
#Preview {
    ProfileView(environment: .skillsVeteran)
        .preferredColorScheme(.dark)
}
