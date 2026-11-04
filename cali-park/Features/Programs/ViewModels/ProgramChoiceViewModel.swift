import Foundation
import Observation

// MARK: - ProgramChoiceViewModel
/// Drives the onboarding step after the level test: suggests one program from
/// the answers, lets the athlete pick another or none, and creates the chosen
/// program's plans when onboarding finishes.
@MainActor
@Observable
final class ProgramChoiceViewModel {
    // MARK: Choice
    enum Choice: Hashable {
        case program(ProgramID)
        case none
    }

    // MARK: State
    let programs = ProgramCatalog.all
    /// The program the answers point to.
    private(set) var suggested: ProgramID = .fundamentals
    private(set) var choice: Choice = .program(.fundamentals)
    private(set) var isCreating = false
    var errorMessage: String?

    /// Whether the athlete picked something themselves; a new suggestion then
    /// no longer overrides their pick.
    private var hasPicked = false
    private let starter: ProgramStarter

    // MARK: Init
    init(starter: ProgramStarter) {
        self.starter = starter
    }

    // MARK: Intentions
    /// Recomputes the suggestion from the level-test answers. The choice
    /// follows it until the athlete picks something themselves.
    func updateSuggestion(for placement: SkillPlacement) {
        suggested = ProgramPrescriber.suggestedProgram(for: placement)
        if !hasPicked { choice = .program(suggested) }
    }

    func pick(_ choice: Choice) {
        self.choice = choice
        hasPicked = true
    }

    func isSuggested(_ program: TrainingProgram) -> Bool {
        program.id == suggested
    }

    /// Creates the chosen program's plans. Returns `false` and sets
    /// `errorMessage` when they could not be created; nothing to do for
    /// "Bez programu". Save the placement first, so the plans start on the
    /// rungs the athlete just declared.
    func createChosenProgram() async -> Bool {
        guard case .program(let id) = choice, let program = ProgramCatalog.program(withID: id) else { return true }
        guard !isCreating else { return false }
        isCreating = true
        defer { isCreating = false }

        do {
            _ = try await starter.start(program)
            return true
        } catch {
            errorMessage = String(
                localized: "Nie udało się utworzyć planu z programu \(program.name). Możesz to zrobić później w Planach treningowych.")
            return false
        }
    }
}
