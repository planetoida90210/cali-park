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
struct RepCountQuestion: Identifiable, Sendable {
    /// The path this question places; also the question's identity, since there
    /// is one rep question per path.
    let path: ProgressionPathID
    /// The question shown to the athlete, e.g. "Ile pełnych podciągnięć…".
    let prompt: String
    /// The rung declared when the athlete can't do a single rep yet — the
    /// regression that builds toward the movement.
    let zeroRepRung: Int
    /// The rung of the movement the question counts.
    let movementRung: Int

    var id: ProgressionPathID { path }

    /// The starting rung declared by an answer.
    func rung(for bucket: RepCountBucket) -> Int {
        switch bucket {
        case .none: zeroRepRung
        case .few, .several: movementRung
        case .many: movementRung + 1
        }
    }
}
