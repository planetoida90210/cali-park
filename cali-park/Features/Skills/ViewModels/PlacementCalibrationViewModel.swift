import Foundation
import Observation

// MARK: - PlacementCalibrationViewModel
/// Drives the placement form shared by onboarding and the in-app calibration
/// sheet: it holds the athlete's answers, turns them into a `SkillPlacement`
/// through `PlacementCalibration`, and persists it through `PlacementStoring`.
///
/// Re-calibration starts from the saved placement: answers that map back to it
/// unambiguously are pre-filled, and saving changes only the paths the athlete
/// answered in this session (`PlacementCalibration.merging`), so adjusting one
/// ladder never erases the others. The engine protects rungs already earned
/// from logs, so a downward re-calibration is safe. The declared date is
/// injected for deterministic tests.
@MainActor
@Observable
final class PlacementCalibrationViewModel {
    /// The questions to present, straight from the shared calibration definition.
    let repQuestions = PlacementCalibration.repQuestions
    let skillQuestions = PlacementCalibration.skillQuestions

    /// Selected rep bucket per path; a path absent here has no answer yet.
    private(set) var repAnswers: [ProgressionPathID: RepCountBucket] = [:]
    /// Identifiers of the skills the athlete marked as already owned.
    private(set) var masteredSkills: Set<String> = []
    /// Whether the athlete owns a resistance band (an optional parallel track).
    /// The form no longer asks (ticket 026); this carries a band declared
    /// earlier through re-calibration so a save never drops it.
    var ownsBand: Bool

    var errorMessage: String?
    /// Set after a successful save so the presenter can dismiss.
    private(set) var didSave = false

    /// Paths whose answers changed in this session; only these are re-declared.
    private(set) var answeredPaths: Set<ProgressionPathID> = []
    /// The saved placement the form started from, for showing what a path
    /// declares when its answer could not be pre-filled.
    private let savedPlacement: SkillPlacement?

    private let store: PlacementStoring
    private let now: () -> Date
    /// Runs after a successful save, so shared progress re-reads the placement.
    private let onSave: @MainActor () -> Void

    // MARK: Init
    init(store: PlacementStoring,
         now: @escaping () -> Date = { .now },
         onSave: @escaping @MainActor () -> Void = {}) {
        self.store = store
        self.now = now
        self.onSave = onSave
        // Pre-fill from any prior declaration so re-calibration starts from
        // what the athlete already told us. An unreadable placement only loses
        // the pre-fill; saving reports the error.
        savedPlacement = try? store.load()
        ownsBand = savedPlacement?.ownsEquipment(PlacementCalibration.bandEquipment) ?? false
        if let savedPlacement {
            let answers = PlacementCalibration.answers(from: savedPlacement)
            repAnswers = answers.repAnswers
            masteredSkills = answers.masteredSkills
        }
    }

    // MARK: Answers
    /// The selected bucket for a rep question, or `nil` when unanswered.
    func bucket(for question: RepCountQuestion) -> RepCountBucket? {
        repAnswers[question.id]
    }

    /// Records the athlete's answer to a rep question (single choice).
    func select(_ bucket: RepCountBucket, for question: RepCountQuestion) {
        repAnswers[question.id] = bucket
        answeredPaths.insert(question.path)
    }

    /// The saved declaration for a rep question's path that no bucket shows,
    /// e.g. "Podciągnięcia" when both 1–5 and 6–11 lead there. `nil` when the
    /// path has no saved declaration, a bucket or a checked skill already
    /// shows it, or the athlete answered the path in this session.
    func savedRungName(for question: RepCountQuestion) -> String? {
        let shownBySkill = skillQuestions.contains { $0.path == question.path && masteredSkills.contains($0.id) }
        guard repAnswers[question.id] == nil,
              !shownBySkill,
              !answeredPaths.contains(question.path),
              let step = savedPlacement?.declaredReference(for: question.path)?.step
        else { return nil }
        return ExerciseCatalog.exercise(withID: step.exerciseID)?.name
    }

    /// Whether the athlete marked a skill as already owned.
    func isMastered(_ question: SkillQuestion) -> Bool {
        masteredSkills.contains(question.id)
    }

    /// Flips whether a skill is marked as owned.
    func toggleMastery(of question: SkillQuestion) {
        if masteredSkills.contains(question.id) {
            masteredSkills.remove(question.id)
        } else {
            masteredSkills.insert(question.id)
        }
        answeredPaths.insert(question.path)
    }

    // MARK: Result
    /// The placement the current answers describe, on their own.
    var placement: SkillPlacement {
        PlacementCalibration.placement(
            repAnswers: repAnswers,
            masteredSkills: masteredSkills,
            ownsBand: ownsBand,
            declaredAt: now()
        )
    }

    /// Persists the answered paths over the saved placement, setting `didSave`
    /// on success. The saved placement is re-read here, so the merge is made
    /// against what is on disk now, and an unreadable one fails the save
    /// instead of being replaced.
    func save() {
        do {
            let saved = try store.load()
            try store.save(PlacementCalibration.merging(placement, answeredPaths: answeredPaths, into: saved))
            didSave = true
            onSave()
        } catch {
            errorMessage = "Nie udało się zapisać poziomu."
        }
    }
}
