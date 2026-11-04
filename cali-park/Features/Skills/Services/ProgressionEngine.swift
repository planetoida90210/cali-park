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
/// `snapshot(logs:placement:calendar:today:)` answers all three in one pass;
/// the single-question functions remain for callers that need one answer.
/// Every function reads the log through `ScoringLog`, which merges a workout's
/// entries per exercise (audit A-5) and reads holds in seconds (audit A-8).
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

    // MARK: Snapshot

    /// Every progress answer for the given logs and placement, from one
    /// scoring pass: path states with and without the placement, XP and level,
    /// badges, conquered rungs, the last advancement and the hint.
    static func snapshot(logs: [WorkoutLogEntry],
                         placement: SkillPlacement?,
                         calendar: Calendar = .current,
                         today: Date = .now) -> ProgressSnapshot {
        let scoring = ScoringLog(logs)
        let logStates = pathStates(scoring, placement: nil)
        let states = placement == nil ? logStates : pathStates(scoring, placement: placement)
        return ProgressSnapshot(
            placement: placement,
            pathStates: states,
            logPathStates: logStates,
            level: PlayerLevel.forXP(experiencePoints(scoring, logStates: logStates)),
            badges: earnedBadges(scoring, logStates: logStates, calendar: calendar, today: today),
            conqueredRungs: conqueredRungs(logStates: logStates),
            lastAdvancement: lastAdvancement(scoring, logStates: logStates),
            hint: mostActionableHint(states: states),
            scoring: scoring
        )
    }

    // MARK: Path state

    /// The state of every catalog path for the given logs and placement.
    /// Pass `nil` (or `.empty`) placement to score from logs alone.
    static func pathStates(logs: [WorkoutLogEntry],
                           placement: SkillPlacement?) -> [ProgressionPathID: PathState] {
        pathStates(ScoringLog(logs), placement: placement)
    }

    static func pathStates(_ scoring: ScoringLog,
                           placement: SkillPlacement?) -> [ProgressionPathID: PathState] {
        var states: [ProgressionPathID: PathState] = [:]
        states.reserveCapacity(ProgressionCatalog.all.count)
        for path in ProgressionCatalog.all {
            states[path.id] = pathState(for: path, scoring: scoring, placement: placement)
        }
        return states
    }

    /// The state of a single path. Everything up to the higher of what the logs
    /// prove and what the placement declares counts as conquered; the current
    /// rung is the first unconquered main-line rung above that.
    ///
    /// Parallel-track rungs (`isParallelTrack`, e.g. band pull-ups or step-ups)
    /// are options, never the mandatory next step, so the current rung skips
    /// them (audit A-3). Logging one still counts like any other rung: it can
    /// conquer itself and the rungs below it, and earns XP and a celebration.
    static func pathState(for path: ProgressionPath,
                          logs: [WorkoutLogEntry],
                          placement: SkillPlacement?) -> PathState {
        pathState(for: path, scoring: ScoringLog(logs), placement: placement)
    }

    private static func pathState(for path: ProgressionPath,
                                  scoring: ScoringLog,
                                  placement: SkillPlacement?) -> PathState {
        let rungCount = path.steps.count

        // Highest rung whose criterion the logs satisfy in a single session.
        // Rungs are separate exercises, so a higher rung can be met even with no
        // logs on a lower one; reaching it implies the ones below are conquered.
        var logsConqueredThrough = -1
        for (index, step) in path.steps.enumerated()
        where score(step, in: scoring).best >= step.criterion.targetValue {
            logsConqueredThrough = index
        }

        // A declaration says "I start here", conquering everything below it.
        let declaredConqueredThrough = (placement?.declaredRung(for: path.id)).map { $0 - 1 } ?? -1

        let conqueredThrough = max(logsConqueredThrough, declaredConqueredThrough)
        let conqueredRungCount = conqueredThrough + 1
        // Train the first unconquered main-line rung, or stay on the top once
        // complete.
        let currentRungIndex = nextMainLineRung(in: path, from: conqueredThrough + 1)
            ?? min(max(conqueredThrough + 1, 0), rungCount - 1)

        return PathState(
            pathID: path.id,
            rungCount: rungCount,
            currentRungIndex: currentRungIndex,
            conqueredRungCount: conqueredRungCount,
            currentProgress: rungProgress(for: path.steps[currentRungIndex], in: scoring)
        )
    }

    /// The index of the first rung at or after `index` that is not a parallel
    /// track, or `nil` when no such rung exists.
    static func nextMainLineRung(in path: ProgressionPath, from index: Int) -> Int? {
        let start = max(index, 0)
        guard start < path.steps.count else { return nil }
        return path.steps[start...].firstIndex { !$0.isParallelTrack }
    }

    /// The athlete's best logged progress toward one rung's criterion.
    static func rungProgress(for step: ProgressionStep, in logs: [WorkoutLogEntry]) -> RungProgress {
        rungProgress(for: step, in: ScoringLog(logs))
    }

    static func rungProgress(for step: ProgressionStep, in scoring: ScoringLog) -> RungProgress {
        RungProgress(criterion: step.criterion, bestValue: score(step, in: scoring).best)
    }

    // MARK: Experience & level

    /// Total XP from the whole log history: training volume plus a bonus for
    /// every rung conquered through logs. Declarations contribute nothing.
    static func experiencePoints(for logs: [WorkoutLogEntry]) -> Int {
        let scoring = ScoringLog(logs)
        return experiencePoints(scoring, logStates: pathStates(scoring, placement: nil))
    }

    private static func experiencePoints(_ scoring: ScoringLog,
                                         logStates: [ProgressionPathID: PathState]) -> Int {
        let volumeXP = scoring.entries.reduce(0) { running, entry in
            running + entry.totalReps * xpPerRep + entry.totalSeconds * xpPerHoldSecond
        }
        let conqueredRungs = logStates.values.reduce(0) { $0 + $1.conqueredRungCount }
        return volumeXP + conqueredRungs * xpPerConqueredRung
    }

    /// The athlete's level for their whole log history.
    static func playerLevel(for logs: [WorkoutLogEntry]) -> PlayerLevel {
        PlayerLevel.forXP(experiencePoints(for: logs))
    }

    /// Every rung the logs have conquered, on every path. Scored with no
    /// placement, so declarations add nothing.
    static func conqueredRungs(logs: [WorkoutLogEntry]) -> Set<RungReference> {
        conqueredRungs(logStates: pathStates(logs: logs, placement: nil))
    }

    private static func conqueredRungs(logStates: [ProgressionPathID: PathState]) -> Set<RungReference> {
        var references: Set<RungReference> = []
        for path in ProgressionCatalog.all {
            guard let state = logStates[path.id] else { continue }
            for step in path.steps.prefix(state.conqueredRungCount) {
                references.insert(RungReference(pathID: path.id, stepID: step.id))
            }
        }
        return references
    }

    // MARK: Highlights

    /// The most recently conquered rung across all paths, scored from logs only,
    /// or `nil` when nothing has been conquered yet.
    ///
    /// "Most recent" is the path whose top logged rung was first reached latest —
    /// the last milestone the athlete actually trained up to. Declarations never
    /// count (this reads logs, like XP and badges). Ties break on catalog order.
    static func lastAdvancement(from logs: [WorkoutLogEntry]) -> RungReference? {
        let scoring = ScoringLog(logs)
        return lastAdvancement(scoring, logStates: pathStates(scoring, placement: nil))
    }

    private static func lastAdvancement(_ scoring: ScoringLog,
                                        logStates: [ProgressionPathID: PathState]) -> RungReference? {
        var best: (reference: RungReference, date: Date)?
        for path in ProgressionCatalog.all {
            // Scored without a placement, the conquered count ends at the
            // highest rung the logs directly satisfy.
            guard let state = logStates[path.id], state.conqueredRungCount > 0 else { continue }
            let step = path.steps[state.conqueredRungCount - 1]
            guard let date = score(step, in: scoring).firstMet else { continue }
            if best.map({ date > $0.date }) ?? true {
                best = (RungReference(pathID: path.id, stepID: step.id), date)
            }
        }
        return best?.reference
    }

    /// The single rung most worth nudging toward: the current rung (respecting
    /// the placement floor) with partial-but-unfinished progress, closest to its
    /// criterion. `nil` when no rung is partway done.
    static func mostActionableHint(logs: [WorkoutLogEntry],
                                   placement: SkillPlacement?) -> ProgressionHint? {
        mostActionableHint(states: pathStates(logs: logs, placement: placement))
    }

    private static func mostActionableHint(states: [ProgressionPathID: PathState]) -> ProgressionHint? {
        var best: ProgressionHint?
        var bestFraction = 0.0
        for path in ProgressionCatalog.all {
            guard let state = states[path.id] else { continue }
            let progress = state.currentProgress
            // Only nudge when there's real, unfinished progress to build on.
            guard progress.bestValue > 0, !progress.isMet else { continue }
            let fraction = progress.fractionComplete
            if fraction > bestFraction {
                bestFraction = fraction
                best = ProgressionHint(
                    pathID: path.id,
                    currentRungIndex: state.currentRungIndex,
                    progress: progress
                )
            }
        }
        return best
    }

    // MARK: Badges

    /// Every badge the logs earn. Computed strictly from logs (skill completion
    /// is scored with an empty placement), so declarations never grant a badge.
    static func earnedBadges(from logs: [WorkoutLogEntry],
                             calendar: Calendar = .current,
                             today: Date = .now) -> Set<Badge> {
        let scoring = ScoringLog(logs)
        return earnedBadges(scoring,
                            logStates: pathStates(scoring, placement: nil),
                            calendar: calendar,
                            today: today)
    }

    private static func earnedBadges(_ scoring: ScoringLog,
                                     logStates: [ProgressionPathID: PathState],
                                     calendar: Calendar,
                                     today: Date) -> Set<Badge> {
        let logs = scoring.entries
        guard !logs.isEmpty else { return [] }

        var badges: Set<Badge> = [.firstWorkout]

        let dates = logs.map(\.date)
        let trainingDays = Set(dates.map { calendar.startOfDay(for: $0) })
        if trainingDays.count >= 10 { badges.insert(.tenTrainingDays) }

        let streak = WorkoutStreak.compute(from: dates, calendar: calendar, today: today)
        if streak.longest >= 7 { badges.insert(.weekStreak) }

        let completedPaths = logStates.values.filter(\.isComplete).count
        if completedPaths >= 1 { badges.insert(.firstSkill) }
        if completedPaths >= 3 { badges.insert(.threeSkills) }

        let totalReps = logs.reduce(0) { $0 + $1.totalReps }
        if totalReps >= 1000 { badges.insert(.thousandReps) }

        return badges
    }

    // MARK: Scoring

    /// One rung scored against the log: the best single-session value toward
    /// its criterion, and the date of the first session that met it.
    ///
    /// A session's value is the weakest set among its best `criterion.sets`
    /// sets; a session with fewer qualifying sets scores `0`, so volume split
    /// across sessions never adds up to "3 × 8 in one session".
    private static func score(_ step: ProgressionStep,
                              in scoring: ScoringLog) -> (best: Int, firstMet: Date?) {
        let criterion = step.criterion
        let requiredSets = criterion.sets
        guard requiredSets > 0 else { return (0, nil) }

        var best = 0
        var firstMet: Date?
        for session in scoring.sessions(for: step.exerciseID) {
            let values = qualifyingValues(in: session.sets, for: criterion.measurement)
            guard values.count >= requiredSets else { continue }
            // The (requiredSets)-th best set is the weakest one still counted.
            let weakestCounted = values.sorted(by: >)[requiredSets - 1]
            best = max(best, weakestCounted)
            if weakestCounted >= criterion.targetValue {
                firstMet = min(firstMet ?? session.date, session.date)
            }
        }
        return (best, firstMet)
    }

    /// The per-set values relevant to a measurement: reps from rep-based sets,
    /// or seconds from timed holds.
    private static func qualifyingValues(in sets: [LoggedSet],
                                         for measurement: ExerciseMeasurement) -> [Int] {
        switch measurement {
        case .reps: sets.filter { !$0.isTimed }.map(\.reps)
        case .seconds: sets.compactMap(\.durationSeconds)
        }
    }
}
