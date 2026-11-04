import Foundation

// MARK: - PlacementCalibration
/// Turns onboarding answers into a `SkillPlacement`.
///
/// The questions are a deliberately short set — a few rep counts plus a handful
/// of "can you already do this?" checkboxes — chosen so a newcomer and a veteran
/// both land on a sensible starting rung without a long quiz. Paths left unasked
/// simply get no declaration and start from the bottom, where logs take over.
///
/// This mapping is the single source of truth shared by the onboarding level test and the
/// in-app calibration sheet, and it mirrors the ladders in `docs/PROGRESSIONS.md`.
/// A declaration only sets a starting point: it never grants XP or badges (those
/// come from real logs), and the engine takes the max of declaration and logs so
/// re-calibrating down never erases a rung already earned by training.
nonisolated enum PlacementCalibration {
    /// Equipment key for the resistance band, matching `Park.equipments`.
    static let bandEquipment = "Resistance bands"

    // MARK: Questions
    /// Rep-count questions, one per rep-based path. A count never conquers a
    /// variant harder than the counted movement (see `RepCountQuestion`); those
    /// come from logs or, for skills a count can't capture, the checkboxes below.
    ///
    /// Answers name rungs by step ID, so inserting rungs never changes where
    /// an answer lands. After the 2026-11 revision (ticket 015) the outcomes
    /// are the same as before except dips at "12+", which now start on the
    /// ring support hold that RR asks for before ring dips.
    static let repQuestions: [RepCountQuestion] = [
        RepCountQuestion(
            path: .pullUp,
            prompt: String(localized: "Ile pełnych podciągnięć robisz w jednej serii?"),
            zeroRepStep: ExerciseCatalog.negativePullUpsID,
            movementStep: ExerciseCatalog.pullUpsID,
            nextVariantStep: ExerciseCatalog.lPullUpsID
        ),
        RepCountQuestion(
            path: .pushUp,
            prompt: String(localized: "Ile pełnych pompek robisz w jednej serii?"),
            zeroRepStep: ExerciseCatalog.kneePushUpsID,
            movementStep: ExerciseCatalog.pushUpsID,
            nextVariantStep: ExerciseCatalog.diamondPushUpsID
        ),
        RepCountQuestion(
            path: .dip,
            prompt: String(localized: "Ile dipów na poręczach robisz w jednej serii?"),
            zeroRepStep: ExerciseCatalog.negativeDipsID,
            movementStep: ExerciseCatalog.dipsID,
            nextVariantStep: ExerciseCatalog.ringSupportHoldID
        ),
        RepCountQuestion(
            path: .legs,
            prompt: String(localized: "Ile przysiadów robisz w jednej serii?"),
            zeroRepStep: ExerciseCatalog.assistedSquatsID,
            movementStep: ExerciseCatalog.squatsID,
            nextVariantStep: ExerciseCatalog.lungesID
        )
    ]

    /// Skill checkboxes for movements that a rep count cannot capture. Each
    /// declares the skill itself as the current rung, so checking it actually
    /// moves the start point.
    static let skillQuestions: [SkillQuestion] = [
        SkillQuestion(id: "muscleUp", path: .muscleUp, label: String(localized: "Muscle-up"), step: ExerciseCatalog.muscleUpID),
        SkillQuestion(id: "fullLSit", path: .lSit, label: String(localized: "Pełny L-sit"), step: ExerciseCatalog.lSitID),
        SkillQuestion(
            id: "pistolSquat", path: .legs,
            label: String(localized: "Pistolet (przysiad na jednej nodze)"),
            step: ExerciseCatalog.pistolSquatsID)
    ]

    // MARK: Reducer
    /// The placement declared by a set of answers. Several answers targeting the
    /// same path resolve to the highest declared rung, matching the engine's
    /// "everything below the current rung is conquered" rule.
    static func placement(
        repAnswers: [ProgressionPathID: RepCountBucket],
        masteredSkills: Set<String>,
        ownsBand: Bool,
        declaredAt: Date = .now
    ) -> SkillPlacement {
        var declared: [ProgressionPathID: RungReference] = [:]

        // Keeps the higher of two declarations on one path, by current position.
        func declare(_ step: UUID, on path: ProgressionPathID) {
            let candidate = RungReference(pathID: path, stepID: step)
            guard let index = candidate.rungIndex else { return }
            if let existing = declared[path]?.rungIndex, existing >= index { return }
            declared[path] = candidate
        }

        for question in repQuestions {
            guard let bucket = repAnswers[question.id] else { continue }
            declare(question.step(for: bucket), on: question.path)
        }

        for question in skillQuestions where masteredSkills.contains(question.id) {
            declare(question.step, on: question.path)
        }

        // A bottom-rung declaration is identical to no declaration (nothing
        // below to conquer), so drop it to keep the stored map minimal and
        // meaningful.
        let meaningfulDeclarations =
            declared
            .filter { ($0.value.rungIndex ?? 0) > 0 }
            .mapValues(\.stepID)

        return SkillPlacement(
            declaredStepByPath: meaningfulDeclarations,
            ownedEquipment: ownsBand ? [bandEquipment] : [],
            declaredAt: declaredAt
        )
    }

    // MARK: Re-calibration
    /// The form answers that reproduce a saved placement, for pre-filling the
    /// form on re-calibration. Only unambiguous answers come back: a rung that
    /// several buckets declare (1–5 and 6–11 both place you on the movement
    /// itself), or that no answer declares, stays unanswered. `merging` keeps
    /// the saved declaration for such a path as long as the athlete does not
    /// answer it again.
    static func answers(from placement: SkillPlacement) -> (
        repAnswers: [ProgressionPathID: RepCountBucket],
        masteredSkills: Set<String>
    ) {
        var repAnswers: [ProgressionPathID: RepCountBucket] = [:]
        var masteredSkills: Set<String> = []

        for question in skillQuestions where placement.declaredStepByPath[question.path] == question.step {
            masteredSkills.insert(question.id)
        }

        for question in repQuestions {
            guard let declaredStep = placement.declaredStepByPath[question.path] else { continue }
            // A checked skill explains this rung; the rep count is unknown.
            let explainedBySkill = skillQuestions.contains {
                $0.path == question.path && masteredSkills.contains($0.id)
            }
            guard !explainedBySkill else { continue }
            let matching = RepCountBucket.allCases.filter { question.step(for: $0) == declaredStep }
            if matching.count == 1, let bucket = matching.first {
                repAnswers[question.path] = bucket
            }
        }

        return (repAnswers, masteredSkills)
    }

    /// The placement to save after a re-calibration: the paths answered in this
    /// session take their new declaration (or lose it, when the new answer
    /// declares nothing), every other path keeps what `saved` declared. So
    /// answering one question never erases the others.
    ///
    /// - Parameters:
    ///   - answers: The placement the session's answers describe (`placement(…)`).
    ///   - answeredPaths: The paths whose answers the athlete changed in this
    ///     session.
    ///   - saved: The placement saved before this session, or `nil` on first
    ///     calibration.
    static func merging(
        _ answers: SkillPlacement,
        answeredPaths: Set<ProgressionPathID>,
        into saved: SkillPlacement?
    ) -> SkillPlacement {
        guard let saved else { return answers }

        var declarations = saved.declaredStepByPath.filter { !answeredPaths.contains($0.key) }
        for (path, stepID) in answers.declaredStepByPath where answeredPaths.contains(path) {
            declarations[path] = stepID
        }

        // The form only asks about the band; keep any other equipment.
        var equipment = saved.ownedEquipment.subtracting([bandEquipment])
        equipment.formUnion(answers.ownedEquipment)

        return SkillPlacement(
            declaredStepByPath: declarations,
            ownedEquipment: equipment,
            declaredAt: answers.declaredAt
        )
    }
}
