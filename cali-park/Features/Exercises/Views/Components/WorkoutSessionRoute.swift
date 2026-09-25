import Foundation

// MARK: - WorkoutSessionRoute
/// Value-based navigation token for the workout detail screen, pushed from the
/// Home "Ostatni trening" card and the history list.
struct WorkoutSessionRoute: Hashable {
    let sessionID: UUID
}
