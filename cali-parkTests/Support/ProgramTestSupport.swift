import Foundation

@testable import cali_park

// MARK: - ProgramFixtures
/// Deterministic inputs for the program tests: a gregorian UTC calendar, a
/// fixed whole-second "today", and ladder states built from placements the
/// onboarding level test can produce.
enum ProgramFixtures {
    static let calendar = TestCalendar.utc

    /// 2026-11-04T12:00:00Z, a Wednesday.
    static let today = TestDate.reference

    /// Nothing declared, nothing logged: every ladder at its first rung.
    static let newcomer: [ProgressionPathID: PathState] = states()

    /// The level test answered "0" for pull-ups, push-ups, dips and squats.
    static let zeroPullUps: [ProgressionPathID: PathState] = states(
        placement: PlacementCalibration.placement(
            repAnswers: [.pullUp: .none, .pushUp: .none, .dip: .none, .legs: .none],
            masteredSkills: [],
            ownsBand: false,
            declaredAt: today
        ))

    /// The level test answered "12+" everywhere and checked the full L-sit,
    /// and the athlete trains pike push-ups on the handstand ladder.
    static let advancedPlacement = SkillPlacement(
        declaredStepByPath: PlacementCalibration.placement(
            repAnswers: [.pullUp: .many, .pushUp: .many, .dip: .many, .legs: .many],
            masteredSkills: ["fullLSit"],
            ownsBand: false,
            declaredAt: today
        ).declaredStepByPath.merging([.handstand: ExerciseCatalog.pikePushUpsID]) { $1 },
        declaredAt: today
    )
    static let advanced: [ProgressionPathID: PathState] = states(placement: advancedPlacement)

    static func states(
        placement: SkillPlacement? = nil,
        logs: [WorkoutLogEntry] = []
    ) -> [ProgressionPathID: PathState] {
        ProgressionEngine.pathStates(logs: logs, placement: placement)
    }

    /// A session of `sets` × `reps` on one exercise, on `date`.
    static func reps(_ exerciseID: UUID, _ reps: Int, sets: Int = 3, on date: Date = today) -> WorkoutLogEntry {
        WorkoutLogEntry(
            exerciseID: exerciseID, date: date,
            sets: Array(repeating: LoggedSet(reps: reps), count: sets))
    }

    /// A session of `sets` holds of `seconds` on one exercise, on `date`.
    static func hold(_ exerciseID: UUID, _ seconds: Int, sets: Int = 3, on date: Date = today) -> WorkoutLogEntry {
        WorkoutLogEntry(
            exerciseID: exerciseID, date: date,
            sets: Array(repeating: LoggedSet(value: seconds, measurement: .seconds), count: sets))
    }
}

// MARK: - Broken stores
/// A plan store that reads fine but refuses every write.
final class ReadOnlyPlanStore: WorkoutPlanStoring {
    struct WriteError: Error {}
    func load() throws -> [WorkoutPlan] { [] }
    func save(_ plan: WorkoutPlan) throws { throw WriteError() }
    func delete(id: UUID) throws { throw WriteError() }
}
