import Foundation

// MARK: - ProgramFormat
/// Polish labels for program and plan items: what to do on an item ("3 × 5–8
/// na nogę"), the pair or circuit it belongs to, and its rest. Shared by the
/// program detail screen and the plan editor so both read the same. Numbers
/// stay on one line with their units and ranges (`String.keptTogether`).
nonisolated enum ProgramFormat {
    /// What to do, e.g. "3 × 5–8", "3 × 10–30 s", "2–6 rund · 1–2 powtórzenia
    /// w zapasie", "do 10 min praktyki" or "łącznie do 3 min, holdy 10–30 s".
    /// `nil` when the item has no target at all (a plan built by hand).
    static func doseSummary(for planned: PlannedExercise, exercise: Exercise?) -> String? {
        rawDoseSummary(for: planned, exercise: exercise)?.keptTogether
    }

    private static func rawDoseSummary(for planned: PlannedExercise, exercise: Exercise?) -> String? {
        let side = exercise?.unilateralSide.map { " " + $0.label } ?? ""

        if let minutes = planned.timeBoxMinutes {
            return String(localized: "do \(minutes) min praktyki")
        }
        if let total = planned.totalSeconds {
            let totalText = duration(total)
            guard let hold = range(planned.targetSecondsMin, planned.targetSeconds) else {
                return String(localized: "łącznie do \(totalText)")
            }
            return String(localized: "łącznie do \(totalText), holdy \(hold) s\(side)")
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
                return String(localized: "\(sets) × \(hold) s\(side)")
            }
        }
        return nil
    }

    /// "Para 1" for a two-item group, "Obwód" for a circuit (rounds), "Blok 2"
    /// otherwise; `nil` for an item done on its own.
    static func groupLabel(for planned: PlannedExercise, in items: [PlannedExercise]) -> String? {
        guard let group = planned.group else { return nil }
        if planned.rounds != nil { return String(localized: "Obwód") }
        let size = items.filter { $0.group == group }.count
        return size == 2 ? String(localized: "Para \(group)") : String(localized: "Blok \(group)")
    }

    /// "przerwa 90 s", or `nil` without a set rest.
    static func restSummary(for planned: PlannedExercise) -> String? {
        planned.restSeconds.map { String(localized: "przerwa \($0) s").keptTogether }
    }

    // MARK: Workout screen

    /// How a group is done, for its header on the workout screen: "Na
    /// przemian, przerwa 90 s po każdej serii" for a pair, "Jedno po drugim,
    /// przerwa po rundzie" for a circuit, `nil` for a group without either.
    static func groupInstruction(for items: [PlannedExercise]) -> String? {
        if items.contains(where: { $0.rounds != nil }) {
            return String(localized: "Jedno po drugim, przerwa po rundzie")
        }
        if let rest = items.compactMap(\.restSeconds).max() {
            return String(localized: "Na przemian, przerwa \(rest) s po każdej serii").keptTogether
        }
        return items.count > 1 ? String(localized: "Na przemian") : nil
    }

    /// "Runda 2/3" for a fixed number of rounds, "Runda 3 (2–6)" for a range,
    /// "3/3 rundy zrobione" or "6 rund zrobionych" once every round is done.
    static func roundLabel(for tracker: RoundTracker) -> String {
        let rounds = tracker.rounds
        if tracker.isFinished {
            let noun = PolishPlural.form(for: tracker.completed, one: "runda zrobiona",
                                         few: "rundy zrobione", many: "rund zrobionych")
            return rounds.lowerBound == rounds.upperBound
                ? "\(tracker.completed)/\(rounds.upperBound) \(noun)"
                : "\(tracker.completed) \(noun)"
        }
        if rounds.lowerBound == rounds.upperBound {
            return String(localized: "Runda \(tracker.currentRound)/\(rounds.upperBound)")
        }
        return String(localized: "Runda \(tracker.currentRound) (\(rangeText(rounds)))")
    }

    /// "Przerwa 90 s", or "Przerwa 2 min" for whole minutes.
    static func restLabel(seconds: Int) -> String {
        String(localized: "Przerwa \(duration(seconds))").keptTogether
    }

    /// "Program Fundamenty · wersja 1".
    static func originLine(for program: TrainingProgram, version: Int?) -> String {
        String(localized: "Program \(program.name) · wersja \(version ?? program.version)")
    }

    // MARK: Helpers

    /// "1 powtórzenie w zapasie" or "1–2 powtórzenia w zapasie".
    private static func reserveText(_ reserve: Int) -> String {
        guard reserve > 1 else { return String(localized: "1 powtórzenie w zapasie") }
        let noun = PolishPlural.form(for: reserve, one: "powtórzenie", few: "powtórzenia", many: "powtórzeń")
        return String(localized: "1–\(reserve) \(noun) w zapasie")
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
        seconds % 60 == 0 ? String(localized: "\(seconds / 60) min") : String(localized: "\(seconds) s")
    }
}
