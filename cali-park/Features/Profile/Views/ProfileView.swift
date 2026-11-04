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
                    ProfileWeeklyGoalRow(title: viewModel.weeklyGoalTitle,
                                         progressText: viewModel.weeklyGoalProgressText) {
                        goalEditor = environment.makeWeeklyGoalEditorViewModel()
                    }
                }

                Section {
                    NavigationLink(value: ProfileRoute.history) {
                        ProfileRowLabel(title: "Historia treningów", systemImage: "clock.arrow.circlepath")
                    }
                    .accessibilityIdentifier("profile.history")
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
                case .diagnostics:
                    DiagnosticsView(viewModel: environment.makeDiagnosticsViewModel())
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
}

#if DEBUG
// MARK: - Preview
#Preview {
    ProfileView(environment: .skillsVeteran)
        .preferredColorScheme(.dark)
}
#endif
