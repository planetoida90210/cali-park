import SwiftUI

// Definicja modułu dla ekranu głównego
struct ModuleDefinition: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let iconName: String
    let description: String
    
    static let allModules: [ModuleDefinition] = [
        ModuleDefinition(
            id: "log",
            name: "Ostatni trening",
            iconName: "clock.arrow.circlepath",
            description: "Twój ostatni zapisany trening"
        ),
        ModuleDefinition(
            id: "next",
            name: "Następny trening",
            iconName: "calendar",
            description: "Najbliższy plan albo propozycja treningu."
        ),
        ModuleDefinition(
            id: "parks",
            name: "Pogoda i siłownia",
            iconName: "mappin.and.ellipse",
            description: "Pogoda i najbliższa siłownia."
        ),
        ModuleDefinition(
            id: "streak",
            name: "Seria dni",
            iconName: "flame.fill",
            description: "Dni treningu z rzędu."
        ),
        // Leaderboard ("friends") and community feed ("feed") are placeholder
        // modules that need a backend. They are intentionally left out of the
        // available list until then; their views stay in the repo, unreferenced.
        ModuleDefinition(
            id: "achievements",
            name: "Osiągnięcia",
            iconName: "star.fill",
            description: "Twoje odznaki i postępy"
        )
    ]
    
    static func getModule(byId id: String) -> ModuleDefinition? {
        return allModules.first { $0.id == id }
    }
}

// Zarządzanie modułami (preferencje użytkownika)
class ModulePreferences: ObservableObject {
    @Published var enabledModules: [String] {
        didSet {
            saveEnabledModules()
        }
    }
    
    // Tryb edycji
    @Published var isEditMode: Bool = false
    
    init() {
        // Domyślnie włączone moduły
        if let savedModules = UserDefaults.standard.stringArray(forKey: "enabledModules") {
            // Drop any modules that no longer exist (e.g. the retired
            // leaderboard/feed placeholders) so stale prefs can't resurface atrapy.
            let known = Set(ModuleDefinition.allModules.map(\.id))
            let filtered = savedModules.filter { known.contains($0) }
            self.enabledModules = filtered
            if filtered != savedModules {
                saveEnabledModules()
            }
        } else {
            // Domyślnie włączone: log, next, parks
            self.enabledModules = ["log", "next", "parks"]
            saveEnabledModules()
        }
    }
    
    private func saveEnabledModules() {
        UserDefaults.standard.set(enabledModules, forKey: "enabledModules")
    }
    
    // Włączanie/wyłączanie modułu
    func toggleModule(_ moduleId: String) {
        if enabledModules.contains(moduleId) {
            enabledModules.removeAll { $0 == moduleId }
        } else {
            enabledModules.append(moduleId)
        }
    }
    
    // Zmiana kolejności modułów (drag & drop)
    func moveModule(from source: IndexSet, to destination: Int) {
        enabledModules.move(fromOffsets: source, toOffset: destination)
    }
} 