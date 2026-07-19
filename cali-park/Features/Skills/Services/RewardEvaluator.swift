import Foundation

// MARK: - RewardEvaluator
/// Decides which advances deserve a celebration, comparing what the logs have
/// earned against what has already been celebrated.
///
/// Pure and deterministic: every result depends only on the inputs. Three rules
/// keep the reward loop honest:
///
/// - **Logs earn celebrations, declarations never do.** A rung is celebratable
///   only once the logs conquer it. A declaration adds no events — it only sets
///   a floor (below).
/// - **From the placement up.** A declared starting rung is a floor: conquering
///   a rung *below* it through logs is not a fresh advance (the athlete already
///   said they were past it), so it does not celebrate. Conquering the declared
///   rung or anything above it does.
/// - **Baseline, not a flood.** The first evaluation (no prior record) silently
///   adopts everything already earned as its baseline and celebrates nothing,
///   so an athlete upgrading with a long history is not buried in overlays.
///   Every later evaluation celebrates only what is genuinely new, exactly once.
enum RewardEvaluator {
    /// The events to celebrate now and the record to persist afterward.
    ///
    /// - Parameters:
    ///   - logs: The whole workout-log history.
    ///   - placement: The athlete's declaration, used only as a per-path floor;
    ///     it never adds events.
    ///   - celebrated: The last saved record of what has been celebrated, or
    ///     `nil` on the very first evaluation (which seeds a silent baseline).
    /// - Returns: Pending events in display order (conquered rungs first, then
    ///   level-ups), plus the updated record to save.
    static func evaluate(logs: [WorkoutLogEntry],
                         placement: SkillPlacement?,
                         celebrated: SkillProgress?) -> RewardEvaluation {
        let conqueredRungs = celebratableRungReferences(from: logs, placement: placement)
        let currentLevel = ProgressionEngine.playerLevel(for: logs).level

        // First run: adopt the current standing as the baseline, celebrate
        // nothing. A returning athlete's history is not a stream of surprises.
        guard let celebrated else {
            return RewardEvaluation(
                pendingEvents: [],
                updatedProgress: SkillProgress(celebratedRungs: conqueredRungs, celebratedLevel: currentLevel)
            )
        }

        let freshRungs = conqueredRungs.subtracting(celebrated.celebratedRungs)
        let rungEvents = orderedRungEvents(from: freshRungs)

        let levelEvents = currentLevel > celebrated.celebratedLevel
            ? ((celebrated.celebratedLevel + 1)...currentLevel).map(CelebrationEvent.levelReached)
            : []

        // Rungs read as the build-up, the level-up as the finale.
        let events = rungEvents + levelEvents

        let updatedProgress = SkillProgress(
            celebratedRungs: celebrated.celebratedRungs.union(conqueredRungs),
            celebratedLevel: max(celebrated.celebratedLevel, currentLevel)
        )

        return RewardEvaluation(pendingEvents: events, updatedProgress: updatedProgress)
    }

    // MARK: Helpers

    /// The rungs the logs have conquered that sit at or above the declared
    /// floor — the ones a real advance can celebrate. Scored with an empty
    /// placement so declarations add nothing; the declaration only raises the
    /// floor below which logged rungs are treated as already-owned.
    private static func celebratableRungReferences(from logs: [WorkoutLogEntry],
                                                    placement: SkillPlacement?) -> Set<RungReference> {
        let logStates = ProgressionEngine.pathStates(logs: logs, placement: nil)
        var references: Set<RungReference> = []
        for path in ProgressionCatalog.all {
            guard let state = logStates[path.id] else { continue }
            let floor = placement?.declaredRung(for: path.id) ?? 0
            for index in 0..<state.conqueredRungCount where index >= floor {
                references.insert(RungReference(pathID: path.id, rungIndex: index))
            }
        }
        return references
    }

    /// Fresh rung advances ordered deterministically by catalog path order, then
    /// by rung index, so a burst of advances always celebrates bottom-up.
    private static func orderedRungEvents(from rungs: Set<RungReference>) -> [CelebrationEvent] {
        let pathOrder = Dictionary(
            uniqueKeysWithValues: ProgressionCatalog.all.enumerated().map { ($0.element.id, $0.offset) }
        )
        return rungs
            .sorted { lhs, rhs in
                let lhsPath = pathOrder[lhs.pathID] ?? Int.max
                let rhsPath = pathOrder[rhs.pathID] ?? Int.max
                if lhsPath != rhsPath { return lhsPath < rhsPath }
                return lhs.rungIndex < rhs.rungIndex
            }
            .map(CelebrationEvent.rungConquered)
    }
}
