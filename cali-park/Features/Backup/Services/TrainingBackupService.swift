import Foundation
import os

// MARK: - TrainingBackupRestoreError
/// Why an import did not replace the data.
nonisolated enum TrainingBackupRestoreError: Error, Equatable {
    /// The data on the phone could not be read, so nothing was touched: it
    /// could not have been restored if a write failed.
    case currentDataUnreadable
    /// A write failed and every store was put back as it was.
    case failedAndRolledBack
    /// A write failed and putting the old data back failed too.
    case failedRollbackIncomplete

    var message: String {
        switch self {
        case .currentDataUnreadable:
            String(localized: "\(StoreLoadFailure.message) Import przerwany, nic nie zostało zmienione.")
        case .failedAndRolledBack:
            String(localized: "Nie udało się zaimportować kopii. Przywróciliśmy dane sprzed importu.")
        case .failedRollbackIncomplete:
            String(localized: "Nie udało się zaimportować kopii ani w pełni przywrócić danych sprzed importu. Nie usuwaj apki i spróbuj zaimportować kopię jeszcze raz.")
        }
    }
}

// MARK: - TrainingBackupService
/// Reads everything the athlete owns into a `TrainingBackup` and replaces it
/// all from one, through the same stores the app uses.
///
/// The workout log is read and written through the `TrainingJournal`, the
/// app's one write path for entries, so every screen sees the import at once.
///
/// A restore is all or nothing: it first reads the current data (refusing to
/// start if any of it is unreadable), then replaces each store. If any write
/// fails, it writes the previous data back to every store written so far.
/// Afterwards progress re-reads the placement, the weekly goal reloads, the
/// reward loop starts over silently (an import is not progress), and plan
/// reminders are re-synced.
@MainActor
final class TrainingBackupService {
    private let journal: TrainingJournal
    private let planStore: WorkoutPlanStoring
    private let placementStore: PlacementStoring
    private let progressStore: SkillProgressStoring
    private let goalStore: WeeklyGoalStoring
    private let favorites: ParkFavorites
    private let exerciseFavorites: ExerciseFavorites
    private let planService: WorkoutPlanService
    private let progress: ProgressService
    private let goals: WeeklyGoalService
    private let rewards: RewardCenter
    private let logger = AppLog.logger(category: "TrainingBackup")

    /// The stores must be the ones behind the services: `planStore` behind
    /// `planService`, `placementStore` behind `progress`, `goalStore` behind
    /// `goals` and `progressStore` behind `rewards`.
    init(journal: TrainingJournal,
         planStore: WorkoutPlanStoring,
         placementStore: PlacementStoring,
         progressStore: SkillProgressStoring,
         goalStore: WeeklyGoalStoring,
         favorites: ParkFavorites,
         exerciseFavorites: ExerciseFavorites,
         planService: WorkoutPlanService,
         progress: ProgressService,
         goals: WeeklyGoalService,
         rewards: RewardCenter) {
        self.journal = journal
        self.planStore = planStore
        self.placementStore = placementStore
        self.progressStore = progressStore
        self.goalStore = goalStore
        self.favorites = favorites
        self.exerciseFavorites = exerciseFavorites
        self.planService = planService
        self.progress = progress
        self.goals = goals
        self.rewards = rewards
    }

    // MARK: Export
    /// Everything saved now. Throws when any store cannot be read, so an
    /// export never silently leaves part of the data out.
    func currentBackup() throws -> TrainingBackup {
        journal.reloadIfFailed()
        if let failure = journal.loadFailure { throw failure }
        return TrainingBackup(
            workoutLog: journal.entries,
            workoutPlans: try planStore.load(),
            placement: try placementStore.load(),
            skillProgress: try progressStore.load(),
            weeklyGoal: try goalStore.load(),
            favoriteParkIDs: try favorites.currentIDs(),
            favoriteExerciseIDs: try exerciseFavorites.currentIDs()
        )
    }

    // MARK: Import
    /// Replaces all saved data with `backup`. See the type's documentation
    /// for the all-or-nothing guarantee.
    func restore(_ backup: TrainingBackup) async throws(TrainingBackupRestoreError) {
        let previous: TrainingBackup
        do {
            previous = try currentBackup()
        } catch {
            logger.error("Import refused, current data unreadable: \(String(describing: error), privacy: .public)")
            throw .currentDataUnreadable
        }

        let steps = self.steps
        for (index, step) in steps.enumerated() {
            do {
                try step.write(backup)
            } catch {
                logger.error("Import failed, rolling back: \(String(describing: error), privacy: .public)")
                // Includes the failed step: a non-atomic write may have
                // changed part of its store before failing.
                let rolledBack = rollBack(steps[...index], to: previous)
                await finish()
                throw rolledBack ? .failedAndRolledBack : .failedRollbackIncomplete
            }
        }
        await finish()
    }

    // MARK: Steps
    /// One store's part of a restore: how to write a backup into it, and how to
    /// tell whether it already holds a backup's data.
    private struct Step {
        let write: (TrainingBackup) throws -> Void
        let holds: (TrainingBackup) -> Bool
    }

    /// Every store, in write order. The log goes last: the journal's change
    /// handlers (reminders, progress) then run against everything else
    /// already in place.
    private var steps: [Step] {
        [
            Step(write: { [placementStore] in try placementStore.replace(with: $0.placement) },
                 holds: { [placementStore] backup in (try? placementStore.load() == backup.placement) ?? false }),
            Step(write: { [progressStore] in try progressStore.replace(with: $0.skillProgress) },
                 holds: { [progressStore] backup in (try? progressStore.load() == backup.skillProgress) ?? false }),
            Step(write: { [goalStore] in try goalStore.replace(with: $0.weeklyGoal) },
                 holds: { [goalStore] backup in (try? goalStore.load() == backup.weeklyGoal) ?? false }),
            Step(write: { [planStore] in try planStore.replaceAll(with: $0.workoutPlans) },
                 holds: { [planStore] backup in (try? planStore.load() == backup.workoutPlans) ?? false }),
            // A file from before favorites existed leaves them as they are.
            Step(write: { [favorites] backup in
                     if let ids = backup.favoriteParkIDs { try favorites.replaceAll(with: ids) }
                 },
                 holds: { [favorites] backup in
                     backup.favoriteParkIDs.map { (try? favorites.currentIDs()) == $0 } ?? true
                 }),
            Step(write: { [exerciseFavorites] backup in
                     if let ids = backup.favoriteExerciseIDs { try exerciseFavorites.replaceAll(with: ids) }
                 },
                 holds: { [exerciseFavorites] backup in
                     backup.favoriteExerciseIDs.map { (try? exerciseFavorites.currentIDs()) == $0 } ?? true
                 }),
            Step(write: { [journal] in try journal.replaceAll($0.workoutLog) },
                 holds: { [journal] backup in journal.loadFailure == nil && journal.entries == backup.workoutLog })
        ]
    }

    /// Writes `previous` back through `steps`, newest first. A step whose
    /// write fails still counts as restored when its store already holds the
    /// old data (an atomic write that failed changed nothing). Returns whether
    /// every store holds `previous` again.
    private func rollBack(_ steps: ArraySlice<Step>, to previous: TrainingBackup) -> Bool {
        var complete = true
        for step in steps.reversed() {
            do {
                try step.write(previous)
            } catch {
                guard !step.holds(previous) else { continue }
                logger.fault("Rollback after a failed import failed: \(String(describing: error), privacy: .public)")
                complete = false
            }
        }
        return complete
    }

    /// Brings the shared services up to the stores. Runs before the first
    /// suspension, so no screen renders the rewards the journal change queued
    /// in between.
    private func finish() async {
        progress.reloadPlacement()
        goals.reload()
        rewards.rebaseline()
        await planService.syncReminders()
    }
}
