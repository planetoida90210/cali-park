import Foundation
import Observation

// MARK: - WorkoutHistoryViewModel
/// Drives the "Ostatnie treningi" list: the journal's entries (newest first),
/// quick-workout sessions grouped together, deletes on swipe, and failures
/// surfaced for an alert.
@MainActor
@Observable
final class WorkoutHistoryViewModel {
    // MARK: State
    var errorMessage: String?
    /// Whether the current failure streak was already announced.
    @ObservationIgnored private var hasAlertedLoadError = false

    // MARK: Dependencies
    private let journal: TrainingJournal

    // MARK: Init
    init(journal: TrainingJournal) {
        self.journal = journal
        alertIfLoadFailed()
    }

    // MARK: Output
    /// Every entry, newest first. After a failed load the list keeps what it
    /// showed before (nothing, on first load) instead of claiming the journal
    /// is empty.
    var entries: [WorkoutLogEntry] { journal.newestFirst }

    /// Whether the journal could not be read.
    var hasLoadError: Bool { journal.hasLoadFailure }

    // MARK: Intentions
    /// Retries a failed load and raises the alert once per failure streak.
    /// Call when the view appears.
    func reload() {
        journal.reloadIfFailed()
        alertIfLoadFailed()
    }

    func delete(_ entry: WorkoutLogEntry) {
        delete([entry])
    }

    /// Deletes the given rows in one write.
    func delete(_ doomed: [WorkoutLogEntry]) {
        do {
            try journal.delete(ids: Set(doomed.map(\.id)))
        } catch {
            errorMessage = TrainingJournal.deleteFailureMessage
        }
    }

    /// Detail screen for a workout tapped in the list.
    func makeDetailViewModel(sessionID: UUID) -> WorkoutSessionDetailViewModel {
        WorkoutSessionDetailViewModel(sessionID: sessionID, journal: journal)
    }

    /// Resolves the catalog exercise a log entry points to.
    func exercise(for entry: WorkoutLogEntry) -> Exercise? {
        ExerciseCatalog.exercise(withID: entry.exerciseID)
    }

    /// Entries grouped for display: exercises sharing a `sessionID` collapse
    /// into one workout, standalone logs stay on their own, all newest first.
    var sections: [WorkoutSession] {
        WorkoutSession.grouped(from: entries)
    }

    private func alertIfLoadFailed() {
        guard hasLoadError else {
            hasAlertedLoadError = false
            return
        }
        if !hasAlertedLoadError { errorMessage = StoreLoadFailure.message }
        hasAlertedLoadError = true
    }
}
