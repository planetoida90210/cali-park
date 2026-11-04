import Foundation

// MARK: - CriterionSource
/// Where a rung's advancement criterion comes from, shown next to the target
/// so the athlete can tell a sourced rule from our own convention.
///
/// The labels match the "Źródła" section of `docs/PROGRESSIONS.md` 1:1. A
/// rung's own source (which ladder in which book lists it) is documented
/// there too; only the criterion's source lives in code.
nonisolated enum CriterionSource: String, Codable, CaseIterable, Sendable {
    /// Recommended Routine, r/bodyweightfitness wiki.
    case rr
    /// Overcoming Gravity, 2nd ed. (Steven Low), a level from the chart.
    case og2
    /// Derived from the OG2 isometrics table; not stated there as a rule.
    case og2Table
    /// GMB's six L-sit steps.
    case gmb
    /// StartBodyweight.
    case sbw
    /// Cali Move's pull-up challenge (only facts about bands and negatives).
    case caliMove
    /// Our own rule, with no source behind it. Shown honestly as ours.
    case caliPark

    /// The short label shown in the app and in `PROGRESSIONS.md`.
    var label: String {
        switch self {
        case .rr: "RR"
        case .og2: "OG2"
        case .og2Table: "OG2 (tabela)"
        case .gmb: "GMB"
        case .sbw: "SBW"
        case .caliMove: "Cali Move"
        case .caliPark: "konwencja CaliPark"
        }
    }

    /// The rung sheet's source line, e.g. "Skąd to kryterium? Zasada z
    /// Recommended Routine (r/bodyweightfitness)." The explanation names the
    /// source in full, so the short `label` would only repeat it.
    var sourceLine: String {
        "Skąd to kryterium? \(explanation)"
    }

    /// One sentence answering "Skąd to kryterium?" in the rung sheet.
    var explanation: String {
        switch self {
        case .rr: "Zasada z Recommended Routine (r/bodyweightfitness)."
        case .og2: "Poziom z Overcoming Gravity, 2. wydanie."
        case .og2Table: "Wyprowadzone z tabeli izometrii Overcoming Gravity, 2. wydanie."
        case .gmb: "Kroki L-situ według GMB."
        case .sbw: "Zasada ze StartBodyweight."
        case .caliMove: "Z wyzwania podciągnięć Cali Move."
        case .caliPark: "Nasza reguła, bez zewnętrznego źródła."
        }
    }
}
