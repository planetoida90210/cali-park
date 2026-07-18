import Foundation

// MARK: - RepCountQuestion
/// One onboarding question that places the athlete on a rep-based path by how
/// many clean reps they manage in a single set.
///
/// Each answer bucket maps to a declared starting rung (a 0-based index into the
/// path's `steps`), so answering "9+" starts a strong athlete near the top of
/// the ladder instead of at the bottom. The mapping mirrors `docs/PROGRESSIONS.md`.
struct RepCountQuestion: Identifiable, Sendable {
    /// The path this question places; also the question's identity, since there
    /// is one rep question per path.
    let path: ProgressionPathID
    /// The question shown to the athlete, e.g. "Ile pełnych podciągnięć…".
    let prompt: String
    /// The declared starting rung for each answer bucket.
    let rungForBucket: [RepCountBucket: Int]

    var id: ProgressionPathID { path }

    /// The starting rung declared by an answer, or `nil` when the bucket is
    /// unmapped.
    func rung(for bucket: RepCountBucket) -> Int? {
        rungForBucket[bucket]
    }
}
