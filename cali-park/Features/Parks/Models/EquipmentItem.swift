import SwiftUI

// MARK: - EquipmentCategory
/// High-level grouping for park equipment used across the app.
enum EquipmentCategory: String, Codable, CaseIterable, Identifiable {
    case strength
    case mobility
    case extra

    // User-facing title
    var title: String {
        switch self {
        case .strength: "Siła"
        case .mobility: "Mobilność"
        case .extra: "Inne"
        }
    }

    var id: String { rawValue }
}

// MARK: - EquipmentItem
/// Unified description of a single equipment piece – name, category and SF Symbol.
struct EquipmentItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: EquipmentCategory
    let symbol: String

    /// Polish label. `name` stays the stored key shared with park data.
    var displayName: String {
        Self.displayName(for: name)
    }

    static func displayName(for key: String) -> String {
        displayNames[key] ?? key
    }

    static func shortName(for key: String) -> String {
        shortNames[key] ?? displayName(for: key)
    }

    private static let displayNames: [String: String] = [
        "Pull-up bar": "Drążek",
        "Dip bar": "Poręcze do dipów",
        "Monkey bars": "Drabinki",
        "Rings": "Kółka",
        "Push-up handles": "Uchwyty do pompek",
        "Parallel bars": "Poręcze",
        "Climbing rope": "Lina",
        "Box jump": "Skrzynia",
        "Battle ropes": "Liny",
        "Sledge hammer": "Młot",
        "Kettlebell": "Kettlebell",
        "Medicine ball": "Piłka lekarska",
        "Resistance bands": "Gumy",
        "Tires": "Opony"
    ]

    private static let shortNames: [String: String] = [
        "Pull-up bar": "Drążek",
        "Dip bar": "Dipy",
        "Monkey bars": "Drabinki",
        "Rings": "Kółka",
        "Push-up handles": "Pompki",
        "Parallel bars": "Poręcze",
        "Climbing rope": "Lina",
        "Box jump": "Skrzynia",
        "Battle ropes": "Liny",
        "Sledge hammer": "Młot",
        "Kettlebell": "Kettlebell",
        "Medicine ball": "Piłka",
        "Resistance bands": "Gumy",
        "Tires": "Opony"
    ]
}

// MARK: - Static Mapping
extension EquipmentItem {
    /// Static lookup table – single source of truth for mapping strings → metadata.
    private static let lookup: [String: (EquipmentCategory, String)] = [
        "Pull-up bar": (.strength, "figure.pullup"),
        "Dip bar": (.strength, "flame"),
        "Monkey bars": (.strength, "rectangle.3.offgrid"),
        "Rings": (.strength, "circle.grid.cross"),
        "Push-up handles": (.strength, "hands.sparkles"),
        "Parallel bars": (.strength, "line.3.horizontal.decrease"),
        "Climbing rope": (.strength, "scribble.variable"),
        "Box jump": (.strength, "square.split.2x2"),
        "Battle ropes": (.strength, "waveform.path"),
        "Sledge hammer": (.strength, "hammer"),
        "Kettlebell": (.strength, "dumbbell"),
        "Medicine ball": (.strength, "circle.hexagonpath"),
        "Resistance bands": (.mobility, "arrow.triangle.2.circlepath"),
        "Tires": (.extra, "circle.dashed"),
    ]

    /// Convert raw names to typed items. Unknown names fall back to `.extra` + `questionmark` symbol.
    static func items(from names: [String]) -> [EquipmentItem] {
        names.map { name in
            let info = lookup[name] ?? (.extra, "questionmark")
            return EquipmentItem(name: name, category: info.0, symbol: info.1)
        }
    }
} 