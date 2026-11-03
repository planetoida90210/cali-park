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
///   said they were past it), so it does not celebrate, but it is recorded as
///   seen, so lowering the floor later never celebrates it either. Conquering
///   the declared rung or anything above it does celebrate.
/// - **Baseline, not a flood.** The first evaluation (no prior record) silently
///   adopts everything already earned as its baseline and celebrates nothing,
///   so an athlete upgrading with a long history is not buried in overlays.
///   Every later evaluation celebrates only what is genuinely new, exactly once.
enum RewardEvaluator {
    /// The events to celebrate and the record to persist now.
    ///
    /// - Parameters:
    ///   - logs: The whole workout-log history.
    ///   - placement: The athlete's declaration, used only as a per-path floor;
    ///     it never adds events.
    ///   - celebrated: The last saved record of what has been celebrated, or
    ///     `nil` on the very first evaluation (which seeds a silent baseline).
    /// - Returns: Pending events in display order (conquered rungs first, then
    ///   level-ups), plus the record to save now. That record holds the
    ///   baseline and the rungs recorded silently below the floor, but not the
    ///   pending events: mark each one as it is shown.
    static func evaluate(logs: [WorkoutLogEntry],
                         placement: SkillPlacement?,
                         celebrated: SkillProgress?) -> RewardEvaluation {
        let conqueredRungs = conqueredRungReferences(from: logs)
        let currentLevel = ProgressionEngine.playerLevel(for: logs).level

        // First run: adopt the current standing as the baseline, celebrate
        // nothing. A returning athlete's history is not a stream of surprises.
        guard let celebrated else {
            return RewardEvaluation(
                pendingEvents: [],
                updatedProgress: SkillProgress(celebratedRungs: conqueredRungs, celebratedLevel: currentLevel)
            )
        }

        // Every fresh rung is either celebrated (at or above the floor) or
        // recorded silently (below it). Recording the silent ones is what keeps
        // a later, lower floor from celebrating them as new.
        let freshRungs = conqueredRungs.subtracting(celebrated.celebratedRungs)
        let celebratable = freshRungs.filter { isAtOrAboveFloor($0, placement: placement) }
        let belowFloor = freshRungs.subtracting(celebratable)

        let levelEvents = currentLevel > celebrated.celebratedLevel
            ? ((celebrated.celebratedLevel + 1)...currentLevel).map(CelebrationEvent.levelReached)
            : []

        // Rungs read as the build-up, the level-up as the finale.
        let events = orderedRungEvents(from: celebratable) + levelEvents

        // Pending events are not in the record yet: each one is added when it
        // has been shown (`SkillProgress.markingCelebrated`).
        let updatedProgress = SkillProgress(
            celebratedRungs: celebrated.celebratedRungs.union(belowFloor),
            celebratedLevel: celebrated.celebratedLevel
        )

        return RewardEvaluation(pendingEvents: events, updatedProgress: updatedProgress)
    }

    // MARK: Helpers

    /// Every rung the logs have conquered, on every path. Scored with no
    /// placement, so declarations add nothing.
    private static func conqueredRungReferences(from logs: [WorkoutLogEntry]) -> Set<RungReference> {
        let logStates = ProgressionEngine.pathStates(logs: logs, placement: nil)
        var references: Set<RungReference> = []
        for path in ProgressionCatalog.all {
            guard let state = logStates[path.id] else { continue }
            for step in path.steps.prefix(state.conqueredRungCount) {
                references.insert(RungReference(pathID: path.id, stepID: step.id))
            }
        }
        return references
    }

    /// Whether a rung sits at or above the path's declared floor. Conquering a
    /// rung below it is not a fresh advance: the athlete already said they were
    /// past it.
    private static func isAtOrAboveFloor(_ rung: RungReference, placement: SkillPlacement?) -> Bool {
        let floor = placement?.declaredRung(for: rung.pathID) ?? 0
        return (rung.rungIndex ?? 0) >= floor
    }

    /// Fresh rung advances ordered deterministically by catalog path order, then
    /// by rung position, so a burst of advances always celebrates bottom-up.
    private static func orderedRungEvents(from rungs: Set<RungReference>) -> [CelebrationEvent] {
        let pathOrder = Dictionary(
            uniqueKeysWithValues: ProgressionCatalog.all.enumerated().map { ($0.element.id, $0.offset) }
        )
        return rungs
            .sorted { lhs, rhs in
                let lhsPath = pathOrder[lhs.pathID] ?? Int.max
                let rhsPath = pathOrder[rhs.pathID] ?? Int.max
                if lhsPath != rhsPath { return lhsPath < rhsPath }
                return (lhs.rungIndex ?? Int.max) < (rhs.rungIndex ?? Int.max)
            }
            .map(CelebrationEvent.rungConquered)
    }
}
