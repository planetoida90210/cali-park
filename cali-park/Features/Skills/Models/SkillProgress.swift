import Foundation

// MARK: - SkillProgress
/// The record of which rewards have already been celebrated, so each fires only
/// once. Progress state itself (rungs, XP, level) is always recomputed from logs
/// by `ProgressionEngine`; this type persists *only* the "already celebrated"
/// bookkeeping the reward loop (SK6) needs to stay idempotent.
///
/// Nothing here is a secret, so it lives in a plain JSON file (see
/// `SkillProgressStoring`).
struct SkillProgress: Codable, Equatable, Sendable {
    /// Rung advancements whose celebration has already played.
    var celebratedRungs: Set<RungReference>
    /// The highest player level whose celebration has already played; `1` means
    /// none has been celebrated yet.
    var celebratedLevel: Int

    init(celebratedRungs: Set<RungReference> = [], celebratedLevel: Int = 1) {
        self.celebratedRungs = celebratedRungs
        self.celebratedLevel = celebratedLevel
    }

    /// Whether a rung's advancement has already been celebrated.
    func hasCelebrated(_ rung: RungReference) -> Bool {
        celebratedRungs.contains(rung)
    }

    /// A fresh record with nothing celebrated yet.
    static let empty = SkillProgress()
}
