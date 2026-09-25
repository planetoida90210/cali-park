import Foundation

// MARK: - PlacementCalibration
/// Turns onboarding answers into a `SkillPlacement`.
///
/// The questions are a deliberately short set — a few rep counts plus a handful
/// of "can you already do this?" checkboxes — chosen so a newcomer and a veteran
/// both land on a sensible starting rung without a long quiz. Paths left unasked
/// simply get no declaration and start from the bottom, where logs take over.
///
/// This mapping is the single source of truth shared by onboarding (SK4) and the
/// in-app calibration sheet, and it mirrors the ladders in `docs/PROGRESSIONS.md`.
/// A declaration only sets a starting point: it never grants XP or badges (those
/// come from real logs), and the engine takes the max of declaration and logs so
/// re-calibrating down never erases a rung already earned by training.
enum PlacementCalibration {
    /// Equipment key for the resistance band, matching `Park.equipments`.
    static let bandEquipment = "Resistance bands"

    // MARK: Questions
    /// Rep-count questions, one per rep-based path. A count never conquers a
    /// variant harder than the counted movement (see `RepCountQuestion`); those
    /// come from logs or, for skills a count can't capture, the checkboxes below.
    static let repQuestions: [RepCountQuestion] = [
        RepCountQuestion(
            path: .pullUp,
            prompt: "Ile pełnych podciągnięć robisz w jednej serii?",
            zeroRepRung: 2,     // negatives
            movementRung: 4     // pull-ups
        ),
        RepCountQuestion(
            path: .pushUp,
            prompt: "Ile pełnych pompek robisz w jednej serii?",
            zeroRepRung: 2,     // knee push-ups
            movementRung: 3     // push-ups
        ),
        RepCountQuestion(
            path: .dip,
            prompt: "Ile dipów na poręczach robisz w jednej serii?",
            zeroRepRung: 1,     // negatives
            movementRung: 2     // dips
        ),
        RepCountQuestion(
            path: .legs,
            prompt: "Ile przysiadów robisz w jednej serii?",
            zeroRepRung: 0,     // assisted squats
            movementRung: 1     // squats
        )
    ]

    /// Skill checkboxes for movements that a rep count cannot capture. Each
    /// declares a rung above zero so checking it actually moves the start point.
    static let skillQuestions: [SkillQuestion] = [
        SkillQuestion(id: "muscleUp", path: .muscleUp, label: "Muscle-up", rung: 3),
        SkillQuestion(id: "fullLSit", path: .lSit, label: "Pełny L-sit", rung: 3),
        SkillQuestion(id: "pistolSquat", path: .legs, label: "Pistolet (przysiad na jednej nodze)", rung: 5)
    ]

    // MARK: Reducer
    /// The placement declared by a set of answers. Several answers targeting the
    /// same path resolve to the highest declared rung, matching the engine's
    /// "everything below the current rung is conquered" rule.
    static func placement(repAnswers: [ProgressionPathID: RepCountBucket],
                          masteredSkills: Set<String>,
                          ownsBand: Bool,
                          declaredAt: Date = .now) -> SkillPlacement {
        var declaredRungByPath: [ProgressionPathID: Int] = [:]

        for question in repQuestions {
            guard let bucket = repAnswers[question.id] else { continue }
            let rung = question.rung(for: bucket)
            declaredRungByPath[question.path] = max(declaredRungByPath[question.path] ?? 0, rung)
        }

        for question in skillQuestions where masteredSkills.contains(question.id) {
            declaredRungByPath[question.path] = max(declaredRungByPath[question.path] ?? 0, question.rung)
        }

        // A rung-0 declaration is identical to no declaration (nothing below to
        // conquer), so drop it to keep the stored map minimal and meaningful.
        let meaningfulDeclarations = declaredRungByPath.filter { $0.value > 0 }

        return SkillPlacement(
            declaredRungByPath: meaningfulDeclarations,
            ownedEquipment: ownsBand ? [bandEquipment] : [],
            declaredAt: declaredAt
        )
    }
}
