import Foundation

// MARK: - MeasureFormat
/// The one formatter for sets, reps, seconds and criteria, honoring each
/// value's measure. Repetitions read as "6 + 6 + 8"; timed holds as "3 × 20 s"
/// when equal, or "20 + 15 + 20 s" when they differ. Targets read as "3 × 8" or
/// "3 × 20 s", and the "you own it" markers as "pierwsze czyste" /
/// "pierwsze 5 s". Totals keep reps and seconds apart, so a mixed session never
/// adds seconds to repetitions. On screen the seconds unit stays the invariant
/// "s"; spoken variants spell it out for VoiceOver. Counted nouns go through
/// `PolishPlural`.
nonisolated enum MeasureFormat {
    /// The unit symbol for a hold — invariant in Polish, like "kg".
    static let secondsUnit = String(localized: "s", comment: "Seconds unit symbol, as in \"20 s\"")

    // MARK: Values

    /// "20 s".
    static func seconds(_ value: Int) -> String {
        "\(value) \(secondsUnit)"
    }

    /// An amount of work: "20 powtórzeń" for reps, "60 s" for a hold.
    static func amount(_ value: Int, _ measurement: ExerciseMeasurement) -> String {
        switch measurement {
        case .reps: PolishPlural.reps(value)
        case .seconds: seconds(value)
        }
    }

    /// Equal sets: "3 × 8" for reps, "3 × 20 s" for holds.
    static func sets(_ count: Int, of value: Int, _ measurement: ExerciseMeasurement) -> String {
        switch measurement {
        case .reps: "\(count) × \(value)"
        case .seconds: "\(count) × \(seconds(value))"
        }
    }

    /// Equal sets, spoken: "3 serie po 8 powtórzeń", "3 serie po 20 sekund".
    static func spokenSets(_ count: Int, of value: Int, _ measurement: ExerciseMeasurement) -> String {
        let each = switch measurement {
        case .reps: PolishPlural.reps(value)
        case .seconds: PolishPlural.seconds(value)
        }
        return String(localized: "\(PolishPlural.sets(count)) po \(each)")
    }

    // MARK: Logged sets

    /// A one-line breakdown of `sets`: "6 + 6 + 8" for reps, "3 × 20 s" for
    /// equal holds, "20 + 15 + 20 s" for varied holds. Empty when `sets` is.
    static func breakdown(of sets: [LoggedSet]) -> String {
        guard !sets.isEmpty else { return "" }
        guard sets.allSatisfy(\.isTimed) else {
            return sets.map { String($0.reps) }.joined(separator: " + ")
        }
        let held = sets.map { $0.durationSeconds ?? 0 }
        if let first = held.first, held.allSatisfy({ $0 == first }) {
            return Self.sets(held.count, of: first, .seconds)
        }
        return held.map(String.init).joined(separator: " + ") + " \(secondsUnit)"
    }

    /// The work in `sets` as a trailing summary: "20 powtórzeń" for reps, or
    /// "60 s" when every set is a timed hold.
    static func total(of sets: [LoggedSet]) -> String {
        if !sets.isEmpty, sets.allSatisfy(\.isTimed) {
            return seconds(sets.totalSeconds)
        }
        return PolishPlural.reps(sets.totalReps)
    }

    /// Combined totals across several entries, listing only the measures that
    /// occur: "40 powtórzeń", "60 s", or "40 powtórzeń · 60 s". Reads
    /// "0 powtórzeń" when there is nothing to show.
    static func totals(reps: Int, seconds held: Int) -> String {
        var parts: [String] = []
        if reps > 0 { parts.append(PolishPlural.reps(reps)) }
        if held > 0 { parts.append(seconds(held)) }
        return parts.isEmpty ? PolishPlural.reps(0) : parts.joined(separator: " · ")
    }

    /// A workout in one line: "2 ćwiczenia · 40 powtórzeń · 60 s".
    static func summary(of session: WorkoutSession) -> String {
        "\(PolishPlural.exercises(session.entries.count)) · \(totals(reps: session.totalReps, seconds: session.totalSeconds))"
    }

    /// A spoken reading of `sets` for VoiceOver: "3 serie po 20 sekund" for
    /// equal holds, the spoken seconds list when they differ, and the plain rep
    /// breakdown otherwise.
    static func spokenBreakdown(of sets: [LoggedSet]) -> String {
        guard !sets.isEmpty else { return "" }
        guard sets.allSatisfy(\.isTimed) else { return breakdown(of: sets) }
        let held = sets.map { $0.durationSeconds ?? 0 }
        if let first = held.first, held.allSatisfy({ $0 == first }) {
            return spokenSets(held.count, of: first, .seconds)
        }
        return held.map { PolishPlural.seconds($0) }.joined(separator: ", ")
    }

    /// The spoken set line of a logged exercise: the set count, then the
    /// breakdown, without saying the count twice. "3 serie po 20 sekund" for
    /// equal holds (the spoken breakdown already counts them), otherwise
    /// "3 serie: 6 + 6 + 8".
    static func spokenSetLine(of sets: [LoggedSet]) -> String {
        let spoken = spokenBreakdown(of: sets)
        let count = PolishPlural.sets(sets.count)
        return spoken.hasPrefix(count) ? spoken : "\(count): \(spoken)"
    }

    // MARK: Criteria

    /// The target for a rung: "3 × 8" for reps, "3 × 20 s" for holds, or the
    /// mastery markers "pierwsze czyste" / "pierwsze 5 s" for single-effort
    /// skills. A unilateral rung counts per side: "3 × 5 na rękę".
    static func criterion(_ criterion: AdvancementCriterion,
                          side: UnilateralSide? = nil) -> String {
        let target = switch criterion {
        case let .setsOfReps(count, reps):
            count == 1 && reps == 1 ? String(localized: "pierwsze czyste") : sets(count, of: reps, .reps)
        case let .setsOfHold(count, held):
            count == 1 ? String(localized: "pierwsze \(seconds(held))") : sets(count, of: held, .seconds)
        }
        return withSide(target, side)
    }

    /// The target for a step, counted per side when its exercise is
    /// unilateral.
    static func criterion(for step: ProgressionStep) -> String {
        criterion(step.criterion, side: step.unilateralSide)
    }

    /// The athlete's best logged effort toward a rung, or `nil` when no session
    /// has counted yet (or when a single-rep marker leaves nothing partial to
    /// show).
    static func best(_ progress: RungProgress) -> String? {
        guard progress.bestValue > 0 else { return nil }
        switch progress.criterion {
        case .setsOfReps:
            return progress.targetSets == 1 ? nil : sets(progress.targetSets, of: progress.bestValue, .reps)
        case .setsOfHold:
            return progress.targetSets == 1
                ? seconds(progress.bestValue)
                : sets(progress.targetSets, of: progress.bestValue, .seconds)
        }
    }

    /// The target paired with the logged best: "3 × 8 — Twoje najlepsze: 3 × 6",
    /// or just the target when nothing counts yet.
    static func progressLine(_ progress: RungProgress, side: UnilateralSide? = nil) -> String {
        let target = criterion(progress.criterion, side: side)
        guard let best = best(progress) else { return target }
        return String(localized: "\(target) — Twoje najlepsze: \(best)")
    }

    /// A spoken reading of a criterion for VoiceOver: "3 serie po 8 powtórzeń",
    /// "3 serie po 20 sekund", or the spelled-out mastery markers.
    static func spokenCriterion(_ criterion: AdvancementCriterion,
                                side: UnilateralSide? = nil) -> String {
        let spoken = switch criterion {
        case let .setsOfReps(count, reps):
            count == 1 && reps == 1
                ? String(localized: "pierwsze czyste powtórzenie")
                : spokenSets(count, of: reps, .reps)
        case let .setsOfHold(count, held):
            count == 1
                ? String(localized: "pierwsze utrzymanie \(PolishPlural.seconds(held))")
                : spokenSets(count, of: held, .seconds)
        }
        return withSide(spoken, side)
    }

    /// The spoken target for a step, per side when its exercise is unilateral.
    static func spokenCriterion(for step: ProgressionStep) -> String {
        spokenCriterion(step.criterion, side: step.unilateralSide)
    }

    /// Appends the per-side suffix ("na rękę") when there is one.
    private static func withSide(_ text: String, _ side: UnilateralSide?) -> String {
        guard let side else { return text }
        return "\(text) \(side.label)"
    }
}
