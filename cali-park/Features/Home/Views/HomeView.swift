import SwiftUI

// MARK: - HomeRoute
/// Push destinations from Home. The primary action rail's "Plany" button
/// resolves to `.plans`; kept type-safe via `navigationDestination(for:)`.
enum HomeRoute: Hashable {
    case plans
}

struct HomeView: View {
    // Real workout data for hero + modules; name stays mocked until the
    // Profile sprint delivers a real user profile.
    @State private var dashboard: HomeDashboardViewModel
    private let userProfile = MockDataProvider.userProfile

    // Module preferences
    @StateObject private var modulePreferences = ModulePreferences()

    // Selected module ID for auto-scrolling
    @State private var selectedModuleId: String? = nil

    // Dragging state for reordering (drag straight on Home, no edit mode)
    @State private var draggingModuleId: String? = nil

    // Module selector state
    @State private var showModuleSelector = false

    // The plan the hero's "Rozpocznij" is starting; presents its quick workout.
    @State private var startingPlan: WorkoutPlan?

    // The open weekly goal editor (long press on the hero ring, or the module).
    @State private var goalEditor: WeeklyGoalEditorViewModel?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let environment: AppEnvironment

    @Environment(\.scenePhase) private var scenePhase

    init(environment: AppEnvironment) {
        self.environment = environment
        _dashboard = State(initialValue: environment.makeHomeDashboardViewModel())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Main background
                Color.appBackground.ignoresSafeArea()

                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            // A. Contextual hero — reacts to today's plan/logs.
                            ContextualHeroView(
                                state: dashboard.heroState(),
                                name: userProfile.name,
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
                        .onChange(of: selectedModuleId) { _, newValue in
                            if let id = newValue {
                                withAnimation {
                                    scrollProxy.scrollTo(id, anchor: .top)
                                }
                                Task {
                                    try? await Task.sleep(for: .seconds(0.5))
                                    selectedModuleId = nil
                                }
                            }
                        }
                    }
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
                            .font(.title3)
                            .foregroundStyle(Color.accent)
                    }
                    .accessibilityLabel("Dostosuj moduły")
                }
            }
            .sheet(isPresented: $showModuleSelector) {
                ModuleSelectionView(modulePreferences: modulePreferences)
            }
            .sheet(item: $goalEditor, onDismiss: { dashboard.reload() }) { editor in
                WeeklyGoalEditorView(viewModel: editor)
            }
            .sheet(item: $startingPlan, onDismiss: { dashboard.reload() }) { plan in
                QuickWorkoutView(
                    viewModel: dashboard.makeQuickWorkoutViewModel(plan: plan),
                    onFinish: { dashboard.reload() }
                )
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
                // Picks up entries logged in the Exercises tab.
                dashboard.reload()
            }
            // onAppear does not fire when the app returns from background, and
            // nothing observed changes at midnight, so "today" would go stale.
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { dashboard.reload() }
            }
            .onReceive(Self.dayChanges) { _ in
                dashboard.reload()
            }
            .alert(dashboard.errorMessage ?? "", isPresented: errorBinding) {
                Button("Rozumiem", role: .cancel) {}
            } message: {
                Text("Spróbuj ponownie.")
            }
        }
        .environmentObject(modulePreferences)
        .overlay {
            if let met = dashboard.goalCelebration, let snapshot = dashboard.weeklyGoal {
                CelebrationOverlayView(
                    presentation: .weeklyGoalMet(met, isPrimary: met.id == snapshot.week.primary.id, streak: snapshot.streak),
                    trigger: "goal-\(met.id.uuidString)-\(snapshot.week.interval.start.timeIntervalSince1970)",
                    hasNext: snapshot.pendingCelebrations.count > 1,
                    onDismiss: { dashboard.dismissGoalCelebration() }
                )
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: dashboard.goalCelebration)
    }

    private func openGoalEditor() {
        goalEditor = environment.makeWeeklyGoalEditorViewModel()
    }

    /// Fires when the calendar day rolls over (or the clock or time zone jumps)
    /// while the app stays in the foreground. The calendar-day notification
    /// may arrive on any thread, so it is delivered on main.
    private static let dayChanges = NotificationCenter.default
        .publisher(for: .NSCalendarDayChanged)
        .merge(with: NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification))
        .receive(on: DispatchQueue.main)

    // Bridges the optional `errorMessage` to a Bool binding for `.alert`.
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { dashboard.errorMessage != nil },
            set: { if !$0 { dashboard.errorMessage = nil } }
        )
    }

    // Smart Stack Modules View
    @ViewBuilder
    private var modulesStackView: some View {
        VStack(spacing: 8) {
            ForEach(modulePreferences.enabledModules, id: \.self) { moduleId in
                ModuleView(moduleId: moduleId, dashboard: dashboard, onEditGoal: openGoalEditor)
                    .id(moduleId)
                    .onDrag({
                        draggingModuleId = moduleId
                        return NSItemProvider(object: moduleId as NSString)
                    }, preview: {
                        // Minimalistic preview to uniknąć miniaturki
                        Color.clear.frame(width: 1, height: 1)
                    })
                    .onDrop(of: [.text], delegate: ModuleDropDelegate(item: moduleId, draggingItem: $draggingModuleId, prefs: modulePreferences))
            }
        }
    }

    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up")
                .font(.largeTitle)
                .foregroundStyle(Color.accent)

            Text("Start jest pusty")
                .font(.title3)
                .foregroundStyle(Color.textPrimary)

            Text("Dodaj moduły, aby zobaczyć tu potrzebne informacje")
                .font(.bodyMedium)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showModuleSelector = true
            } label: {
                Text("Dodaj moduły")
                    .font(.buttonMedium)
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.accent)
                    .clipShape(.rect(cornerRadius: 12))
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 16)
    }
}

// MARK: - Module Selection View
struct ModuleSelectionView: View {
    @ObservedObject var modulePreferences: ModulePreferences
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(ModuleDefinition.allModules) { module in
                        moduleToggleRow(module)
                    }
                } header: {
                    Text("Dostępne moduły")
                } footer: {
                    Text("Włączone moduły będą widoczne na starcie. Kolejność zmienisz, przeciągając moduł.")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Wybierz moduły")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Gotowe") {
                        dismiss()
                    }
                    .foregroundStyle(Color.accent)
                }
            }
        }
    }

    // Module toggle row
    private func moduleToggleRow(_ module: ModuleDefinition) -> some View {
        Toggle(isOn: Binding(
            get: { modulePreferences.enabledModules.contains(module.id) },
            set: { newValue in
                if newValue {
                    if !modulePreferences.enabledModules.contains(module.id) {
                        modulePreferences.enabledModules.append(module.id)
                    }
                } else {
                    modulePreferences.enabledModules.removeAll { $0 == module.id }
                }
            }
        )) {
            HStack {
                // Module icon
                Image(systemName: module.iconName)
                    .font(.title3)
                    .foregroundStyle(Color.accent)
                    .frame(width: 32, height: 32)

                // Module information
                VStack(alignment: .leading, spacing: 2) {
                    Text(module.name)
                        .font(.bodyLarge)
                        .foregroundStyle(Color.textPrimary)

                    Text(module.description)
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .tint(Color.accent)
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview("Plan na dziś") {
    HomeView(environment: .previewPlanToday)
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
