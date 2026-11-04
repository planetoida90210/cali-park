import Foundation

// MARK: - ProgramStartError
enum ProgramStartError: Error, Equatable {
    /// The journal or the placement exists but can't be read, so the current
    /// rungs are unknown. Nothing was saved.
    case ladderStateUnreadable
    /// A plan could not be saved.
    case saveFailed
}

// MARK: - ProgramStarter
/// Creates the plans of a ready-made program for the athlete: reads their
/// ladder state from the shared `ProgressService`, prescribes the plans with
/// `ProgramPrescriber`, and saves them through `WorkoutPlanService`. Shared by
/// the Planner's program screens and onboarding.
@MainActor
final class ProgramStarter {
    private let planService: WorkoutPlanService
    private let progress: ProgressService
    private let clock: () -> Date

    init(planService: WorkoutPlanService,
         progress: ProgressService,
         clock: @escaping () -> Date = { .now }) {
        self.planService = planService
        self.progress = progress
        self.clock = clock
    }

    /// The athlete's state on every ladder. Throws
    /// `ProgramStartError.ladderStateUnreadable` when a store can't be read:
    /// prescribing from an empty journal would put everyone on the bottom
    /// rung.
    func pathStates() throws -> [ProgressionPathID: PathState] {
        progress.reloadIfFailed()
        guard !progress.hasLoadError else { throw ProgramStartError.ladderStateUnreadable }
        return progress.snapshot.pathStates
    }

    /// The plans the program would create now, without saving them.
    func preview(_ program: TrainingProgram) throws -> [WorkoutPlan] {
        ProgramPrescriber.plans(for: program, pathStates: try pathStates(), today: clock())
    }

    /// Prescribes and saves the program's plans, returning them as saved.
    /// The plans have no reminder, so a reminder sync failure doesn't matter.
    func start(_ program: TrainingProgram) async throws -> [WorkoutPlan] {
        let plans = try preview(program)
        var saved: [WorkoutPlan] = []
        for plan in plans {
            do {
                try await planService.save(plan)
            } catch {
                throw ProgramStartError.saveFailed
            }
            saved.append(plan)
        }
        return saved
    }
}
