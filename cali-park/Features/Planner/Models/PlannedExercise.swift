import Foundation

// MARK: - PlannedExercise
/// One exercise inside a `WorkoutPlan`, referenced by its stable catalog
/// `exerciseID`. Targets are optional: a plan can just list the movements, or
/// prescribe sets/reps to prefill the SetPad when the session starts.
///
/// Items created from a ready-made program (`ProgramPrescriber`) carry more:
/// a ladder reference, ranges, rest, a pair or circuit number, and so on.
/// Every one of those fields is optional and absent from plans saved before
/// programs existed, so old plan files still load (see `init(from:)`).
nonisolated struct PlannedExercise: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var exerciseID: UUID
    var targetSets: Int?
    /// The rep target, or the top of the range when `targetRepsMin` is set
    /// ("3 × 5–8" stores 5 and 8).
    var targetReps: Int?

    // MARK: Ladder reference
    /// The ladder this item follows. When set, a session started from the
    /// plan trains the athlete's current main-line rung on this ladder
    /// instead of the stored `exerciseID`, which only records the rung the
    /// item was created on (see `ProgramPrescriber.resolved`).
    var pathID: ProgressionPathID?
    /// Follow only the ladder's held rungs (seconds), e.g. the handstand
    /// practice in "Skille", which must not turn into pike push-ups.
    var holdRungsOnly: Bool

    // MARK: Program targets
    /// The bottom of the rep range; `nil` for a single rep target.
    var targetRepsMin: Int?
    /// Seconds per hold, or the top of the range when `targetSecondsMin` is set.
    var targetSeconds: Int?
    /// The bottom of the hold range; `nil` for a single hold target.
    var targetSecondsMin: Int?
    /// Rest after each set, in seconds.
    var restSeconds: Int?
    /// Items with the same number form one pair or circuit, done alternately.
    var group: Int?
    /// How many rounds of the circuit this item belongs to, e.g. 2–6.
    var rounds: ClosedRange<Int>?
    /// End each set 1 to this many reps short of failure, instead of a rep
    /// target ("1–2 w zapasie" stores 2).
    var repsInReserve: Int?
    /// Practice for up to this many minutes instead of counting sets.
    var timeBoxMinutes: Int?
    /// Accumulate up to this many seconds of holds in total.
    var totalSeconds: Int?

    init(
        id: UUID = UUID(),
        exerciseID: UUID,
        targetSets: Int? = nil,
        targetReps: Int? = nil,
        pathID: ProgressionPathID? = nil,
        holdRungsOnly: Bool = false,
        targetRepsMin: Int? = nil,
        targetSeconds: Int? = nil,
        targetSecondsMin: Int? = nil,
        restSeconds: Int? = nil,
        group: Int? = nil,
        rounds: ClosedRange<Int>? = nil,
        repsInReserve: Int? = nil,
        timeBoxMinutes: Int? = nil,
        totalSeconds: Int? = nil
    ) {
        self.id = id
        self.exerciseID = exerciseID
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.pathID = pathID
        self.holdRungsOnly = holdRungsOnly
        self.targetRepsMin = targetRepsMin
        self.targetSeconds = targetSeconds
        self.targetSecondsMin = targetSecondsMin
        self.restSeconds = restSeconds
        self.group = group
        self.rounds = rounds
        self.repsInReserve = repsInReserve
        self.timeBoxMinutes = timeBoxMinutes
        self.totalSeconds = totalSeconds
    }

    // MARK: Codable
    // Every field after `targetReps` is additive: absent keys decode to nil
    // (or false), and nil fields are not written, so a plan without program
    // data encodes exactly as before. The envelope stays at schema version 1:
    // nothing existing changed meaning, and older readers ignore unknown keys.
    private enum CodingKeys: String, CodingKey {
        case id, exerciseID, targetSets, targetReps
        case pathID, holdRungsOnly, targetRepsMin, targetSeconds, targetSecondsMin
        case restSeconds, group, rounds, repsInReserve, timeBoxMinutes, totalSeconds
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        exerciseID = try container.decode(UUID.self, forKey: .exerciseID)
        targetSets = try container.decodeIfPresent(Int.self, forKey: .targetSets)
        targetReps = try container.decodeIfPresent(Int.self, forKey: .targetReps)
        // A ladder this build doesn't know (added by a newer version) or a
        // malformed range drops only that field: the item still trains its
        // stored exercise, and the plan file is not treated as corrupt.
        pathID = try? container.decodeIfPresent(ProgressionPathID.self, forKey: .pathID)
        rounds = try? container.decodeIfPresent(ClosedRange<Int>.self, forKey: .rounds)
        holdRungsOnly = try container.decodeIfPresent(Bool.self, forKey: .holdRungsOnly) ?? false
        targetRepsMin = try container.decodeIfPresent(Int.self, forKey: .targetRepsMin)
        targetSeconds = try container.decodeIfPresent(Int.self, forKey: .targetSeconds)
        targetSecondsMin = try container.decodeIfPresent(Int.self, forKey: .targetSecondsMin)
        restSeconds = try container.decodeIfPresent(Int.self, forKey: .restSeconds)
        group = try container.decodeIfPresent(Int.self, forKey: .group)
        repsInReserve = try container.decodeIfPresent(Int.self, forKey: .repsInReserve)
        timeBoxMinutes = try container.decodeIfPresent(Int.self, forKey: .timeBoxMinutes)
        totalSeconds = try container.decodeIfPresent(Int.self, forKey: .totalSeconds)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(exerciseID, forKey: .exerciseID)
        try container.encodeIfPresent(targetSets, forKey: .targetSets)
        try container.encodeIfPresent(targetReps, forKey: .targetReps)
        try container.encodeIfPresent(pathID, forKey: .pathID)
        if holdRungsOnly { try container.encode(true, forKey: .holdRungsOnly) }
        try container.encodeIfPresent(targetRepsMin, forKey: .targetRepsMin)
        try container.encodeIfPresent(targetSeconds, forKey: .targetSeconds)
        try container.encodeIfPresent(targetSecondsMin, forKey: .targetSecondsMin)
        try container.encodeIfPresent(restSeconds, forKey: .restSeconds)
        try container.encodeIfPresent(group, forKey: .group)
        try container.encodeIfPresent(rounds, forKey: .rounds)
        try container.encodeIfPresent(repsInReserve, forKey: .repsInReserve)
        try container.encodeIfPresent(timeBoxMinutes, forKey: .timeBoxMinutes)
        try container.encodeIfPresent(totalSeconds, forKey: .totalSeconds)
    }
}
