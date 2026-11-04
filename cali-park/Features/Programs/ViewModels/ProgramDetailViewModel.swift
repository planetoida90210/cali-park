import Foundation
import Observation

// MARK: - ProgramDetailViewModel
/// Drives one program's detail screen: shows what the program would create on
/// the athlete's current rungs, and "Utwórz plan" saves those plans through
/// `ProgramStarter` (which goes through `WorkoutPlanService`). The created
/// plans are ordinary plans; the presenter opens the first one in the editor.
@MainActor
@Observable
final class ProgramDetailViewModel {
    // MARK: State
    let program: TrainingProgram
    /// The plans "Utwórz plan" would create now, for the preview.
    private(set) var previewPlans: [WorkoutPlan] = []
    /// The athlete has no full pull-up yet, so "Fundamenty" points them to
    /// "Pierwsze podciągnięcie" first.
    private(set) var showsFirstPullUpHint = false
    /// The journal or placement could not be read, so the rungs are unknown
    /// and nothing can be created.
    private(set) var hasLoadError = false
    private(set) var isCreating = false
    /// The plans saved by `create()`, once it succeeded.
    private(set) var createdPlans: [WorkoutPlan]?
    var errorMessage: String?
    /// A plan from this program already exists, so "Utwórz plan" asks
    /// before making a second one.
    var asksToCreateAnother = false

    // MARK: Dependencies
    private let starter: ProgramStarter

    // MARK: Init
    init(program: TrainingProgram, starter: ProgramStarter) {
        self.program = program
        self.starter = starter
        reload()
    }

    // MARK: Derived state
    var canCreate: Bool { !hasLoadError && !isCreating && createdPlans == nil }

    // MARK: Intentions
    /// Re-reads the ladder state and rebuilds the preview.
    func reload() {
        do {
            let states = try starter.pathStates()
            previewPlans = ProgramPrescriber.plans(for: program, pathStates: states)
            showsFirstPullUpHint = program.id == .fundamentals && ProgramPrescriber.needsFirstPullUp(states)
            hasLoadError = false
        } catch {
            if !hasLoadError { errorMessage = StoreLoadFailure.message }
            hasLoadError = true
        }
    }

    /// "Utwórz plan": asks first when a plan from this program already
    /// exists (`asksToCreateAnother`), otherwise creates right away.
    func requestCreate() async {
        guard canCreate else { return }
        if starter.hasPlan(from: program) {
            asksToCreateAnother = true
        } else {
            await create()
        }
    }

    /// Creates and saves the program's plans. No-op unless `canCreate`.
    func create() async {
        guard canCreate else { return }
        isCreating = true
        defer { isCreating = false }

        do {
            createdPlans = try await starter.start(program)
        } catch ProgramStartError.ladderStateUnreadable {
            hasLoadError = true
            errorMessage = StoreLoadFailure.message
        } catch {
            errorMessage = String(localized: "Nie udało się utworzyć planu.")
        }
    }

    // MARK: Presentation
    func exercise(for planned: PlannedExercise) -> Exercise? {
        ExerciseCatalog.exercise(withID: planned.exerciseID)
    }

    /// What to do on an item, e.g. "Para 1 · 3 × 5–8 · przerwa 90 s".
    func targetSummary(for planned: PlannedExercise, in plan: WorkoutPlan) -> String? {
        let parts = [
            ProgramFormat.groupLabel(for: planned, in: plan.exercises),
            ProgramFormat.doseSummary(for: planned, exercise: exercise(for: planned)),
            ProgramFormat.restSummary(for: planned)
        ].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// The schedule the created plans start with, e.g. "Co tydzień · Pon, Śr, Pt".
    var scheduleSummary: String {
        WorkoutScheduleFormatter.summary(.weekly(program.weekdays))
    }
}
