import Foundation
@testable import cali_park

// MARK: - StoreFixtures
/// Expected values of the golden fixture files in `Fixtures/`. The JSON files
/// were written by the pre-envelope stores (bare arrays/objects, ISO 8601
/// whole-second dates), so they pin the on-disk format existing installs have.
/// Never regenerate them: a change that breaks decoding them breaks real users.
enum StoreFixtures {
    // MARK: Identifiers
    static let pullUpsID = UUID(uuidString: "6F1C0B8E-2D44-4B1E-9C55-0A1B2C3D4E01")!
    static let plankID = UUID(uuidString: "6F1C0B8E-2D44-4B1E-9C55-0A1B2C3D4E02")!
    static let sessionID = UUID(uuidString: "6F1C0B8E-2D44-4B1E-9C55-0A1B2C3D4E03")!
    static let planID = UUID(uuidString: "6F1C0B8E-2D44-4B1E-9C55-0A1B2C3D4E04")!

    // MARK: Dates (whole seconds)
    /// 2026-10-01T07:30:00Z
    static let october1 = Date(timeIntervalSince1970: 1_790_839_800)
    /// 2026-10-02T18:05:10Z
    static let october2 = Date(timeIntervalSince1970: 1_790_964_310)

    // MARK: workout-log.json
    static let workoutLog: [WorkoutLogEntry] = [
        // The oldest shape: no note, sessionID, planID or durations.
        WorkoutLogEntry(
            id: UUID(uuidString: "A0000000-0000-4000-8000-000000000001")!,
            exerciseID: pullUpsID,
            date: october1,
            sets: [LoggedSet(reps: 8), LoggedSet(reps: 6)]
        ),
        // A quick-workout entry from a plan, with weight and a note.
        WorkoutLogEntry(
            id: UUID(uuidString: "A0000000-0000-4000-8000-000000000002")!,
            exerciseID: pullUpsID,
            date: october2,
            sets: [LoggedSet(reps: 5, weight: 10)],
            note: "Kamizelka 10 kg",
            sessionID: sessionID,
            planID: planID
        ),
        // A timed exercise.
        WorkoutLogEntry(
            id: UUID(uuidString: "A0000000-0000-4000-8000-000000000003")!,
            exerciseID: plankID,
            date: october2,
            sets: [LoggedSet(reps: 1, durationSeconds: 45)],
            sessionID: sessionID,
            planID: planID
        )
    ]

    // MARK: workout-plans.json
    static let workoutPlans: [WorkoutPlan] = [
        WorkoutPlan(
            id: planID,
            name: "Pull day",
            exercises: [
                PlannedExercise(id: UUID(uuidString: "B0000000-0000-4000-8000-000000000001")!,
                                exerciseID: pullUpsID, targetSets: 3, targetReps: 8),
                PlannedExercise(id: UUID(uuidString: "B0000000-0000-4000-8000-000000000002")!,
                                exerciseID: plankID)
            ],
            schedule: .weekly([.monday, .thursday]),
            createdAt: october1,
            reminderTime: DateComponents(hour: 18, minute: 30)
        ),
        WorkoutPlan(
            id: UUID(uuidString: "C0000000-0000-4000-8000-000000000001")!,
            name: "Co trzy dni",
            schedule: .everyNDays(3, from: october1),
            isActive: false,
            createdAt: october1
        ),
        WorkoutPlan(
            id: UUID(uuidString: "C0000000-0000-4000-8000-000000000002")!,
            name: "Jednorazowy",
            schedule: .once(october2),
            createdAt: october2
        ),
        WorkoutPlan(
            id: UUID(uuidString: "C0000000-0000-4000-8000-000000000003")!,
            name: "Bez daty",
            schedule: .once(nil),
            createdAt: october2
        )
    ]

    // MARK: skill-placement.json
    static let placement = SkillPlacement(
        declaredRungByPath: [.pullUp: 3, .pushUp: 5],
        ownedEquipment: ["Resistance bands"],
        declaredAt: october1
    )

    // MARK: skill-progress.json
    static let progress = SkillProgress(
        celebratedRungs: [
            RungReference(pathID: .pullUp, rungIndex: 3),
            RungReference(pathID: .dip, rungIndex: 1)
        ],
        celebratedLevel: 4
    )
}
