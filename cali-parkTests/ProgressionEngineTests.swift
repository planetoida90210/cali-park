//
//  ProgressionEngineTests.swift
//  cali-parkTests
//
//  Sprint SK3 — the progression engine and its stores: path state from logs and
//  declarations (max of the two, paths independent), XP/levels backward from
//  history, badges from logs only, and store roundtrips. Pure and deterministic:
//  a fixed UTC calendar drives the streak-based badges.
//

import Foundation
import Testing
@testable import cali_park

// MARK: - Fixtures

private enum Fixture {
    /// A rep entry for `exerciseID` with the given rep counts, one set each.
    static func reps(_ exerciseID: UUID, _ counts: Int..., date: Date = .now, session: UUID? = nil) -> WorkoutLogEntry {
        WorkoutLogEntry(
            exerciseID: exerciseID,
            date: date,
            sets: counts.map { LoggedSet(value: $0, measurement: .reps) },
            sessionID: session
        )
    }

    /// A timed-hold entry for `exerciseID` with the given second counts.
    static func holds(_ exerciseID: UUID, _ counts: Int..., date: Date = .now) -> WorkoutLogEntry {
        WorkoutLogEntry(
            exerciseID: exerciseID,
            date: date,
            sets: counts.map { LoggedSet(value: $0, measurement: .seconds) }
        )
    }

    static func pullUpState(logs: [WorkoutLogEntry], placement: SkillPlacement? = nil) -> PathState {
        ProgressionEngine.pathState(
            for: ProgressionCatalog.path(withID: .pullUp)!,
            logs: logs,
            placement: placement
        )
    }
}

// MARK: - Path state from logs

struct ProgressionEnginePathStateTests {
    // Pull-up ladder indices: 0 dead hang, 1 scapular, 2 negatives,
    // 3 band (parallel), 4 full pull-ups, 5 L-pull-ups, 6 archer.

    @Test
    func threeByEightInOneSessionConquersThroughFullPullUps() {
        let state = Fixture.pullUpState(logs: [Fixture.reps(ExerciseCatalog.pullUpsID, 8, 8, 8)])
        // Rungs 0...4 conquered; now training L-pull-ups (index 5).
        #expect(state.conqueredRungCount == 5)
        #expect(state.currentRungIndex == 5)
        #expect(state.isConquered(rungAt: 4))
        #expect(!state.isConquered(rungAt: 5))
        #expect(!state.isComplete)
    }

    @Test
    func sameVolumeSplitAcrossSessionsDoesNotAdvance() {
        // Three separate single-set sessions of 8 — never "3 × 8 in one session".
        let logs = [
            Fixture.reps(ExerciseCatalog.pullUpsID, 8, session: UUID()),
            Fixture.reps(ExerciseCatalog.pullUpsID, 8, session: UUID()),
            Fixture.reps(ExerciseCatalog.pullUpsID, 8, session: UUID())
        ]
        let state = Fixture.pullUpState(logs: logs)
        #expect(state.conqueredRungCount == 0)
        #expect(state.currentRungIndex == 0)
    }

    @Test
    func currentRungProgressReportsBestWeakestSet() {
        // Placement puts the athlete on full pull-ups (index 4); a near-miss
        // session (8, 6, 7) reports the weakest of the best 3 sets as progress.
        let placement = SkillPlacement(declaredRungByPath: [.pullUp: 4])
        let state = Fixture.pullUpState(logs: [Fixture.reps(ExerciseCatalog.pullUpsID, 8, 6, 7)], placement: placement)
        // Not met (6 < 8), so full pull-ups (index 4) is still current.
        #expect(state.currentRungIndex == 4)
        #expect(state.currentProgress.bestValue == 6)
        #expect(state.currentProgress.targetValue == 8)
        #expect(!state.currentProgress.isMet)
    }

    @Test
    func fewerSetsThanRequiredScoresZeroProgress() {
        // Only two sets logged for a 3-set criterion → no qualifying session.
        let placement = SkillPlacement(declaredRungByPath: [.pullUp: 4])
        let state = Fixture.pullUpState(logs: [Fixture.reps(ExerciseCatalog.pullUpsID, 12, 12)], placement: placement)
        #expect(state.currentRungIndex == 4)
        #expect(state.currentProgress.bestValue == 0)
    }

    @Test
    func timedHoldCriterionNeedsTheFullDuration() {
        let path = ProgressionCatalog.path(withID: .frontLever)!
        // Tuck front lever (index 0) asks for 3 × 20 s.
        let short = ProgressionEngine.pathState(
            for: path,
            logs: [Fixture.holds(ExerciseCatalog.tuckFrontLeverID, 15, 15, 15)],
            placement: nil
        )
        #expect(short.conqueredRungCount == 0)
        #expect(short.currentProgress.bestValue == 15)
        #expect(!short.currentProgress.isMet)

        let met = ProgressionEngine.pathState(
            for: path,
            logs: [Fixture.holds(ExerciseCatalog.tuckFrontLeverID, 20, 20, 20)],
            placement: nil
        )
        #expect(met.conqueredRungCount == 1)
        #expect(met.currentRungIndex == 1)
    }

    @Test
    func topRungConqueredMarksPathComplete() {
        let path = ProgressionCatalog.path(withID: .handstand)!
        // Handstand top rung (index 2) is wall HSPU, 3 × 5 reps.
        let state = ProgressionEngine.pathState(
            for: path,
            logs: [Fixture.reps(ExerciseCatalog.wallHandstandPushUpsID, 5, 5, 5)],
            placement: nil
        )
        #expect(state.conqueredRungCount == path.steps.count)
        #expect(state.isComplete)
        // Stays on the top rung once complete, never runs off the end.
        #expect(state.currentRungIndex == path.steps.count - 1)
    }
}

// MARK: - Placement + logs combine as max

struct ProgressionEnginePlacementTests {
    @Test
    func declarationSetsStartingRungWithoutLogs() {
        // Declare archer (index 6) as the current rung.
        let placement = SkillPlacement(declaredRungByPath: [.pullUp: 6])
        let state = Fixture.pullUpState(logs: [], placement: placement)
        #expect(state.currentRungIndex == 6)
        #expect(state.conqueredRungCount == 6)
        #expect(state.isConquered(rungAt: 5))
        #expect(!state.isConquered(rungAt: 6))
    }

    @Test
    func logsWinWhenTheyExceedTheDeclaration() {
        // Declare negatives (index 2) but log full pull-ups (conquers through 4).
        let placement = SkillPlacement(declaredRungByPath: [.pullUp: 2])
        let state = Fixture.pullUpState(
            logs: [Fixture.reps(ExerciseCatalog.pullUpsID, 8, 8, 8)],
            placement: placement
        )
        #expect(state.conqueredRungCount == 5)
        #expect(state.currentRungIndex == 5)
    }

    @Test
    func declarationWinsWhenItExceedsTheLogs() {
        // Declare archer (index 6); logs only reach full pull-ups (index 4).
        let placement = SkillPlacement(declaredRungByPath: [.pullUp: 6])
        let state = Fixture.pullUpState(
            logs: [Fixture.reps(ExerciseCatalog.pullUpsID, 8, 8, 8)],
            placement: placement
        )
        #expect(state.currentRungIndex == 6)
        #expect(state.conqueredRungCount == 6)
    }

    @Test
    func pathsAreScoredIndependently() throws {
        // The "70 pull-ups, no muscle-up" case: strong pulling never touches the
        // muscle-up ladder, which uses different exercises.
        let logs = [
            Fixture.reps(ExerciseCatalog.pullUpsID, 20, 20, 20),
            Fixture.reps(ExerciseCatalog.archerPullUpsID, 5, 5, 5)
        ]
        let states = ProgressionEngine.pathStates(logs: logs, placement: nil)
        let muscleUp = try #require(states[.muscleUp])
        #expect(muscleUp.conqueredRungCount == 0)
        #expect(muscleUp.currentRungIndex == 0)
        // Pull-up path, meanwhile, is fully conquered.
        let pullUp = try #require(states[.pullUp])
        #expect(pullUp.isComplete)
    }

    @Test
    func everyPathHasAState() {
        let states = ProgressionEngine.pathStates(logs: [], placement: nil)
        #expect(Set(states.keys) == Set(ProgressionPathID.allCases))
    }
}

// MARK: - Experience & level

struct ProgressionEngineExperienceTests {
    @Test
    func emptyHistoryEarnsNoXP() {
        #expect(ProgressionEngine.experiencePoints(for: []) == 0)
    }

    @Test
    func declarationsNeverGrantXP() {
        // Placement is not an input to XP at all — no logs means no XP, whatever
        // the athlete declares.
        let placement = SkillPlacement(declaredRungByPath: [.pullUp: 6])
        let state = Fixture.pullUpState(logs: [], placement: placement)
        #expect(state.currentRungIndex == 6)                 // declaration applied…
        #expect(ProgressionEngine.experiencePoints(for: []) == 0) // …but zero XP.
    }

    @Test
    func xpCountsVolumePlusConqueredRungs() {
        // 3 × 8 pull-ups = 24 reps × 10 = 240 XP volume.
        // Conquers through rung 4 → 5 rungs × 100 = 500 XP bonus. Total 740.
        let xp = ProgressionEngine.experiencePoints(for: [Fixture.reps(ExerciseCatalog.pullUpsID, 8, 8, 8)])
        #expect(xp == 740)
    }

    @Test
    func timedVolumeContributesXP() {
        // 3 × 20 s = 60 s × 1 = 60 XP volume + 1 conquered rung × 100 = 160.
        let xp = ProgressionEngine.experiencePoints(for: [Fixture.holds(ExerciseCatalog.tuckFrontLeverID, 20, 20, 20)])
        #expect(xp == 160)
    }

    @Test(arguments: [
        (0, 1),        // start of level 1
        (499, 1),      // just below level 2
        (500, 2),      // threshold for level 2
        (1999, 2),
        (2000, 3),     // threshold for level 3
        (4500, 4)      // threshold for level 4
    ])
    func levelThresholds(xp: Int, expectedLevel: Int) {
        #expect(PlayerLevel.forXP(xp).level == expectedLevel)
    }

    @Test
    func levelExposesProgressWithinTheBand() {
        let level = PlayerLevel.forXP(1250) // level 2: [500, 2000)
        #expect(level.level == 2)
        #expect(level.xpAtLevelStart == 500)
        #expect(level.xpAtNextLevel == 2000)
        #expect(level.xpIntoLevel == 750)
        #expect(level.xpToNextLevel == 750)
        #expect(abs(level.progressToNextLevel - 0.5) < 0.0001)
    }
}

// MARK: - Badges

struct ProgressionEngineBadgeTests {
    /// Fixed UTC clock so streak-based badges never depend on run time.
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private static let today = Date(timeIntervalSince1970: 200 * 86_400 + 12 * 3_600)

    private static func daysAgo(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: -offset, to: today)!
    }

    private func earned(_ logs: [WorkoutLogEntry]) -> Set<Badge> {
        ProgressionEngine.earnedBadges(from: logs, calendar: Self.calendar, today: Self.today)
    }

    @Test
    func emptyHistoryEarnsNothing() {
        #expect(earned([]).isEmpty)
    }

    @Test
    func anyWorkoutEarnsFirstWorkout() {
        let badges = earned([Fixture.reps(ExerciseCatalog.pullUpsID, 3, date: Self.today)])
        #expect(badges.contains(.firstWorkout))
        #expect(!badges.contains(.tenTrainingDays))
        #expect(!badges.contains(.firstSkill))
    }

    @Test
    func tenDistinctDaysEarnRegularity() {
        let logs = (0..<10).map { Fixture.reps(ExerciseCatalog.pullUpsID, 3, date: Self.daysAgo($0)) }
        #expect(earned(logs).contains(.tenTrainingDays))
    }

    @Test
    func sevenConsecutiveDaysEarnWeekStreak() {
        let logs = (0..<7).map { Fixture.reps(ExerciseCatalog.pushUpsID, 5, date: Self.daysAgo($0)) }
        #expect(earned(logs).contains(.weekStreak))
    }

    @Test
    func completingAPathEarnsFirstSkill() {
        let logs = [Fixture.reps(ExerciseCatalog.wallHandstandPushUpsID, 5, 5, 5, date: Self.today)]
        #expect(earned(logs).contains(.firstSkill))
    }

    @Test
    func aThousandRepsEarnsTheVolumeBadge() {
        // One session of 10 × 100 reps.
        let entry = WorkoutLogEntry(
            exerciseID: ExerciseCatalog.squatsID,
            date: Self.today,
            sets: Array(repeating: LoggedSet(value: 100, measurement: .reps), count: 10)
        )
        #expect(earned([entry]).contains(.thousandReps))
    }
}

// MARK: - Placement store

struct SkillPlacementStoreTests {
    @Test
    func placementRoundtripsThroughJSON() throws {
        let placement = SkillPlacement(
            declaredRungByPath: [.pullUp: 4, .frontLever: 1],
            ownedEquipment: ["Resistance bands"],
            declaredAt: Date(timeIntervalSince1970: 1_000)
        )
        let data = try JSONEncoder().encode(placement)
        let decoded = try JSONDecoder().decode(SkillPlacement.self, from: data)
        #expect(decoded == placement)
        #expect(decoded.declaredRung(for: .pullUp) == 4)
        #expect(decoded.ownsEquipment("Resistance bands"))
    }

    @Test
    func inMemoryStoreSavesAndLoads() throws {
        let store = InMemorySkillPlacementStore()
        #expect(store.load() == nil)
        let placement = SkillPlacement(declaredRungByPath: [.dip: 2])
        try store.save(placement)
        #expect(store.load() == placement)
    }

    @Test
    func fileStoreRoundtripsAndReportsAbsence() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = FileSkillPlacementStore(directory: directory)
        #expect(store.load() == nil)

        let placement = SkillPlacement(declaredRungByPath: [.core: 1], ownedEquipment: ["Pull-up bar"])
        try store.save(placement)
        #expect(store.load() == placement)
    }
}

// MARK: - Skill-progress store

struct SkillProgressStoreTests {
    @Test
    func progressRoundtripsThroughJSON() throws {
        let progress = SkillProgress(
            celebratedRungs: [
                RungReference(pathID: .pullUp, rungIndex: 4),
                RungReference(pathID: .dip, rungIndex: 2)
            ],
            celebratedLevel: 3
        )
        let data = try JSONEncoder().encode(progress)
        let decoded = try JSONDecoder().decode(SkillProgress.self, from: data)
        #expect(decoded == progress)
        #expect(decoded.hasCelebrated(RungReference(pathID: .pullUp, rungIndex: 4)))
        #expect(!decoded.hasCelebrated(RungReference(pathID: .pullUp, rungIndex: 5)))
    }

    @Test
    func fileStoreRoundtripsAndReportsAbsence() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = FileSkillProgressStore(directory: directory)
        #expect(store.load() == nil)

        let progress = SkillProgress(celebratedRungs: [RungReference(pathID: .planche, rungIndex: 1)], celebratedLevel: 2)
        try store.save(progress)
        #expect(store.load() == progress)
    }
}
