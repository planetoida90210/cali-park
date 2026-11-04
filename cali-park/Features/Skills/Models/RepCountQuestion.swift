import Foundation

// MARK: - RepCountQuestion
/// One onboarding question that places the athlete on a rep-based path by how
/// many clean reps of one movement they manage in a single set.
///
/// A rep count only speaks for the movement it asks about. Harder variants
/// above it (diamond push-ups, L-pull-ups, lunges…) are separate exercises, so
/// no answer can mark them conquered: "0" starts on the regression that builds
/// the movement, "1–5" and "6–11" train the movement itself, and "12+" (enough
/// for its 3 × 8) makes the next variant current, to be earned through logs.
nonisolated struct RepCountQuestion: Identifiable, Sendable {
    /// The path this question places; also the question's identity, since there
    /// is one rep question per path.
    let path: ProgressionPathID
    /// The question shown to the athlete, e.g. "Ile pełnych podciągnięć…".
    let prompt: String
    /// The rung declared when the athlete can't do a single rep yet — the
    /// regression that builds toward the movement — as its step ID.
    let zeroRepStep: UUID
    /// The step ID of the movement the question counts.
    let movementStep: UUID
    /// The step ID made current at "12+": the next main-line variant above the
    /// movement, to be earned through logs.
    let nextVariantStep: UUID

    var id: ProgressionPathID { path }

    /// The starting rung declared by an answer, as a step ID. Step IDs, not
    /// positions, so inserting rungs never moves an answer's meaning.
    func step(for bucket: RepCountBucket) -> UUID {
        switch bucket {
        case .none: zeroRepStep
        case .few, .several: movementStep
        case .many: nextVariantStep
        }
    }

    /// The position in the current ladder of the rung an answer declares, or
    /// `nil` if the step is not on the path.
    func rung(for bucket: RepCountBucket) -> Int? {
        RungReference(pathID: path, stepID: step(for: bucket)).rungIndex
    }

    /// The position of the counted movement in the current ladder.
    var movementRung: Int? {
        RungReference(pathID: path, stepID: movementStep).rungIndex
    }
}
