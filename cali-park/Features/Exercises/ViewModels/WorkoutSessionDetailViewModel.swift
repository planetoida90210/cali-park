import Foundation
import Observation

// MARK: - WorkoutSessionDetailViewModel
/// Drives the workout detail screen (and the post-finish summary): resolves one
/// `WorkoutSession` from the journal by its identifier, so the screen always
/// shows what is actually saved, and deletes the whole workout on request.
@MainActor
@Observable
final class WorkoutSessionDetailViewModel {
    // MARK: State
    var errorMessage: String?
    /// Set after a successful delete so the screen can close itself.
    private(set) var didDelete = false
    /// Whether the current failure streak was already announced.
    @ObservationIgnored private var hasAlertedLoadError = false

    // MARK: Dependencies
    private let sessionID: UUID
    private let journal: TrainingJournal

    // MARK: Init
    init(sessionID: UUID, journal: TrainingJournal) {
        self.sessionID = sessionID
        self.journal = journal
        alertIfLoadFailed()
    }

    // MARK: Output
    /// The workout in saved order, so exercises list the way they were added;
    /// `nil` once it is gone (deleted here or elsewhere).
    var session: WorkoutSession? {
        WorkoutSession.session(withID: sessionID, in: journal.entries)
    }

    /// Whether the journal could not be read; the screen then keeps its
    /// previous state.
    var hasLoadError: Bool { journal.hasLoadFailure }

    // MARK: Intentions
    /// Retries a failed load and raises the alert once per failure streak.
    func reload() {
        journal.reloadIfFailed()
        alertIfLoadFailed()
    }

    /// Removes every entry of the workout in one write, so a failure never
    /// leaves half of it behind.
    func delete() {
        guard let session else { return }
        do {
            try journal.delete(ids: Set(session.entries.map(\.id)))
            didDelete = true
        } catch {
            errorMessage = TrainingJournal.deleteFailureMessage
        }
    }

    /// Resolves the catalog exercise a log entry points to.
    func exercise(for entry: WorkoutLogEntry) -> Exercise? {
        ExerciseCatalog.exercise(withID: entry.exerciseID)
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
