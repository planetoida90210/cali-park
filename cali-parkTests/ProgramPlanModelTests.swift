import Foundation
import Testing
@testable import cali_park

// Ticket 016: the optional program fields on `WorkoutPlan` and
// `PlannedExercise`. Old plan files (bare legacy arrays and envelope v1) must
// keep loading, and a plan with every new field must survive the file store.

private final class ProgramBundleToken {}

private enum PlanFileSupport {
    static func makeDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "ProgramPlanModelTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func jsonObject(at url: URL) throws -> Any {
        try JSONSerialization.jsonObject(with: Data(contentsOf: url))
    }

    /// A plan using every new field, with whole-second dates for the
    /// ISO 8601 roundtrip.
    static let programPlan = WorkoutPlan(
        id: UUID(uuidString: "D0000000-0000-4000-8000-000000000001")!,
        name: "Fundamenty",
        exercises: [
            PlannedExercise(id: UUID(uuidString: "D0000000-0000-4000-8000-000000000002")!,
                            exerciseID: ExerciseCatalog.negativePullUpsID,
                            targetSets: 3, targetReps: 5,
                            pathID: .pullUp, targetRepsMin: 3,
                            restSeconds: 90, group: 1),
            PlannedExercise(id: UUID(uuidString: "D0000000-0000-4000-8000-000000000003")!,
                            exerciseID: ExerciseCatalog.plankID,
                            targetSets: 3,
                            pathID: .core, targetSeconds: 30, targetSecondsMin: 10,
                            restSeconds: 90, group: 1),
            PlannedExercise(id: UUID(uuidString: "D0000000-0000-4000-8000-000000000004")!,
                            exerciseID: ExerciseCatalog.plankShoulderTapsID,
                            group: 2, rounds: 2...6, repsInReserve: 2),
            PlannedExercise(id: UUID(uuidString: "D0000000-0000-4000-8000-000000000005")!,
                            exerciseID: ExerciseCatalog.wallHandstandHoldID,
                            pathID: .handstand, holdRungsOnly: true, timeBoxMinutes: 10),
            PlannedExercise(id: UUID(uuidString: "D0000000-0000-4000-8000-000000000006")!,
                            exerciseID: ExerciseCatalog.lSitID,
                            pathID: .lSit, targetSeconds: 30, targetSecondsMin: 10, totalSeconds: 180)
        ],
        schedule: .weekly([.monday, .wednesday, .friday]),
        createdAt: ProgramFixtures.today,
        reminderTime: DateComponents(hour: 7, minute: 15),
        programID: ProgramID.fundamentals.rawValue,
        programVersion: 1
    )
}

@Suite("Plan model: optional program fields")
struct ProgramPlanModelTests {
    @Test
    func legacyFixtureLoadsWithoutProgramFields() throws {
        let directory = try PlanFileSupport.makeDirectory()
        let source = try #require(Bundle(for: ProgramBundleToken.self)
            .url(forResource: "workout-plans-legacy", withExtension: "json"))
        try FileManager.default.copyItem(at: source, to: directory.appending(path: "workout-plans.json"))

        let plans = try FileWorkoutPlanStore(directory: directory).load()

        #expect(plans == StoreFixtures.workoutPlans)
        #expect(plans.allSatisfy { $0.programID == nil && $0.programVersion == nil })
        let items = plans.flatMap(\.exercises)
        #expect(!items.isEmpty)
        #expect(items.allSatisfy { $0.pathID == nil && !$0.holdRungsOnly && $0.rounds == nil })
        #expect(items.allSatisfy { $0.targetRepsMin == nil && $0.targetSeconds == nil && $0.restSeconds == nil })
    }

    @Test
    func envelopeV1PlanFromBeforeProgramsLoads() throws {
        let directory = try PlanFileSupport.makeDirectory()
        let text = #"""
        {"schemaVersion":1,"payload":[{"id":"D0000000-0000-4000-8000-000000000010","name":"Stary plan","isActive":true,
        "createdAt":"2026-10-01T07:30:00Z","schedule":{"weekly":{"_0":[2]}},
        "exercises":[{"id":"D0000000-0000-4000-8000-000000000011","exerciseID":"E0000000-0000-4000-8000-000000000001","targetSets":3,"targetReps":8}]}]}
        """#
        try Data(text.utf8).write(to: directory.appending(path: "workout-plans.json"))

        let plans = try FileWorkoutPlanStore(directory: directory).load()

        let plan = try #require(plans.first)
        #expect(plan.name == "Stary plan")
        #expect(plan.programID == nil)
        #expect(plan.exercises == [PlannedExercise(id: UUID(uuidString: "D0000000-0000-4000-8000-000000000011")!,
                                                   exerciseID: ExerciseCatalog.pullUpsID,
                                                   targetSets: 3, targetReps: 8)])
    }

    @Test
    func planWithEveryProgramFieldRoundTripsThroughTheFileStore() throws {
        let directory = try PlanFileSupport.makeDirectory()
        let store = FileWorkoutPlanStore(directory: directory)

        try store.save(PlanFileSupport.programPlan)

        #expect(try store.load() == [PlanFileSupport.programPlan])
        let object = try #require(PlanFileSupport.jsonObject(at: directory.appending(path: "workout-plans.json")) as? [String: Any])
        // The new fields are additive, so the envelope version stays 1.
        #expect(object["schemaVersion"] as? Int == 1)
    }

    @Test
    func planWithoutProgramDataWritesNoNewKeys() throws {
        let plan = WorkoutPlan(name: "Ręczny",
                               exercises: [PlannedExercise(exerciseID: ExerciseCatalog.pushUpsID, targetSets: 3, targetReps: 10)],
                               schedule: .weekly([.monday]),
                               createdAt: ProgramFixtures.today)

        let data = try JSONEncoder().encode(plan)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let item = try #require((object["exercises"] as? [[String: Any]])?.first)

        #expect(object["programID"] == nil)
        #expect(object["programVersion"] == nil)
        #expect(Set(item.keys) == ["id", "exerciseID", "targetSets", "targetReps"])
    }

    @Test
    func unknownLadderOrBrokenRangeDropsOnlyThatField() throws {
        let text = #"""
        {"id":"D0000000-0000-4000-8000-000000000020","exerciseID":"E0000000-0000-4000-8000-000000000001",
         "pathID":"ladderFromTheFuture","rounds":[6,2],"restSeconds":90}
        """#

        let item = try JSONDecoder().decode(PlannedExercise.self, from: Data(text.utf8))

        #expect(item.exerciseID == ExerciseCatalog.pullUpsID)
        #expect(item.pathID == nil)
        #expect(item.rounds == nil)
        #expect(item.restSeconds == 90)
    }
}
