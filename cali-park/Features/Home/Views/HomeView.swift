import SwiftUI

struct HomeView: View {
    // Real workout data for hero + modules.
    @State private var dashboard: HomeDashboardViewModel
    // Nearest real Park for the "parks" module.
    @State private var nearestPark: NearestParkViewModel

    // The module being dragged to a new place, if any.
    @State private var moduleDrag = ModuleDragState()

    // Module selector state
    @State private var showModuleSelector = false

    // Bumped to re-run the nearest-Park lookup (return to the app or to Home).
    @State private var nearestParkRefresh = 0

    // The plan the hero's "Rozpocznij" is starting; presents its quick workout.
    @State private var startingPlan: WorkoutPlan?

    // The open weekly goal editor (long press on the hero ring, or the module).
    @State private var goalEditor: WeeklyGoalEditorViewModel?

    private let environment: AppEnvironment

    @Environment(\.scenePhase) private var scenePhase

    init(environment: AppEnvironment) {
        self.environment = environment
        _dashboard = State(initialValue: environment.makeHomeDashboardViewModel())
        _nearestPark = State(initialValue: environment.makeNearestParkViewModel())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Main background
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // A. Contextual hero — reacts to today's plan/logs.
                        ContextualHeroView(
                            state: dashboard.heroState(),
                            weeklyGoal: dashboard.weeklyGoal,
                            progressionHint: dashboard.progressionHint,
                            now: dashboard.now,
                            onStartPlan: { startingPlan = $0 },
                            onEditGoal: openGoalEditor
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)

                        // B. Primary Action Rail
                        PrimaryActionRailView(dashboard: dashboard)
                            .padding(.bottom, 16)

                        // C. Smart Stack (Modules)
                        if modulePreferences.enabledModules.isEmpty {
                            emptyStateView
                        } else {
                            modulesStackView
                        }

                        Spacer().frame(height: 12)
                    }
                    .padding(.bottom, 12)
                    // A module dropped on the hero or between modules still
                    // ends the drag.
                    .onDrop(of: [.text], delegate: ModuleDropDelegate(targetID: nil, drag: moduleDrag, preferences: modulePreferences))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // One entry point to customize modules (add / remove / toggle).
                    Button {
                        showModuleSelector = true
                    } label: {
                        Image(systemName: modulePreferences.enabledModules.isEmpty ? "plus.circle" : "slider.horizontal.3")
                            .font(.appTitle3)
                            .foregroundStyle(Color.accent)
                    }
                    .accessibilityLabel("Dostosuj moduły")
                }
            }
            .sheet(isPresented: $showModuleSelector) {
                ModuleSelectionView(preferences: modulePreferences)
            }
            .sheet(item: $goalEditor, onDismiss: { dashboard.reload() }) { editor in
                WeeklyGoalEditorView(viewModel: editor)
            }
            .sheet(item: $startingPlan) { plan in
                QuickWorkoutView(viewModel: dashboard.makeQuickWorkoutViewModel(plan: plan))
            }
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .plans:
                    WorkoutPlansView(environment: environment)
                }
            }
            .navigationDestination(for: WorkoutSessionRoute.self) { route in
                WorkoutSessionDetailView(
                    viewModel: dashboard.makeWorkoutSessionDetailViewModel(sessionID: route.sessionID)
                )
            }
            .onAppear {
                // Picks up plans changed in the Planner. Workouts need no
                // reload: Home reads the shared journal.
                dashboard.reload()
                // Picks up location allowed on the Parks map meanwhile.
                nearestParkRefresh += 1
            }
            // Also re-runs when the user answers the location prompt on the
            // Parks map or changes it in Settings.
            .task(id: NearestParkRefreshKey(tick: nearestParkRefresh,
                                            authorization: environment.locationProvider.authorization)) {
                await nearestPark.refresh()
            }
            // onAppear does not fire when the app returns from background, and
            // nothing observed changes at midnight, so "today" would go stale.
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    dashboard.reload()
                    nearestParkRefresh += 1
                }
            }
            // The calendar day rolls over (or the clock or time zone jumps)
            // while Home stays on screen. Coming back to Home reloads in
            // onAppear anyway.
            .task { await reloadOnEach(.NSCalendarDayChanged) }
            .task { await reloadOnEach(UIApplication.significantTimeChangeNotification) }
            .errorAlert($dashboard.errorMessage, hint: "Spróbuj ponownie.")
        }
    }

    /// Which modules are shown and in what order, shared app-wide.
    private var modulePreferences: ModulePreferences { environment.modulePreferences }

    private func openGoalEditor() {
        goalEditor = environment.makeWeeklyGoalEditorViewModel()
    }

    /// Reloads the dashboard on every `name` notification until the task is
    /// cancelled. The loop runs on the main actor, whichever thread posts.
    private func reloadOnEach(_ name: Notification.Name) async {
        for await _ in NotificationCenter.default.notifications(named: name) {
            dashboard.reload()
        }
    }

    // Smart Stack Modules View
    @ViewBuilder
    private var modulesStackView: some View {
        VStack(spacing: 8) {
            ForEach(modulePreferences.enabledModules) { module in
                ModuleView(
                    module: module,
                    dashboard: dashboard,
                    nearestPark: nearestPark,
                    preferences: modulePreferences,
                    isDragging: moduleDrag.liftedID == module.id,
                    onEditGoal: openGoalEditor
                )
                .onDrag {
                    let token = moduleDrag.begin(module.id)
                    return ModuleDragItemProvider(module: module) { [moduleDrag] in
                        moduleDrag.end(token)
                    }
                } preview: {
                    ModuleDragPreview(module: module)
                }
                .onDrop(of: [.text], delegate: ModuleDropDelegate(targetID: module.id, drag: moduleDrag, preferences: modulePreferences))
            }
        }
    }

    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up")
                .font(.appLargeTitle)
                .foregroundStyle(Color.accent)
                .accessibilityHidden(true)

            Text("Start jest pusty")
                .font(.appTitle3)
                .foregroundStyle(Color.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text("Dodaj moduły, aby zobaczyć tu potrzebne informacje")
                .font(.bodyMedium)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Dodaj moduły") {
                showModuleSelector = true
            }
            .buttonStyle(.accent(.compact, fillsWidth: false))
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 16)
    }
}

// MARK: - NearestParkRefreshKey
/// Re-runs the nearest-Park lookup on every bump or authorization change.
private struct NearestParkRefreshKey: Equatable {
    let tick: Int
    let authorization: LocationAuthorization
}

// MARK: - Preview
#Preview("Plan na dziś") {
    HomeView(environment: .previewPlanToday)
        .preferredColorScheme(.dark)
}

#Preview("Plan na dziś · AX5") {
    HomeView(environment: .previewPlanToday)
        .dynamicTypeSize(.accessibility5)
        .preferredColorScheme(.dark)
}


#Preview("Trening zrobiony dziś") {
    HomeView(environment: .previewCompletedToday)
        .preferredColorScheme(.dark)
}

#Preview("Pusty start") {
    HomeView(environment: .previewEmpty)
        .preferredColorScheme(.dark)
}
