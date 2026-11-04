import Foundation
import Observation

// MARK: - ProgramGraduationViewModel
/// The "Czas na Fundamenty" card in the Planner. It shows when a plan from
/// "Pierwsze podciągnięcie" has done its job (full pull-ups conquered, see
/// `ProgramPrescriber.isReadyToGraduate`). "Przejdź na Fundamenty" replaces
/// that plan with "Fundamenty" on the same days in one tap, through the
/// same `ProgramStarter` as "Utwórz plan"; "Nie teraz" hides the card for
/// good (`DefaultsKey.hasDismissedFundamentalsHint`).
@MainActor
@Observable
final class ProgramGraduationViewModel {
    // MARK: State
    /// The plan to move on from, while the card is shown.
    private(set) var candidate: WorkoutPlan?
    private(set) var isReplacing = false
    var errorMessage: String?

    // MARK: Dependencies
    private let starter: ProgramStarter
    private let defaults: UserDefaults

    // MARK: Init
    /// Reads nothing; the view calls `reload()` on appear.
    init(starter: ProgramStarter, defaults: UserDefaults) {
        self.starter = starter
        self.defaults = defaults
    }

    private var isDismissed: Bool {
        defaults.bool(forKey: DefaultsKey.hasDismissedFundamentalsHint.rawValue)
    }

    // MARK: Intentions
    /// Re-reads the plans and the ladder state.
    func reload() {
        candidate = isDismissed ? nil : starter.graduationCandidate()
    }

    /// "Nie teraz": hides the card and never shows it again.
    func dismiss() {
        defaults.set(true, forKey: DefaultsKey.hasDismissedFundamentalsHint.rawValue)
        candidate = nil
    }

    /// "Przejdź na Fundamenty": replaces the plan and returns the new plan to
    /// open in the editor, or `nil` when nothing was created. The card does
    /// not come back afterwards.
    func moveOn() async -> WorkoutPlan? {
        guard let plan = candidate, !isReplacing else { return nil }
        isReplacing = true
        defer { isReplacing = false }

        do {
            let created = try await starter.replace(plan, with: ProgramCatalog.fundamentals)
            dismiss()
            return created.first
        } catch ProgramStartError.replacedPlanKept {
            dismiss()
            errorMessage = String(localized: "Plan Fundamenty jest gotowy, ale nie udało się usunąć planu \(plan.name). Usuń go z listy.")
            return nil
        } catch ProgramStartError.ladderStateUnreadable {
            errorMessage = StoreLoadFailure.message
            return nil
        } catch {
            errorMessage = String(localized: "Nie udało się utworzyć planu.")
            return nil
        }
    }
}
