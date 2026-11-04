import Foundation

// MARK: - RungReference
/// A stable pointer to one rung of one path: the path plus the rung's step ID
/// (the exercise trained on it, see `ProgressionStep.id`). Used to record which
/// rung advancements have already been celebrated (see `SkillProgress`), so a
/// celebration plays exactly once.
///
/// The step ID, not the rung's position, is the identity, so inserting or
/// reordering rungs in `ProgressionCatalog` never remaps a stored reference.
/// Resolve the current position with `rungIndex` when a screen needs it.
nonisolated struct RungReference: Codable, Equatable, Hashable, Sendable {
    let pathID: ProgressionPathID
    /// The exercise ID of the rung's step.
    let stepID: UUID

    init(pathID: ProgressionPathID, stepID: UUID) {
        self.pathID = pathID
        self.stepID = stepID
    }

    /// The reference to the rung at `rungIndex` of the path in the current
    /// catalog, or `nil` when the path has no such rung.
    init?(pathID: ProgressionPathID, rungIndex: Int) {
        guard let steps = ProgressionCatalog.path(withID: pathID)?.steps,
              steps.indices.contains(rungIndex)
        else { return nil }
        self.init(pathID: pathID, stepID: steps[rungIndex].id)
    }

    /// The rung's position in the current catalog, or `nil` when the step is
    /// no longer on the path.
    var rungIndex: Int? {
        ProgressionCatalog.path(withID: pathID)?.steps.firstIndex { $0.id == stepID }
    }

    /// The rung's step in the current catalog, or `nil` when it is no longer on
    /// the path.
    var step: ProgressionStep? {
        ProgressionCatalog.path(withID: pathID)?.steps.first { $0.id == stepID }
    }
}

// MARK: - Schema version 1
/// The version 1 shape of a rung reference, `{"pathID": …, "rungIndex": …}`,
/// where the index points into the ladder order frozen in `LadderOrderV1`.
nonisolated struct RungReferenceV1: Decodable {
    let pathID: ProgressionPathID
    let rungIndex: Int

    /// The same rung as a stable reference, or `nil` when the index was never
    /// valid for the path.
    var migrated: RungReference? {
        LadderOrderV1.stepID(for: pathID, rungIndex: rungIndex)
            .map { RungReference(pathID: pathID, stepID: $0) }
    }
}
