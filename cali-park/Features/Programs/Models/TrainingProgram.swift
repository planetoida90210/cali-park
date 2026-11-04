import Foundation

// MARK: - ProgramID
/// Stable identifier of a ready-made program. The raw value is stored in
/// `WorkoutPlan.programID`, so a case's raw value must never change once
/// shipped.
nonisolated enum ProgramID: String, CaseIterable, Codable, Identifiable, Hashable, Sendable {
    case minimum
    case fundamentals
    case firstPullUp
    case skills

    var id: String { rawValue }
}

// MARK: - TrainingProgram
/// A ready-made training program template (see `ProgramCatalog` and
/// `docs/PROGRAMS.md`). A template never trains anything by itself:
/// `ProgramPrescriber` turns it into ordinary, editable `WorkoutPlan`s on the
/// athlete's current rungs.
nonisolated struct TrainingProgram: Identifiable, Hashable, Sendable {
    let id: ProgramID
    /// Bumped whenever the template's content changes, and stored on every
    /// plan created from it (`WorkoutPlan.programVersion`).
    let version: Int
    /// Polish display name, e.g. "Fundamenty".
    let name: String
    /// One line for the program list.
    let tagline: String
    /// Who the program is for.
    let audience: String
    /// Paragraphs for the detail screen: how a session looks and how to
    /// progress.
    let details: [String]
    /// How often, e.g. "3 × w tygodniu".
    let frequency: String
    /// About how long a session takes, e.g. "ok. 45–60 min".
    let sessionLength: String
    /// The honest source line shown with the program, in our own words.
    let creditLine: String
    /// SF Symbol for the list row.
    let symbolName: String
    /// The weekdays the created plans start on; the athlete can change them.
    let weekdays: Set<Weekday>
    /// The training days; each becomes one plan.
    let sessions: [ProgramSession]
}

// MARK: - ProgramSession
/// One training day of a program, created as one `WorkoutPlan`.
nonisolated struct ProgramSession: Hashable, Sendable {
    /// The created plan's name.
    let name: String
    let items: [ProgramItem]
}

// MARK: - ProgramItem
/// One block of a program session: what is trained and how much.
nonisolated struct ProgramItem: Hashable, Sendable {
    // MARK: Movement
    enum Movement: Hashable, Sendable {
        /// The athlete's current main-line rung on a ladder. `holdRungsOnly`
        /// keeps to the ladder's held rungs (handstand practice).
        case ladder(ProgressionPathID, holdRungsOnly: Bool = false)
        /// A fixed catalog exercise that sits on no ladder.
        case exercise(UUID)
    }

    // MARK: Dose
    enum Dose: Hashable, Sendable {
        /// Recommended Routine sets: 3 sets in a range taken from the rung's
        /// criterion (3 × 5–8 for a 3 × 8 rung, 3 × 10–30 s for a 3 × 30 s
        /// hold), see `ProgramPrescriber.ladderDose`.
        case ladderSets
        /// One station of a circuit: a number of rounds, each set stopped a
        /// few reps short of failure.
        case circuit(rounds: ClosedRange<Int>, repsInReserve: Int)
        /// Practice for up to this many minutes.
        case timeBox(minutes: Int)
        /// Holds of `perHold` seconds until about `seconds` in total.
        case totalHold(seconds: Int, perHold: ClosedRange<Int>)
    }

    let movement: Movement
    let dose: Dose
    /// Items with the same number are done as one pair or circuit.
    var group: Int?
    /// Rest after each set, in seconds.
    var restSeconds: Int?

    init(_ movement: Movement, dose: Dose = .ladderSets, group: Int? = nil, restSeconds: Int? = nil) {
        self.movement = movement
        self.dose = dose
        self.group = group
        self.restSeconds = restSeconds
    }
}
