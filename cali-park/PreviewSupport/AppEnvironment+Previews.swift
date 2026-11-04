#if DEBUG
import CoreLocation
import Foundation

// Preview and test support, compiled into Debug builds only: the unit tests
// reach it through `@testable import` of a Debug build, and every `#Preview`
// that uses it sits inside `#if DEBUG` too.

// MARK: - Throwaway defaults
extension UserDefaults {
    /// A fresh, empty suite with a unique name, for previews and tests. It
    /// writes nothing to disk until something is set in it.
    static func throwaway() -> UserDefaults {
        let name = "cali-park.throwaway.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: name) else {
            // Only the app's own bundle ID and the global domain are refused.
            preconditionFailure("UserDefaults refused the suite \(name)")
        }
        return defaults
    }
}

// MARK: - Seeded preview environments
extension AppEnvironment {
    /// A preview environment backed by in-memory stores seeded with the given
    /// logs and plans, so the whole `HomeView` can be eyeballed in each hero
    /// state without touching disk. Parks are the real bundled snapshot; the
    /// location is a fixed point (central Warsaw) so previews never prompt.
    /// Home module preferences live in a throwaway `UserDefaults` suite, so
    /// previews and tests never read or change the real ones.
    static func seeded(logs: [WorkoutLogEntry] = [],
                       plans: [WorkoutPlan] = [],
                       placement: SkillPlacement? = nil,
                       weeklyGoal: WeeklyGoalHistory? = nil,
                       favoriteParks: [UUID] = [],
                       favoriteExercises: [UUID] = [],
                       diagnosticReports: [DiagnosticReport] = [],
                       location: LocationProviding? = nil) -> AppEnvironment {
        AppEnvironment(
            parkDirectory: BundledParkDirectory(),
            locationProvider: location ?? FixedLocationProvider(
                authorization: .authorized,
                location: CLLocationCoordinate2D(latitude: 52.2297, longitude: 21.0122)
            ),
            favoriteParkStore: InMemoryFavoriteParkStore(initial: favoriteParks),
            favoriteExerciseStore: InMemoryFavoriteExerciseStore(initial: favoriteExercises),
            workoutLogStore: InMemoryWorkoutLogStore(initial: logs),
            workoutPlanStore: InMemoryWorkoutPlanStore(initial: plans),
            reminderScheduler: InMemoryReminderScheduler(status: .authorized),
            reminderRefreshScheduler: InMemoryReminderRefreshScheduler(),
            placementStore: InMemorySkillPlacementStore(initial: placement),
            skillProgressStore: InMemorySkillProgressStore(),
            weeklyGoalStore: InMemoryWeeklyGoalStore(initial: weeklyGoal),
            diagnostics: DiagnosticsService(store: InMemoryDiagnosticReportStore(initial: diagnosticReports)),
            defaults: .throwaway()
        )
    }

    /// Plan scheduled for today, nothing logged yet → hero shows "Rozpocznij".
    static var previewPlanToday: AppEnvironment {
        seeded(plans: [
            WorkoutPlan(
                name: "Push Day",
                exercises: [
                    PlannedExercise(exerciseID: ExerciseCatalog.pushUpsID, targetSets: 3, targetReps: 12),
                    PlannedExercise(exerciseID: ExerciseCatalog.dipsID, targetSets: 3, targetReps: 10)
                ],
                schedule: .once(CalendarDay(.now, in: .current))
            )
        ])
    }

    /// A whole session logged today → hero shows the day's summary.
    static var previewCompletedToday: AppEnvironment {
        let session = UUID()
        return seeded(logs: [
            WorkoutLogEntry(
                exerciseID: ExerciseCatalog.pullUpsID,
                sets: [LoggedSet(reps: 8), LoggedSet(reps: 6)],
                sessionID: session
            ),
            WorkoutLogEntry(
                exerciseID: ExerciseCatalog.dipsID,
                sets: [LoggedSet(reps: 12)],
                sessionID: session
            )
        ])
    }

    /// No plans and an empty journal → hero invites the first workout.
    static var previewEmpty: AppEnvironment { seeded() }

    /// "Diagnostyka" with the sample MetricKit reports.
    static var previewDiagnostics: AppEnvironment {
        seeded(diagnosticReports: DiagnosticPreviewData.reports)
    }

    /// A seasoned athlete for the Skills tab: several dynamic ladders finished
    /// through logs, plus a mid-ladder static (front lever conquered through the
    /// advanced tuck). Exercises the conquered / current / future rung states.
    static var skillsVeteran: AppEnvironment {
        func timed(_ id: UUID, seconds: Int, holds: Int = 3) -> WorkoutLogEntry {
            WorkoutLogEntry(exerciseID: id, sets: Array(repeating: LoggedSet(reps: 1, durationSeconds: seconds), count: holds))
        }
        func reps(_ id: UUID, reps: Int, sets: Int = 3) -> WorkoutLogEntry {
            WorkoutLogEntry(exerciseID: id, sets: Array(repeating: LoggedSet(reps: reps), count: sets))
        }
        return seeded(
            logs: [
                reps(ExerciseCatalog.archerPullUpsID, reps: 5),
                reps(ExerciseCatalog.pseudoPlanchePushUpsID, reps: 8),
                reps(ExerciseCatalog.ringDipsID, reps: 8),
                timed(ExerciseCatalog.tuckFrontLeverID, seconds: 20),
                timed(ExerciseCatalog.advancedTuckFrontLeverID, seconds: 20),
                timed(ExerciseCatalog.straddleFrontLeverID, seconds: 12)
            ],
            placement: SkillPlacement(declaredRungByPath: [.core: 2, .legs: 3])
        )
    }
}
#endif
