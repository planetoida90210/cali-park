import Foundation

// MARK: - SkillProgress
/// The record of which rewards have already been celebrated, so each fires only
/// once. Progress state itself (rungs, XP, level) is always recomputed from logs
/// by `ProgressionEngine`; this type persists *only* the "already celebrated"
/// bookkeeping the reward loop (SK6) needs to stay idempotent.
///
/// Nothing here is a secret, so it lives in a plain JSON file (see
/// `SkillProgressStoring`).
nonisolated struct SkillProgress: Codable, Equatable, Sendable {
    /// The store schema version this type writes. Version 1 stored rung
    /// indices; version 2 stores step IDs (see `RungReference`).
    static let schemaVersion = 2

    /// Rungs the reward loop has already dealt with: celebrated, or conquered
    /// below the declared floor where no celebration is due. Either way, never
    /// celebrated again.
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

    /// The record after `event` has been shown.
    func markingCelebrated(_ event: CelebrationEvent) -> SkillProgress {
        var progress = self
        switch event {
        case let .rungConquered(rung): progress.celebratedRungs.insert(rung)
        case let .levelReached(level): progress.celebratedLevel = max(progress.celebratedLevel, level)
        }
        return progress
    }

    /// A fresh record with nothing celebrated yet.
    static let empty = SkillProgress()

    // MARK: Codable
    private enum CodingKeys: String, CodingKey {
        case celebratedRungs
        case celebratedLevel
    }

    /// Reads the current format, or migrates version 1 (rung indices) through
    /// the frozen `LadderOrderV1`. A version 1 index that was never valid is
    /// dropped: at worst that rung celebrates once more.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        celebratedLevel = try container.decode(Int.self, forKey: .celebratedLevel)
        let version = JSONFileFormat.schemaVersion(of: decoder) ?? Self.schemaVersion
        if version < 2 {
            let legacy = try container.decode([RungReferenceV1].self, forKey: .celebratedRungs)
            celebratedRungs = Set(legacy.compactMap(\.migrated))
        } else {
            celebratedRungs = try container.decode(Set<RungReference>.self, forKey: .celebratedRungs)
        }
    }
}
