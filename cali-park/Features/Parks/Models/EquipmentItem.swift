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
        case .mobility: "Mobility"
        case .extra: "Extra"
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