import Foundation

// MARK: - ProgramPrescriber
/// Pure functions that turn a program template and the athlete's ladder state
/// into concrete plans, and keep a plan's ladder items on the current rung.
///
/// Ladder state comes from `ProgressionEngine.pathStates(logs:placement:)`,
/// so the rung an item trains is the same one the Skills tab shows as
/// current: the first unconquered main-line rung, never a parallel track.
nonisolated enum ProgramPrescriber {
    // MARK: Plans

    /// The plans a program creates for an athlete: one per training day, with
    /// every ladder item on the athlete's current main-line rung. The plans
    /// are ordinary editable plans that remember the program and version.
    /// `today` becomes their creation date.
    static func plans(
        for program: TrainingProgram,
        pathStates: [ProgressionPathID: PathState],
        today: Date = .now
    ) -> [WorkoutPlan] {
        program.sessions.map { session in
            WorkoutPlan(
                name: session.name,
                exercises: session.items.compactMap { plannedExercise(for: $0, pathStates: pathStates) },
                schedule: .weekly(program.weekdays),
                createdAt: today,
                programID: program.id.rawValue,
                programVersion: program.version
            )
        }
    }

    /// The plan item for one program item, or `nil` when its exercise or
    /// ladder is missing from the catalog.
    static func plannedExercise(
        for item: ProgramItem,
        pathStates: [ProgressionPathID: PathState]
    ) -> PlannedExercise? {
        let pathID: ProgressionPathID?
        let holdRungsOnly: Bool
        let exercise: Exercise
        switch item.movement {
        case .ladder(let path, let holdsOnly):
            guard let step = currentStep(on: path, holdRungsOnly: holdsOnly, pathStates: pathStates),
                let found = ExerciseCatalog.exercise(withID: step.exerciseID)
            else { return nil }
            pathID = path
            holdRungsOnly = holdsOnly
            exercise = found
        case .exercise(let id):
            guard let found = ExerciseCatalog.exercise(withID: id) else { return nil }
            pathID = nil
            holdRungsOnly = false
            exercise = found
        }

        var planned = PlannedExercise(
            exerciseID: exercise.id,
            pathID: pathID,
            holdRungsOnly: holdRungsOnly,
            restSeconds: item.restSeconds,
            group: item.group)
        switch item.dose {
        case .ladderSets:
            applyLadderDose(to: &planned, exercise: exercise)
        case .circuit(let rounds, let reserve):
            planned.rounds = rounds
            planned.repsInReserve = reserve
        case .timeBox(let minutes):
            planned.timeBoxMinutes = minutes
        case .totalHold(let seconds, let perHold):
            planned.totalSeconds = seconds
            planned.targetSecondsMin = perHold.lowerBound
            planned.targetSeconds = perHold.upperBound
        }
        return planned
    }

    // MARK: Current rung

    /// The rung a ladder item trains now: the athlete's current main-line
    /// rung, or with `holdRungsOnly` the nearest held rung (the highest one at
    /// or below the current rung, else the first above it). A path missing
    /// from `pathStates` starts at its first main-line rung.
    static func currentStep(
        on pathID: ProgressionPathID,
        holdRungsOnly: Bool = false,
        pathStates: [ProgressionPathID: PathState]
    ) -> ProgressionStep? {
        guard let path = ProgressionCatalog.path(withID: pathID), !path.steps.isEmpty else { return nil }
        let fallback = ProgressionEngine.nextMainLineRung(in: path, from: 0) ?? 0
        let index = min(max(pathStates[pathID]?.currentRungIndex ?? fallback, 0), path.steps.count - 1)
        let step = path.steps[index]
        guard holdRungsOnly, step.criterion.measurement != .seconds else { return step }

        func isMainLineHold(_ candidate: ProgressionStep) -> Bool {
            candidate.criterion.measurement == .seconds && !candidate.isParallelTrack
        }
        return path.steps[..<index].last(where: isMainLineHold)
            ?? path.steps[index...].first(where: isMainLineHold)
    }

    // MARK: Dose

    /// Sets of a ladder item, from the rung's criterion: 3 sets, reps from
    /// about 60 % of the target up to it (3 × 8 gives 3 × 5–8, 3 × 5 gives
    /// 3 × 3–5), or holds from 10 s up to the target seconds (3 × 30 s gives
    /// 3 × 10–30 s). Matches RR's "start at 3 × 5, add a rep, move on at
    /// 3 × 8". An exercise off the ladders gets the 3 × 8 / 3 × 30 s default.
    static func ladderDose(for exercise: Exercise) -> (sets: Int, range: ClosedRange<Int>) {
        let criterion = ProgressionCatalog.paths(containing: exercise.id).first?
            .steps.first { $0.exerciseID == exercise.id }?.criterion
        switch exercise.measurement {
        case .reps:
            let top = max(criterion?.targetValue ?? 8, 1)
            let bottom = Int((Double(top) * 0.6).rounded(.up))
            return (setsPerItem, min(bottom, top)...top)
        case .seconds:
            let top = max(criterion?.targetValue ?? 30, 1)
            return (setsPerItem, min(minimumHoldSeconds, top)...top)
        }
    }

    /// Sets per ladder item (RR).
    static let setsPerItem = 3
    /// The shortest hold worth prescribing (RR's 10–30 s).
    static let minimumHoldSeconds = 10

    private static func applyLadderDose(to planned: inout PlannedExercise, exercise: Exercise) {
        let dose = ladderDose(for: exercise)
        planned.targetSets = dose.sets
        switch exercise.measurement {
        case .reps:
            planned.targetRepsMin = dose.range.lowerBound
            planned.targetReps = dose.range.upperBound
            planned.targetSecondsMin = nil
            planned.targetSeconds = nil
        case .seconds:
            planned.targetSecondsMin = dose.range.lowerBound
            planned.targetSeconds = dose.range.upperBound
            planned.targetRepsMin = nil
            planned.targetReps = nil
        }
    }

    // MARK: Following the ladder

    /// The item as a session started now should train it: a ladder item moves
    /// to the athlete's current rung, and when it was prescribed in sets its
    /// ranges move to the new rung's criterion. Everything else (rest, pair,
    /// circuit, time box) stays. Items without a ladder come back unchanged.
    static func resolved(
        _ planned: PlannedExercise,
        pathStates: [ProgressionPathID: PathState]
    ) -> PlannedExercise {
        guard let pathID = planned.pathID,
            let step = currentStep(on: pathID, holdRungsOnly: planned.holdRungsOnly, pathStates: pathStates),
            step.exerciseID != planned.exerciseID,
            let exercise = ExerciseCatalog.exercise(withID: step.exerciseID)
        else { return planned }

        var moved = planned
        moved.exerciseID = exercise.id
        if planned.targetSets != nil {
            applyLadderDose(to: &moved, exercise: exercise)
        }
        return moved
    }

    /// The value to prefill each set with, in the exercise's unit, or `nil`
    /// when the item has no set target (a circuit, a time box). Reps follow
    /// RR's progression: one more than the best set of the last session on
    /// this exercise, kept inside the range; the bottom of the range without
    /// a previous session. Holds start from the last session's best, kept
    /// inside the range.
    static func suggestedValue(
        for planned: PlannedExercise,
        measurement: ExerciseMeasurement,
        logs: [WorkoutLogEntry]
    ) -> Int? {
        let range: ClosedRange<Int>
        switch measurement {
        case .reps:
            guard let top = planned.targetReps, top > 0 else { return nil }
            range = min(planned.targetRepsMin ?? top, top)...top
        case .seconds:
            guard let top = planned.targetSeconds, top > 0 else { return nil }
            range = min(planned.targetSecondsMin ?? top, top)...top
        }

        let lastSession =
            logs
            .filter { $0.exerciseID == planned.exerciseID }
            .max { $0.date < $1.date }
        guard let best = lastSession?.sets.map({ $0.padValue(for: measurement) }).max() else {
            return range.lowerBound
        }
        let next = measurement == .reps ? best + 1 : best
        return min(max(next, range.lowerBound), range.upperBound)
    }

    // MARK: Suggestions

    /// The program onboarding suggests for a placement: "Pierwsze
    /// podciągnięcie" when the athlete declared a start below full pull-ups
    /// (they answered "0"), otherwise "Fundamenty". "Minimum" stays an option
    /// for little time, never the default.
    static func suggestedProgram(for placement: SkillPlacement) -> ProgramID {
        guard let declared = placement.declaredRung(for: .pullUp),
            let pullUps = RungReference(pathID: .pullUp, stepID: ExerciseCatalog.pullUpsID).rungIndex
        else { return .fundamentals }
        return declared < pullUps ? .firstPullUp : .fundamentals
    }

    /// Whether the athlete has no full pull-up yet on their ladder state, so
    /// "Fundamenty" should point them to "Pierwsze podciągnięcie" first.
    static func needsFirstPullUp(_ pathStates: [ProgressionPathID: PathState]) -> Bool {
        guard let pullUps = RungReference(pathID: .pullUp, stepID: ExerciseCatalog.pullUpsID).rungIndex else {
            return false
        }
        return (pathStates[.pullUp]?.currentRungIndex ?? 0) < pullUps
    }

    /// Whether a plan from "Pierwsze podciągnięcie" has done its job: full
    /// pull-ups are conquered (3 × 8), so it is time for "Fundamenty".
    static func isReadyToGraduate(
        _ plan: WorkoutPlan,
        pathStates: [ProgressionPathID: PathState]
    ) -> Bool {
        guard plan.programID == ProgramID.firstPullUp.rawValue,
            let pullUps = RungReference(pathID: .pullUp, stepID: ExerciseCatalog.pullUpsID).rungIndex,
            let state = pathStates[.pullUp]
        else { return false }
        return state.isConquered(rungAt: pullUps)
    }

    /// The plan to suggest moving on from: the oldest active plan from
    /// "Pierwsze podciągnięcie" that is ready to graduate, or `nil` when there
    /// is none or the athlete already has a plan from "Fundamenty".
    static func graduationCandidate(
        plans: [WorkoutPlan],
        pathStates: [ProgressionPathID: PathState]
    ) -> WorkoutPlan? {
        guard !plans.contains(where: { $0.programID == ProgramID.fundamentals.rawValue }) else { return nil }
        return
            plans
            .filter { $0.isActive && isReadyToGraduate($0, pathStates: pathStates) }
            .min { $0.createdAt < $1.createdAt }
    }

    /// The plans that replace `plan` when the athlete moves on to `program`:
    /// the program's plans on the current rungs, on `plan`'s days and with
    /// its reminder, so the week keeps its shape.
    static func replacementPlans(
        for plan: WorkoutPlan,
        program: TrainingProgram,
        pathStates: [ProgressionPathID: PathState],
        today: Date = .now
    ) -> [WorkoutPlan] {
        plans(for: program, pathStates: pathStates, today: today).map { created in
            var replacement = created
            replacement.schedule = plan.schedule
            replacement.reminderTime = plan.reminderTime
            return replacement
        }
    }
}
