import Foundation

// MARK: - SessionBlock
/// One section of a workout screen: a run of exercises done on their own, or
/// one pair or circuit (`PlannedExercise.group`) whose exercises are done
/// alternately.
nonisolated struct SessionBlock<Item> {
    enum Kind: Equatable, Hashable {
        /// Exercises done one after another, each on its own.
        case singles
        /// The items of one pair or circuit, by group number.
        case group(Int)
    }

    let kind: Kind
    let items: [Item]
}

nonisolated extension SessionBlock: Equatable where Item: Equatable {}

nonisolated extension SessionBlock: Identifiable where Item: Identifiable {
    /// A group's number, or the first item of a run of singles.
    var id: String {
        switch kind {
        case .group(let number): "group-\(number)"
        case .singles: "singles-\(items.first.map { "\($0.id)" } ?? "")"
        }
    }
}

// MARK: - SessionGrouping
/// Splits a session's items into blocks for the workout screen. A group's
/// block sits where its first item is and collects every later item with the
/// same group number, so a pair stays together even if an exercise was
/// added between its items. Consecutive items without a group share one
/// block. The order inside a block is the session's order.
nonisolated enum SessionGrouping {
    static func blocks<Item>(_ items: [Item], group: (Item) -> Int?) -> [SessionBlock<Item>] {
        var blocks: [SessionBlock<Item>] = []
        var singles: [Item] = []
        var placed: Set<Int> = []

        func flushSingles() {
            guard !singles.isEmpty else { return }
            blocks.append(SessionBlock(kind: .singles, items: singles))
            singles = []
        }

        for item in items {
            guard let number = group(item) else {
                singles.append(item)
                continue
            }
            guard placed.insert(number).inserted else { continue }
            flushSingles()
            blocks.append(SessionBlock(kind: .group(number), items: items.filter { group($0) == number }))
        }
        flushSingles()
        return blocks
    }
}

// MARK: - RoundTracker
/// Counts the rounds of one pair or circuit during a workout and times the
/// rest after each round. It only guides the athlete: sets are still logged
/// per exercise, and nothing here is saved.
///
/// A pair from a program has a fixed number of rounds (its items' sets, e.g.
/// 3); a circuit has a range (2–6). The tracker counts up to the top of the
/// range, and the athlete may stop once the bottom is reached.
nonisolated struct RoundTracker: Equatable, Sendable {
    /// How many rounds the plan asks for; a single value for a pair.
    let rounds: ClosedRange<Int>
    /// Rest after a round, in seconds.
    let restSeconds: Int
    /// Rounds finished so far.
    private(set) var completed = 0
    /// When the running rest started and ends; `nil` while not resting.
    private(set) var rest: DateInterval?

    /// Rest between the rounds of a circuit that sets none. "Minimum" rests
    /// "as long as needed, usually 1–2 minutes" between rounds.
    static let defaultCircuitRestSeconds = 90

    /// A tracker for one group, or `nil` when the plan sets no rounds: a pair
    /// counts its items' sets, a circuit its rounds.
    init?(for planned: [PlannedExercise]) {
        if let range = planned.compactMap(\.rounds).first {
            rounds = range
            restSeconds = planned.compactMap(\.restSeconds).max() ?? Self.defaultCircuitRestSeconds
        } else if let sets = planned.compactMap(\.targetSets).max(), sets > 0 {
            rounds = sets...sets
            restSeconds = planned.compactMap(\.restSeconds).max() ?? 0
        } else {
            return nil
        }
    }

    init(rounds: ClosedRange<Int>, restSeconds: Int) {
        self.rounds = rounds
        self.restSeconds = restSeconds
    }

    // MARK: State
    /// Every round the plan allows is done.
    var isFinished: Bool { completed >= rounds.upperBound }
    /// The round being done now, 1-based; the last one once finished.
    var currentRound: Int { min(completed + 1, rounds.upperBound) }
    /// The plan's minimum is done: a circuit may end here.
    var hasMetMinimum: Bool { completed >= rounds.lowerBound }

    /// Whether the rest after the last round is still running at `date`.
    func isResting(at date: Date) -> Bool {
        guard let rest else { return false }
        return date < rest.end
    }

    // MARK: Changes
    /// Marks the current round done at `date` and starts the rest, unless it
    /// was the last round or the plan sets no rest. No-op once finished.
    mutating func finishRound(at date: Date) {
        guard !isFinished else { return }
        completed += 1
        rest =
            isFinished || restSeconds <= 0
            ? nil
            : DateInterval(start: date, duration: TimeInterval(restSeconds))
    }

    /// Ends the rest early ("Pomiń"), or clears it once it ran out.
    mutating func endRest() {
        rest = nil
    }
}
