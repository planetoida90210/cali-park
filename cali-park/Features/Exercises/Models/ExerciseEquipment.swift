import Foundation

// MARK: - ExerciseEquipment
/// Polish labels for the equipment keys stored in `Exercise.equipment`.
///
/// Keys added since the park model (ticket 012) are OSM `fitness_station`
/// values (`fitness_pole`, `wall_bars`); the older English keys keep their
/// spelling so stored values still match. A key only changes its label here,
/// never its spelling. Park equipment uses `EquipmentType` instead.
enum ExerciseEquipment {
    static func displayName(for key: String) -> String {
        displayNames[key] ?? key
    }

    private static let displayNames: [String: String] = [
        "Pull-up bar": "Drążek",
        "Dip bar": "Poręcze do dipów",
        "Monkey bars": "Drabinka pozioma",
        "fitness_pole": "Pionowy drążek",
        "wall_bars": "Drabinki gimnastyczne",
        "Rings": "Kółka",
        "Push-up handles": "Uchwyty do pompek",
        "Parallel bars": "Poręcze",
        "Resistance bands": "Gumy"
    ]
}
