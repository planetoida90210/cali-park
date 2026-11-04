import Foundation

// MARK: - HomeModule
/// A Home module the athlete can show, hide and reorder.
///
/// The raw values are stored in `UserDefaults` (`DefaultsKey.enabledModules`)
/// as the athlete's choice and order, so they must never change.
nonisolated enum HomeModule: String, CaseIterable, Codable, Identifiable, Sendable {
    // The order of the cases is the order of the selection screen.
    // Leaderboard and the Community feed need a backend and arrive in v1.1.
    case lastWorkout = "log"
    case nextWorkout = "next"
    case nearestPark = "parks"
    case weeklyGoal = "goal"
    case streak = "streak"
    case achievements = "achievements"

    var id: Self { self }

    var name: String {
        switch self {
        case .lastWorkout: String(localized: "Ostatni trening")
        case .nextWorkout: String(localized: "Następny trening")
        case .nearestPark: String(localized: "Najbliższy Park")
        case .weeklyGoal: String(localized: "Cel tygodniowy")
        case .streak: String(localized: "Seria dni")
        case .achievements: String(localized: "Osiągnięcia")
        }
    }

    var iconName: String {
        switch self {
        case .lastWorkout: "clock.arrow.circlepath"
        case .nextWorkout: "calendar"
        case .nearestPark: "mappin.and.ellipse"
        case .weeklyGoal: "target"
        case .streak: "flame.fill"
        case .achievements: "star.fill"
        }
    }

    var description: String {
        switch self {
        case .lastWorkout: String(localized: "Twój ostatni zapisany trening.")
        case .nextWorkout: String(localized: "Najbliższy plan albo propozycja treningu.")
        case .nearestPark: String(localized: "Najbliższy Park z mapy Parków.")
        case .weeklyGoal: String(localized: "Postęp celów w tym tygodniu i seria tygodni.")
        case .streak: String(localized: "Dni treningu z rzędu.")
        case .achievements: String(localized: "Twoje odznaki i postępy.")
        }
    }
}
