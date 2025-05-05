import SwiftUI

struct HomeView: View {
    // User data
    @State private var userProfile = MockDataProvider.userProfile
    @State private var dailyChallenge = MockDataProvider.dailyChallenge
    
    // Module preferences
    @StateObject private var modulePreferences = ModulePreferences()
    
    // Edit mode state
    @State private var editMode: EditMode = .inactive
    
    // Selected module ID for auto-scrolling
    @State private var selectedModuleId: String? = nil
    
    // Dragging state for reordering
    @State private var draggingModuleId: String? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main background
                Color.appBackground.edgesIgnoringSafeArea(.all)
                
                // Blur overlay when in edit mode
                if editMode.isEditing {
                    Color.black.opacity(0.1)
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                }
                
                // Main content (zawsze jeden ScrollView – również w trybie edycji)
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            // A. Hero Card - edge to edge
                            HeroCardView(
                                name: userProfile.name,
                                weeklyReps: userProfile.weeklyPullUps,
                                progress: userProfile.weeklyProgress
                            )
                            .padding(.bottom, 18)
                            
                            // B. Primary Action Rail
                            PrimaryActionRailView()
                                .padding(.bottom, 18)
                            
                            // C. Smart Stack (Modules)
                            if modulePreferences.enabledModules.isEmpty {
                                emptyStateView
                            } else {
                                modulesStackView
                            }
                            
                            Spacer().frame(height: 12)
                        }
                        .padding(.bottom, 12)
                        .onChange(of: selectedModuleId) { oldValue, newValue in
                            if let id = newValue {
                                withAnimation {
                                    scrollProxy.scrollTo(id, anchor: .top)
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    selectedModuleId = nil
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if modulePreferences.enabledModules.isEmpty {
                        // Gdy brak modułów – przycisk dodania
                        Button(action: { showModuleSelector = true }) {
                            Image(systemName: "plus.circle")
                                .font(.title3)
                                .foregroundColor(.accent)
                        }
                    } else {
                        // Edit mode toggle button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                editMode = editMode.isEditing ? .inactive : .active
                            }
                        }) {
                            if editMode.isEditing {
                                Text("✓ Gotowe")
                                    .foregroundColor(.accent)
                                    .font(.buttonMedium)
                            } else {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.title3)
                                    .foregroundColor(.textPrimary)
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
            .onChange(of: modulePreferences.enabledModules) { oldValue, newValue in
                if newValue.isEmpty {
                    // Automatycznie wyłącz tryb edycji gdy nie ma już modułów
                    editMode = .inactive
                }
            }
        }
        .environmentObject(modulePreferences)
    }
    
    // Smart Stack Modules View
    @ViewBuilder
    private var modulesStackView: some View {
        VStack(spacing: 10) {
            ForEach(modulePreferences.enabledModules, id: \.self) { moduleId in
                ModuleView(moduleId: moduleId)
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
                .font(.system(size: 50))
                .foregroundColor(.accent)
            
            Text("Ekran główny jest pusty")
                .font(.title3)
                .foregroundColor(.textPrimary)
            
            Text("Dodaj moduły, aby zobaczyć tu potrzebne informacje")
                .font(.bodyMedium)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: { showModuleSelector = true }) {
                Text("Dodaj moduły")
                    .font(.buttonMedium)
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.accent)
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 16)
    }
    
    // Add more modules button for normal mode (not edit mode)
    private var addMoreModulesButton: some View {
        Button(action: { showModuleSelector = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.body)
                
                Text("Dostosuj moduły")
                    .font(.bodyMedium)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .foregroundColor(.accent)
            .background(Color.glassBackground.opacity(0.5))
            .cornerRadius(12)
            .padding(.top, 8)
        }
    }
    
    // Module selector state
    @State private var showModuleSelector = false
}

// MARK: - Module Selection View
struct ModuleSelectionView: View {
    @ObservedObject var modulePreferences: ModulePreferences
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Dostępne moduły")) {
                    ForEach(ModuleDefinition.allModules) { module in
                        moduleToggleRow(module)
                    }
                }
                
                Section(footer: Text("Włączone moduły będą widoczne na ekranie głównym. Możesz zmieniać ich kolejność na ekranie głównym w trybie edycji.")) {
                    // Empty view for footer
                    EmptyView()
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Wybierz moduły")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Zapisz") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.accent)
                }
            }
        }
    }
    
    // Module toggle row
    private func moduleToggleRow(_ module: ModuleDefinition) -> some View {
        HStack {
            // Module icon
            Image(systemName: module.iconName)
                .font(.title3)
                .foregroundColor(.accent)
                .frame(width: 32, height: 32)
            
            // Module information
            VStack(alignment: .leading, spacing: 2) {
                Text(module.name)
                    .font(.bodyLarge)
                    .foregroundColor(.textPrimary)
                
                Text(module.description)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // Module toggle
            Toggle("", isOn: Binding(
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
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .preferredColorScheme(.dark)
    }
} 