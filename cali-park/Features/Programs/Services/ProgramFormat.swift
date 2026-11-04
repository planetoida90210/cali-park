import Foundation

// MARK: - ProgramFormat
/// Polish labels for program and plan items: what to do on an item ("3 × 5–8
/// na nogę"), the pair or circuit it belongs to, and its rest. Shared by the
/// program detail screen and the plan editor so both read the same.
nonisolated enum ProgramFormat {
    /// What to do, e.g. "3 × 5–8", "3 × 10–30 s", "2–6 rund · 1–2 powtórzenia
    /// w zapasie", "do 10 min praktyki" or "łącznie do 3 min, holdy 10–30 s".
    /// `nil` when the item has no target at all (a plan built by hand).
    static func doseSummary(for planned: PlannedExercise, exercise: Exercise?) -> String? {
        let side = exercise?.unilateralSide.map { " " + $0.label } ?? ""

        if let minutes = planned.timeBoxMinutes {
            return "do \(minutes) min praktyki"
        }
        if let total = planned.totalSeconds {
            var text = "łącznie do \(duration(total))"
            if let hold = range(planned.targetSecondsMin, planned.targetSeconds) {
                text += ", holdy \(hold) s\(side)"
            }
            return text
        }
        if let rounds = planned.rounds {
            var text = "\(rangeText(rounds)) \(PolishPlural.form(for: rounds.upperBound, one: "runda", few: "rundy", many: "rund"))"
            if let reserve = planned.repsInReserve {
                text += " · " + reserveText(reserve) + side
            }
            return text
        }
        if let sets = planned.targetSets {
            if let reps = range(planned.targetRepsMin, planned.targetReps) {
                return "\(sets) × \(reps)\(side)"
            }
            if let hold = range(planned.targetSecondsMin, planned.targetSeconds) {
                return "\(sets) × \(hold) s\(side)"
            }
        }
        return nil
    }

    /// "Para 1" for a two-item group, "Obwód" for a circuit (rounds), "Blok 2"
    /// otherwise; `nil` for an item done on its own.
    static func groupLabel(for planned: PlannedExercise, in items: [PlannedExercise]) -> String? {
        guard let group = planned.group else { return nil }
        if planned.rounds != nil { return "Obwód" }
        let size = items.filter { $0.group == group }.count
        return size == 2 ? "Para \(group)" : "Blok \(group)"
    }

    /// "przerwa 90 s", or `nil` without a set rest.
    static func restSummary(for planned: PlannedExercise) -> String? {
        planned.restSeconds.map { "przerwa \($0) s" }
    }

    /// "Program Fundamenty · wersja 1".
    static func originLine(for program: TrainingProgram, version: Int?) -> String {
        "Program \(program.name) · wersja \(version ?? program.version)"
    }

    // MARK: Helpers

    /// "1 powtórzenie w zapasie" or "1–2 powtórzenia w zapasie".
    private static func reserveText(_ reserve: Int) -> String {
        guard reserve > 1 else { return "1 powtórzenie w zapasie" }
        return "1–\(reserve) " + PolishPlural.form(for: reserve, one: "powtórzenie", few: "powtórzenia", many: "powtórzeń") + " w zapasie"
    }

    private static func range(_ lower: Int?, _ upper: Int?) -> String? {
        guard let upper else { return nil }
        guard let lower, lower < upper else { return "\(upper)" }
        return "\(lower)–\(upper)"
    }

    private static func rangeText(_ range: ClosedRange<Int>) -> String {
        range.lowerBound == range.upperBound ? "\(range.upperBound)" : "\(range.lowerBound)–\(range.upperBound)"
    }

    /// "3 min" for whole minutes, otherwise "90 s".
    private static func duration(_ seconds: Int) -> String {
        seconds % 60 == 0 ? "\(seconds / 60) min" : "\(seconds) s"
    }
}
