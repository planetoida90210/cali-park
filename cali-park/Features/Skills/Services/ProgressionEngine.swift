import Foundation

// MARK: - ProgressionEngine
/// Pure, deterministic scoring of the progression system from workout logs.
///
/// Every function is a static function over value types with no hidden state, so
/// results depend only on the inputs (the calendar and "today" are injected for
/// the streak-based badges). Three questions are answered here:
///
/// - **Where am I on each path?** `pathStates(logs:placement:)` combines logged
///   performance with the athlete's declaration, taking the max of the two.
/// - **How much have I earned?** `experiencePoints(for:)` and `playerLevel(for:)`
///   score volume plus rung advancements — from logs only, never declarations.
/// - **What have I unlocked?** `earnedBadges(from:calendar:today:)`.
///
/// Paths are scored independently: one path's logs never move another's state.
enum ProgressionEngine {
    // MARK: XP tuning
    /// One repetition is worth this much XP.
    static let xpPerRep = 10
    /// One second of an isometric hold is worth this much XP. Holds are scored
    /// lower per unit than reps because a set accrues far more seconds than reps.
    static let xpPerHoldSecond = 1
    /// Bonus XP for each rung conquered through training (declarations excluded).
    static let xpPerConqueredRung = 100

    // MARK: Path state

    /// The state of every catalog path for the given logs and placement.
    /// Pass `nil` (or `.empty`) placement to score from logs alone.
    static func pathStates(logs: [WorkoutLogEntry],
                           placement: SkillPlacement?) -> [ProgressionPathID: PathState] {
        var states: [ProgressionPathID: PathState] = [:]
        states.reserveCapacity(ProgressionCatalog.all.count)
        for path in ProgressionCatalog.all {
            states[path.id] = pathState(for: path, logs: logs, placement: placement)
        }
        return states
    }

    /// The state of a single path. The current rung is the higher of what the
    /// logs prove and what the placement declares; everything below it counts as
    /// conquered.
    static func pathState(for path: ProgressionPath,
                          logs: [WorkoutLogEntry],
                          placement: SkillPlacement?) -> PathState {
        let rungCount = path.steps.count

        // Highest rung whose criterion the logs satisfy in a single session.
        // Rungs are separate exercises, so a higher rung can be met even with no
        // logs on a lower one; reaching it implies the ones below are conquered.
        var logsConqueredThrough = -1
        for (index, step) in path.steps.enumerated()
        where meetsCriterion(step.criterion, exerciseID: step.exerciseID, in: logs) {
            logsConqueredThrough = index
        }

        // A declaration says "I start here", conquering everything below it.
        let declaredConqueredThrough = (placement?.declaredRung(for: path.id)).map { $0 - 1 } ?? -1

        let conqueredThrough = max(logsConqueredThrough, declaredConqueredThrough)
        let conqueredRungCount = conqueredThrough + 1
        // Train the first unconquered rung, or stay on the top once complete.
        let currentRungIndex = min(max(conqueredThrough + 1, 0), rungCount - 1)

        return PathState(
            pathID: path.id,
            rungCount: rungCount,
            currentRungIndex: currentRungIndex,
            conqueredRungCount: conqueredRungCount,
            currentProgress: rungProgress(for: path.steps[currentRungIndex], in: logs)
        )
    }

    /// The athlete's best logged progress toward one rung's criterion.
    static func rungProgress(for step: ProgressionStep, in logs: [WorkoutLogEntry]) -> RungProgress {
        RungProgress(
            criterion: step.criterion,
            bestValue: bestSessionValue(for: step.criterion, exerciseID: step.exerciseID, in: logs)
        )
    }

    // MARK: Experience & level

    /// Total XP from the whole log history: training volume plus a bonus for
    /// every rung conquered through logs. Declarations contribute nothing.
    static func experiencePoints(for logs: [WorkoutLogEntry]) -> Int {
        let volumeXP = logs.reduce(0) { running, entry in
            running + entry.totalReps * xpPerRep + entry.totalSeconds * xpPerHoldSecond
        }
        let conqueredRungs = pathStates(logs: logs, placement: nil).values
            .reduce(0) { $0 + $1.conqueredRungCount }
        return volumeXP + conqueredRungs * xpPerConqueredRung
    }

    /// The athlete's level for their whole log history.
    static func playerLevel(for logs: [WorkoutLogEntry]) -> PlayerLevel {
        PlayerLevel.forXP(experiencePoints(for: logs))
    }

    // MARK: Badges

    /// Every badge the logs earn. Computed strictly from logs (skill completion
    /// is scored with an empty placement), so declarations never grant a badge.
    static func earnedBadges(from logs: [WorkoutLogEntry],
                             calendar: Calendar = .current,
                             today: Date = .now) -> Set<Badge> {
        guard !logs.isEmpty else { return [] }

        var badges: Set<Badge> = [.firstWorkout]

        let trainingDays = Set(logs.map { calendar.startOfDay(for: $0.date) })
        if trainingDays.count >= 10 { badges.insert(.tenTrainingDays) }

        let streak = WorkoutStreak.compute(from: logs.map(\.date), calendar: calendar, today: today)
        if streak.longest >= 7 { badges.insert(.weekStreak) }

        let completedPaths = pathStates(logs: logs, placement: nil).values.filter(\.isComplete).count
        if completedPaths >= 1 { badges.insert(.firstSkill) }
        if completedPaths >= 3 { badges.insert(.threeSkills) }

        let totalReps = logs.reduce(0) { $0 + $1.totalReps }
        if totalReps >= 1000 { badges.insert(.thousandReps) }

        return badges
    }

    // MARK: Scoring helpers

    /// Whether any single session logs enough qualifying sets to satisfy the
    /// criterion.
    private static func meetsCriterion(_ criterion: AdvancementCriterion,
                                       exerciseID: UUID,
                                       in logs: [WorkoutLogEntry]) -> Bool {
        bestSessionValue(for: criterion, exerciseID: exerciseID, in: logs) >= criterion.targetValue
    }

    /// The best single-session value toward a criterion: across each entry for
    /// the exercise, the value of the weakest set among its best `criterion.sets`
    /// sets, then the maximum of those. `0` when no session logs enough sets, so
    /// volume split across sessions never adds up to "3 × 8 in one session".
    private static func bestSessionValue(for criterion: AdvancementCriterion,
                                         exerciseID: UUID,
                                         in logs: [WorkoutLogEntry]) -> Int {
        let requiredSets = criterion.sets
        guard requiredSets > 0 else { return 0 }

        var best = 0
        for entry in logs where entry.exerciseID == exerciseID {
            let values = qualifyingValues(in: entry, for: criterion.measurement)
            guard values.count >= requiredSets else { continue }
            // The (requiredSets)-th best set is the weakest one still counted.
            let weakestCounted = values.sorted(by: >)[requiredSets - 1]
            best = max(best, weakestCounted)
        }
        return best
    }

    /// The per-set values in an entry relevant to a measurement: reps from
    /// rep-based sets, or seconds from timed holds.
    private static func qualifyingValues(in entry: WorkoutLogEntry,
                                         for measurement: ExerciseMeasurement) -> [Int] {
        switch measurement {
        case .reps: entry.sets.filter { !$0.isTimed }.map(\.reps)
        case .seconds: entry.sets.compactMap(\.durationSeconds)
        }
    }
}
