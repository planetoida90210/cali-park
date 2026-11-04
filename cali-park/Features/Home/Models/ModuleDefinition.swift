import Foundation

// MARK: - ModuleDefinition
/// A Home module the athlete can show, hide and reorder.
struct ModuleDefinition: Identifiable, Hashable {
    let id: String
    let name: String
    let iconName: String
    let description: String

    /// Every module available on Home, in the order of the selection screen.
    /// Leaderboard and the Community feed need a backend and arrive in v1.1.
    static let allModules: [ModuleDefinition] = [
        ModuleDefinition(
            id: "log",
            name: "Ostatni trening",
            iconName: "clock.arrow.circlepath",
            description: "Twój ostatni zapisany trening."
        ),
        ModuleDefinition(
            id: "next",
            name: "Następny trening",
            iconName: "calendar",
            description: "Najbliższy plan albo propozycja treningu."
        ),
        ModuleDefinition(
            id: "parks",
            name: "Najbliższy Park",
            iconName: "mappin.and.ellipse",
            description: "Najbliższy Park z mapy Parków."
        ),
        ModuleDefinition(
            id: WeeklyGoalModule.id,
            name: "Cel tygodniowy",
            iconName: "target",
            description: "Postęp celów w tym tygodniu i seria tygodni."
        ),
        ModuleDefinition(
            id: "streak",
            name: "Seria dni",
            iconName: "flame.fill",
            description: "Dni treningu z rzędu."
        ),
        ModuleDefinition(
            id: "achievements",
            name: "Osiągnięcia",
            iconName: "star.fill",
            description: "Twoje odznaki i postępy."
        )
    ]

    static func module(withID id: String) -> ModuleDefinition? {
        allModules.first { $0.id == id }
    }
}
