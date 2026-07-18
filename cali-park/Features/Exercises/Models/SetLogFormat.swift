import Foundation

// MARK: - SetLogFormat
/// Formats logged sets for display, honoring each set's measure. Repetitions
/// read as "6 + 6 + 8"; timed holds read as "3 × 20 s" when equal, or
/// "20 + 15 + 20 s" when they differ. Aggregate totals keep reps and seconds
/// apart, so a mixed session never adds seconds to repetitions.
enum SetLogFormat {
    /// The unit symbol for a hold — invariant in Polish, like "kg".
    private static let secondsUnit = "s"

    /// A one-line breakdown of `sets`: "6 + 6 + 8" for reps, "3 × 20 s" for
    /// equal holds, "20 + 15 + 20 s" for varied holds. Empty when `sets` is.
    static func breakdown(of sets: [LoggedSet]) -> String {
        guard !sets.isEmpty else { return "" }
        guard sets.allSatisfy(\.isTimed) else {
            return sets.map { String($0.reps) }.joined(separator: " + ")
        }
        let seconds = sets.map { $0.durationSeconds ?? 0 }
        if let first = seconds.first, seconds.allSatisfy({ $0 == first }) {
            return "\(seconds.count) × \(first) \(secondsUnit)"
        }
        return seconds.map(String.init).joined(separator: " + ") + " \(secondsUnit)"
    }

    /// The work in `sets` as a trailing summary: "20 powtórzeń" for reps, or
    /// "60 s" when every set is a timed hold.
    static func total(of sets: [LoggedSet]) -> String {
        if !sets.isEmpty, sets.allSatisfy(\.isTimed) {
            let seconds = sets.reduce(0) { $0 + ($1.durationSeconds ?? 0) }
            return "\(seconds) \(secondsUnit)"
        }
        let reps = sets.reduce(0) { $0 + ($1.isTimed ? 0 : $1.reps) }
        return PolishPlural.reps(reps)
    }

    /// Combined totals across several entries, listing only the measures that
    /// occur: "40 powtórzeń", "60 s", or "40 powtórzeń · 60 s". Reads
    /// "0 powtórzeń" when there is nothing to show.
    static func totals(reps: Int, seconds: Int) -> String {
        var parts: [String] = []
        if reps > 0 { parts.append(PolishPlural.reps(reps)) }
        if seconds > 0 { parts.append("\(seconds) \(secondsUnit)") }
        return parts.isEmpty ? PolishPlural.reps(0) : parts.joined(separator: " · ")
    }

    /// A spoken reading of `sets` for VoiceOver: "3 serie po 20 sekund" for
    /// equal holds, the spoken seconds list when they differ, and the plain rep
    /// breakdown otherwise.
    static func spokenBreakdown(of sets: [LoggedSet]) -> String {
        guard !sets.isEmpty else { return "" }
        guard sets.allSatisfy(\.isTimed) else { return breakdown(of: sets) }
        let seconds = sets.map { $0.durationSeconds ?? 0 }
        if let first = seconds.first, seconds.allSatisfy({ $0 == first }) {
            return "\(PolishPlural.sets(seconds.count)) po \(PolishPlural.seconds(first))"
        }
        return seconds.map { PolishPlural.seconds($0) }.joined(separator: ", ")
    }
}
