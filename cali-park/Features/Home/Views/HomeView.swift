import SwiftUI

struct HomeView: View {
    // Real workout data for hero + modules; name stays mocked until the
    // Profile sprint delivers a real user profile.
    @State private var dashboard: HomeDashboardViewModel
    private let userProfile = MockDataProvider.userProfile

    // Module preferences
    @StateObject private var modulePreferences = ModulePreferences()

    // Edit mode state
    @State private var editMode: EditMode = .inactive

    // Selected module ID for auto-scrolling
    @State private var selectedModuleId: String? = nil

    // Dragging state for reordering
    @State private var draggingModuleId: String? = nil

    // Module selector state
    @State private var showModuleSelector = false

    init(environment: AppEnvironment) {
        _dashboard = State(initialValue: environment.makeHomeDashboardViewModel())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Main background
                Color.appBackground.ignoresSafeArea()

                // Blur overlay when in edit mode
                if editMode.isEditing {
                    Color.black.opacity(0.1)
                        .ignoresSafeArea()
                        .transition(.opacity)
                }

                // Main content (zawsze jeden ScrollView – również w trybie edycji)
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            // A. Hero Card - edge to edge
                            HeroCardView(
                                name: userProfile.name,
                                weeklyReps: dashboard.weeklyPullUps,
                                progress: weeklyProgress
                            )
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
                    if modulePreferences.enabledModules.isEmpty {
                        // Gdy brak modułów – przycisk dodania
                        Button {
                            showModuleSelector = true
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.title3)
                                .foregroundStyle(Color.accent)
                        }
                    } else {
                        // Edit mode toggle button
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                editMode = editMode.isEditing ? .inactive : .active
                            }
                        } label: {
                            if editMode.isEditing {
                                Text("Gotowe")
                                    .foregroundStyle(Color.accent)
                                    .font(.buttonMedium)
                            } else {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.title3)
                                    .foregroundStyle(Color.textPrimary)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showModuleSelector, onDismiss: {
                // Automatycznie wyjdź z trybu edycji po zamknięciu selektora modułów
                if modulePreferences.enabledModules.isEmpty == false {
                    withAnimation {
                        editMode = .inactive
                    }
                }
            }) {
                ModuleSelectionView(modulePreferences: modulePreferences)
            }
            .environment(\.editMode, $editMode)
            .onChange(of: modulePreferences.enabledModules) { _, newValue in
                if newValue.isEmpty {
                    // Automatycznie wyłącz tryb edycji gdy nie ma już modułów
                    editMode = .inactive
                }
            }
            .onAppear {
                // Picks up entries logged in the Exercises tab.
                dashboard.reload()
            }
        }
        .environmentObject(modulePreferences)
    }

    /// Weekly pull-up goal progress (goal stays mocked until the Profile sprint).
    private var weeklyProgress: Double {
        guard userProfile.weeklyGoal > 0 else { return 0 }
        return min(1, Double(dashboard.weeklyPullUps) / Double(userProfile.weeklyGoal))
    }

    // Smart Stack Modules View
    @ViewBuilder
    private var modulesStackView: some View {
        VStack(spacing: 8) {
            ForEach(modulePreferences.enabledModules, id: \.self) { moduleId in
                ModuleView(moduleId: moduleId, dashboard: dashboard)
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

            if !modulePreferences.enabledModules.isEmpty {
                addMoreModulesButton
            }
        }
    }

    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up")
                .font(.largeTitle)
                .foregroundStyle(Color.accent)

            Text("Ekran główny jest pusty")
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

    // Add more modules button for normal mode (not edit mode)
    private var addMoreModulesButton: some View {
        Button {
            showModuleSelector = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.body)

                Text("Dostosuj moduły")
                    .font(.bodyMedium)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .foregroundStyle(Color.accent)
            .background(Color.glassBackground.opacity(0.5))
            .clipShape(.rect(cornerRadius: 12))
            .padding(.top, 8)
        }
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
                    Text("Włączone moduły będą widoczne na ekranie głównym. Możesz zmieniać ich kolejność na ekranie głównym w trybie edycji.")
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
#Preview {
    HomeView(environment: .preview)
        .preferredColorScheme(.dark)
}
