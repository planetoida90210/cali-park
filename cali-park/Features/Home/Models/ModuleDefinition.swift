import Foundation

// MARK: - ModuleDefinition
/// A Home module the athlete can show, hide and reorder.
nonisolated struct ModuleDefinition: Identifiable, Hashable {
    let id: String
    let name: String
    let iconName: String
    let description: String

    /// Every module available on Home, in the order of the selection screen.
    /// Leaderboard and the Community feed need a backend and arrive in v1.1.
    static let allModules: [ModuleDefinition] = [
        ModuleDefinition(
            id: "log",
            name: String(localized: "Ostatni trening"),
            iconName: "clock.arrow.circlepath",
            description: String(localized: "Twój ostatni zapisany trening.")
        ),
        ModuleDefinition(
            id: "next",
            name: String(localized: "Następny trening"),
            iconName: "calendar",
            description: String(localized: "Najbliższy plan albo propozycja treningu.")
        ),
        ModuleDefinition(
            id: "parks",
            name: String(localized: "Najbliższy Park"),
            iconName: "mappin.and.ellipse",
            description: String(localized: "Najbliższy Park z mapy Parków.")
        ),
        ModuleDefinition(
            id: WeeklyGoalModule.id,
            name: String(localized: "Cel tygodniowy"),
            iconName: "target",
            description: String(localized: "Postęp celów w tym tygodniu i seria tygodni.")
        ),
        ModuleDefinition(
            id: "streak",
            name: String(localized: "Seria dni"),
            iconName: "flame.fill",
            description: String(localized: "Dni treningu z rzędu.")
        ),
        ModuleDefinition(
            id: "achievements",
            name: String(localized: "Osiągnięcia"),
            iconName: "star.fill",
            description: String(localized: "Twoje odznaki i postępy.")
        )
    ]

    static func module(withID id: String) -> ModuleDefinition? {
        allModules.first { $0.id == id }
    }
}
