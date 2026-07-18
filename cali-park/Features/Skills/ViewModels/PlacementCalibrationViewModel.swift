import Foundation
import Observation

// MARK: - PlacementCalibrationViewModel
/// Drives the placement form shared by onboarding and the in-app calibration
/// sheet: it holds the athlete's answers, turns them into a `SkillPlacement`
/// through `PlacementCalibration`, and persists it through `PlacementStoring`.
///
/// The declared date is injected for deterministic tests. Saving re-declares the
/// placement; the engine protects rungs already earned from logs, so a downward
/// re-calibration is safe.
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
    var ownsBand: Bool

    var errorMessage: String?
    /// Set after a successful save so the presenter can dismiss.
    private(set) var didSave = false

    private let store: PlacementStoring
    private let now: () -> Date

    // MARK: Init
    init(store: PlacementStoring, now: @escaping () -> Date = { .now }) {
        self.store = store
        self.now = now
        // Pre-fill the unambiguous equipment answer from any prior declaration so
        // re-calibration starts from what the athlete already told us.
        ownsBand = store.load()?.ownsEquipment(PlacementCalibration.bandEquipment) ?? false
    }

    // MARK: Answers
    /// The selected bucket for a rep question, or `nil` when unanswered.
    func bucket(for question: RepCountQuestion) -> RepCountBucket? {
        repAnswers[question.id]
    }

    /// Records the athlete's answer to a rep question (single choice).
    func select(_ bucket: RepCountBucket, for question: RepCountQuestion) {
        repAnswers[question.id] = bucket
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
    }

    // MARK: Result
    /// The placement the current answers describe.
    var placement: SkillPlacement {
        PlacementCalibration.placement(
            repAnswers: repAnswers,
            masteredSkills: masteredSkills,
            ownsBand: ownsBand,
            declaredAt: now()
        )
    }

    /// Persists the declared placement, setting `didSave` on success.
    func save() {
        do {
            try store.save(placement)
            didSave = true
        } catch {
            errorMessage = "Nie udało się zapisać poziomu. Spróbuj ponownie."
        }
    }
}
