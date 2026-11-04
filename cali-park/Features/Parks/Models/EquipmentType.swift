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
        case .horizontalBar: "Drążek"
        case .parallelBars: "Poręcze"
        case .dipBench: "Poręcze do dipów"
        case .rings: "Kółka"
        case .horizontalLadder: "Drabinka pozioma"
        case .wallBars: "Drabinki gimnastyczne"
        case .fitnessPole: "Pionowy drążek"
        case .climbingPole: "Słup do wspinania"
        case .captainsChair: "Poręcze z oparciem"
        case .pushUp: "Niskie drążki do pompek"
        case .sitUp: "Ławka do brzuszków"
        case .stretchBars: "Drążki do rozciągania"
        case .box: "Skrzynia do skoków"
        case .balanceBeam: "Równoważnia"
        case .battlingRopes: "Liny"
        case .tire: "Opona"
        case .punchingBag: "Worek bokserski"
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
