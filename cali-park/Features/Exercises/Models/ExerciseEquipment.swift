import Foundation

// MARK: - ExerciseEquipment
/// Polish labels for the equipment keys stored in `Exercise.equipment`.
///
/// Keys added since the park model (ticket 012) are OSM `fitness_station`
/// values (`fitness_pole`, `wall_bars`); the older English keys keep their
/// spelling so stored values still match. A key only changes its label here,
/// never its spelling. Park equipment uses `EquipmentType` instead.
nonisolated enum ExerciseEquipment {
    static func displayName(for key: String) -> String {
        displayNames[key] ?? key
    }

    private static let displayNames: [String: String] = [
        "Pull-up bar": String(localized: "Drążek"),
        "Dip bar": String(localized: "Poręcze do dipów"),
        "Monkey bars": String(localized: "Drabinka pozioma"),
        "fitness_pole": String(localized: "Pionowy drążek"),
        "wall_bars": String(localized: "Drabinki gimnastyczne"),
        "Rings": String(localized: "Kółka"),
        "Push-up handles": String(localized: "Uchwyty do pompek"),
        "Parallel bars": String(localized: "Poręcze"),
        "Resistance bands": String(localized: "Gumy")
    ]
}
