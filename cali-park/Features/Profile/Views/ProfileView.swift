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
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .body) private var iconWidth: CGFloat = 28

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
            .errorAlert($viewModel.errorMessage, hint: "Spróbuj ponownie.")
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
                    .frame(width: iconWidth)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.weeklyGoalTitle ?? String(localized: "Cel tygodniowy"))
                        .font(.bodyLarge)
                        .foregroundStyle(Color.textPrimary)
                    Text(viewModel.weeklyGoalProgressText.map { String(localized: "Ten tydzień: \($0)") }
                         ?? String(localized: "Nie udało się odczytać celu"))
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                    // At accessibility sizes "Zmień" moves under the text, so
                    // the goal keeps the row's full width.
                    if typeSize.isAccessibilitySize {
                        changeLabel
                            .padding(.top, 4)
                    }
                }

                if !typeSize.isAccessibilitySize {
                    Spacer()
                    changeLabel
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Otwiera edycję celu tygodniowego")
        .listRowBackground(Color.componentBackground)
    }

    private var changeLabel: some View {
        Text("Zmień")
            .font(.buttonSmall)
            .foregroundStyle(Color.accent)
    }
}

// MARK: - ProfileRowLabel
private struct ProfileRowLabel: View {
    let title: LocalizedStringKey
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

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        if typeSize.isAccessibilitySize {
            // Half-width tiles can't hold accessibility text sizes: one per row.
            VStack(spacing: 12) {
                workoutsTile
                dayStreakTile
                weekStreakTile
                levelTile
            }
        } else {
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    workoutsTile
                    dayStreakTile
                }
                GridRow {
                    weekStreakTile
                    levelTile
                }
            }
        }
    }

    private var workoutsTile: some View {
        tile(value: "\(statistics.workouts)",
             caption: PolishPlural.form(for: statistics.workouts, one: "trening", few: "treningi", many: "treningów"),
             systemImage: "figure.strengthtraining.functional")
    }

    private var dayStreakTile: some View {
        tile(value: "\(statistics.dayStreak)",
             caption: String(localized: "seria dni · rekord \(statistics.longestDayStreak)"),
             systemImage: "flame.fill")
    }

    private var weekStreakTile: some View {
        tile(value: statistics.weekStreak.map(String.init) ?? "–",
             caption: String(localized: "seria tygodni z celem"),
             systemImage: "calendar")
    }

    private func tile(value: String, caption: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.accent)
                .accessibilityHidden(true)
            Text(value)
                .font(.appTitle)
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
        .clipShape(.rect(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private var levelTile: some View {
        let level = statistics.level
        return VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "trophy.fill")
                .foregroundStyle(Color.accent)
                .accessibilityHidden(true)
            Text("Poziom \(level.level)")
                .font(.appTitle3)
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
        .clipShape(.rect(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Poziom \(level.level), \(level.totalXP) XP, \(level.xpToNextLevel) XP do następnego poziomu")
    }
}

// MARK: - Preview
#Preview {
    ProfileView(environment: .skillsVeteran)
        .preferredColorScheme(.dark)
}
