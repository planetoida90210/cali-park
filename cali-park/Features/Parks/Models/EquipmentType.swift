import Foundation

// MARK: - EquipmentType
/// Park equipment. Raw values are OSM `fitness_station` values 1:1 (012 §3), so
/// importing from and contributing back to OSM needs no mapping. Polish names
/// are UI only. Case order is display order.
///
/// Machines (ellipticals, rowers…) are deliberately not here: they never make
/// a Park and are only flagged through `Park.hasMachines`.
nonisolated enum EquipmentType: String, Codable, Hashable, Sendable, CaseIterable, Identifiable {
    case horizontalBar = "horizontal_bar"
    case parallelBars = "parallel_bars"
    case dipBench = "dip_bench"
    case rings
    case horizontalLadder = "horizontal_ladder"
    case wallBars = "wall_bars"
    case fitnessPole = "fitness_pole"
    case climbingPole = "climbing_pole"
    case captainsChair = "captains_chair"
    case pushUp = "push-up"
    case sitUp = "sit-up"
    case stretchBars = "stretch_bars"
    case box
    case balanceBeam = "balance_beam"
    case battlingRopes = "battling_ropes"
    case tire
    case punchingBag = "punching_bag"

    var id: String { rawValue }

    /// Core equipment makes a place a Park on its own: a pull-up bar or
    /// parallel bars, dip bars included (012, owner's decision).
    var isCore: Bool {
        switch self {
        case .horizontalBar, .parallelBars, .dipBench: true
        default: false
        }
    }

    var title: String {
        switch self {
        case .horizontalBar: String(localized: "Drążek")
        case .parallelBars: String(localized: "Poręcze")
        case .dipBench: String(localized: "Poręcze do dipów")
        case .rings: String(localized: "Kółka")
        case .horizontalLadder: String(localized: "Drabinka pozioma")
        case .wallBars: String(localized: "Drabinki gimnastyczne")
        case .fitnessPole: String(localized: "Pionowy drążek")
        case .climbingPole: String(localized: "Słup do wspinania")
        case .captainsChair: String(localized: "Poręcze z oparciem")
        case .pushUp: String(localized: "Niskie drążki do pompek")
        case .sitUp: String(localized: "Ławka do brzuszków")
        case .stretchBars: String(localized: "Drążki do rozciągania")
        case .box: String(localized: "Skrzynia do skoków")
        case .balanceBeam: String(localized: "Równoważnia")
        case .battlingRopes: String(localized: "Liny")
        case .tire: String(localized: "Opona")
        case .punchingBag: String(localized: "Worek bokserski")
        }
    }

    /// Temporary SF Symbols until custom equipment icons exist (ticket 011).
    var symbol: String {
        switch self {
        case .horizontalBar: "figure.climbing"
        case .parallelBars, .dipBench: "figure.strengthtraining.functional"
        case .rings: "figure.gymnastics"
        case .horizontalLadder, .wallBars: "stairs"
        case .fitnessPole, .climbingPole: "flag"
        case .captainsChair, .sitUp: "figure.core.training"
        case .pushUp: "figure.strengthtraining.traditional"
        case .stretchBars: "figure.flexibility"
        case .box: "shippingbox"
        case .balanceBeam: "figure.walk"
        case .battlingRopes: "figure.mixed.cardio"
        case .tire: "circle.circle"
        case .punchingBag: "figure.boxing"
        }
    }
}
