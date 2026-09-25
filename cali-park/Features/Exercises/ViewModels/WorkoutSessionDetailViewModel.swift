import Foundation
import Observation

// MARK: - WorkoutSessionDetailViewModel
/// Drives the workout detail screen (and the post-finish summary): resolves one
/// `WorkoutSession` from the log by its identifier, so the screen always shows
/// what is actually saved, and deletes the whole workout on request.
@MainActor
@Observable
final class WorkoutSessionDetailViewModel {
    // MARK: State
    /// `nil` once the workout is gone (deleted here or elsewhere).
    private(set) var session: WorkoutSession?
    var errorMessage: String?
    /// Set after a successful delete so the screen can close itself.
    private(set) var didDelete = false

    // MARK: Dependencies
    private let sessionID: UUID
    private let store: WorkoutLogStoring

    // MARK: Init
    init(sessionID: UUID, store: WorkoutLogStoring) {
        self.sessionID = sessionID
        self.store = store
        reload()
    }

    // MARK: Intentions
    /// Re-reads the store in saved order, so exercises list the way they were
    /// added to the workout.
    func reload() {
        session = WorkoutSession.session(withID: sessionID, in: store.load())
    }

    /// Removes every entry of the workout. On failure the screen re-reads the
    /// store, so it never shows entries that are already gone.
    func delete() {
        guard let session else { return }
        do {
            for entry in session.entries {
                try store.delete(id: entry.id)
            }
            self.session = nil
            didDelete = true
        } catch {
            errorMessage = "Nie udało się usunąć treningu."
            reload()
        }
    }

    /// Resolves the catalog exercise a log entry points to.
    func exercise(for entry: WorkoutLogEntry) -> Exercise? {
        ExerciseCatalog.exercise(withID: entry.exerciseID)
    }
}
