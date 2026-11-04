import Foundation
import Testing
@testable import cali_park

// MARK: - Fixtures
private enum F {
    static let calendar = TestCalendar.utc

    /// Epoch day 10, 1970-01-11, a Sunday.
    static let today = 10

    static func day(_ n: Int, hour: Int = 9, minute: Int = 0) -> Date {
        Date(timeIntervalSince1970: Double(n) * 86_400 + Double(hour) * 3_600 + Double(minute) * 60)
    }

    static func entry(_ exerciseID: UUID = ExerciseCatalog.pullUpsID,
                      at date: Date,
                      reps: [Int] = [8, 8, 8],
                      session: UUID? = nil,
                      plan: UUID? = nil) -> WorkoutLogEntry {
        WorkoutLogEntry(exerciseID: exerciseID, date: date, sets: reps.map { LoggedSet(reps: $0) },
                        sessionID: session, planID: plan)
    }

    static func hold(at date: Date, seconds: Int) -> WorkoutLogEntry {
        WorkoutLogEntry(exerciseID: ExerciseCatalog.plankID, date: date,
                        sets: [LoggedSet(reps: 1, durationSeconds: seconds)])
    }

    static func plan(_ name: String, _ schedule: WorkoutSchedule, createdDay: Int = 0) -> WorkoutPlan {
        WorkoutPlan(name: name,
                    exercises: [PlannedExercise(exerciseID: ExerciseCatalog.pushUpsID, targetSets: 3, targetReps: 10)],
                    schedule: schedule,
                    createdAt: day(createdDay))
    }

    static func newestFirst(_ entries: [WorkoutLogEntry]) -> [WorkoutLogEntry] {
        entries.sorted { $0.date > $1.date }
    }
}

// MARK: - Scenarios
/// Journals and plans covering every hero branch and module state.
private struct Scenario: CustomTestStringConvertible {
    let name: String
    let entries: [WorkoutLogEntry]
    let plans: [WorkoutPlan]

    var testDescription: String { name }

    static let all: [Scenario] = {
        let morningSession = UUID()
        let oldSession = UUID()
        let sunday = F.plan("Niedziela", .weekly([.sunday]))
        let alsoSunday = F.plan("Też niedziela", .weekly([.sunday]), createdDay: 1)
        let wednesday = F.plan("Środa", .weekly([.wednesday]))
        let pastOnce = F.plan("Raz", .once(F.day(5), in: F.calendar))
        let history = [
            F.entry(at: F.day(6), session: oldSession),
            F.entry(ExerciseCatalog.dipsID, at: F.day(6, minute: 10), session: oldSession),
            F.entry(ExerciseCatalog.squatsID, at: F.day(8)),
            F.entry(at: F.day(9, hour: 18))
        ]
        let sameInstant = F.day(9, hour: 20)
        return [
            Scenario(name: "empty", entries: [], plans: []),
            Scenario(name: "history, no plans", entries: history, plans: []),
            Scenario(name: "free workout today", entries: history + [
                F.entry(at: F.day(F.today, hour: 7), session: morningSession),
                F.entry(ExerciseCatalog.pushUpsID, at: F.day(F.today, hour: 7, minute: 20), session: morningSession),
                F.hold(at: F.day(F.today, hour: 6), seconds: 40)
            ], plans: []),
            Scenario(name: "plan due, a free log today", entries: history + [
                F.entry(at: F.day(F.today, hour: 7), reps: [5, 5]),
                F.hold(at: F.day(F.today, hour: 8), seconds: 30)
            ], plans: [sunday, wednesday]),
            Scenario(name: "plan due, nothing yet", entries: history, plans: [sunday]),
            Scenario(name: "plan done today", entries: history + [
                F.entry(ExerciseCatalog.pushUpsID, at: F.day(F.today, hour: 7), plan: sunday.id)
            ], plans: [sunday, wednesday]),
            Scenario(name: "two plans due, one done", entries: history + [
                F.entry(ExerciseCatalog.pushUpsID, at: F.day(F.today, hour: 7), plan: sunday.id)
            ], plans: [sunday, alsoSunday]),
            Scenario(name: "rest day", entries: history, plans: [wednesday]),
            Scenario(name: "rest day, empty journal", entries: [], plans: [wednesday]),
            Scenario(name: "only a past one-off plan", entries: history, plans: [pastOnce]),
            Scenario(name: "two workouts at the same instant", entries: [
                F.entry(at: sameInstant),
                F.entry(ExerciseCatalog.dipsID, at: sameInstant)
            ], plans: [])
        ]
    }()

    var progress: ProgressSnapshot {
        ProgressionEngine.snapshot(logs: entries, placement: nil, calendar: F.calendar, today: F.day(F.today))
    }
}

// MARK: - Legacy oracle
/// Home's derivations as `HomeDashboardViewModel` computed them on every
/// render before `HomeSnapshot` (B-14), copied unchanged except for taking
/// its inputs as parameters. The snapshot must give the same answers.
private enum LegacyHome {
    static func latestWorkout(_ entries: [WorkoutLogEntry]) -> WorkoutSession? {
        WorkoutSession.latest(in: entries)
    }

    static func streak(_ entries: [WorkoutLogEntry], _ reference: Date) -> WorkoutStreak {
        WorkoutStreak.compute(from: entries.map(\.date), calendar: F.calendar, today: reference)
    }

    static func suggestedExercise(_ entries: [WorkoutLogEntry]) -> Exercise? {
        guard !entries.isEmpty else { return nil }
        var lastTrained: [MuscleGroup: Date] = [:]
        for entry in entries {
            guard let exercise = ExerciseCatalog.exercise(withID: entry.exerciseID) else { continue }
            for group in exercise.muscleGroups {
                lastTrained[group] = max(lastTrained[group] ?? .distantPast, entry.date)
            }
        }
        let staleGroups = MuscleGroup.allCases.sorted {
            (lastTrained[$0] ?? .distantPast) < (lastTrained[$1] ?? .distantPast)
        }
        for group in staleGroups {
            if let match = ExerciseCatalog.all.first(where: { $0.category == .basic && $0.muscleGroups.first == group }) {
                return match
            }
            if let match = ExerciseCatalog.all.first(where: { $0.category == .basic && $0.muscleGroups.contains(group) }) {
                return match
            }
        }
        return nil
    }

    static func nextWorkoutState(_ entries: [WorkoutLogEntry], _ plans: [WorkoutPlan], _ reference: Date) -> NextWorkoutState {
        let today = PlanAgenda.day(reference, plans: plans, entries: entries, calendar: F.calendar)
        let next = PlanAgenda.nextUndone(plans: plans, entries: entries, calendar: F.calendar, today: reference)
        if today.isAllDone { return .doneToday(plans: today.due, next: next) }
        if let next { return .planned(next) }
        if let suggestion = suggestedExercise(entries) { return .suggestion(suggestion) }
        return .empty
    }

    static func heroState(_ entries: [WorkoutLogEntry], _ plans: [WorkoutPlan], _ reference: Date) -> HomeHeroState {
        let calendar = F.calendar
        let entriesToday = entries.filter { calendar.isDate($0.date, inSameDayAs: reference) }
        if let planToday = PlanAgenda.day(reference, plans: plans, entries: entries, calendar: calendar).undone.first {
            return .planToday(plan: planToday,
                              loggedTodayReps: entriesToday.reduce(0) { $0 + $1.totalReps },
                              loggedTodaySeconds: entriesToday.reduce(0) { $0 + $1.totalSeconds })
        }
        if !entriesToday.isEmpty {
            guard let lastWorkout = latestWorkout(entries) else { return .firstRun }
            return .completedToday(summary: lastWorkout, streak: streak(entries, reference))
        }
        if let planned = PlanAgenda.nextUndone(plans: plans, entries: entries, calendar: calendar, today: reference) {
            return .restDay(nextPlan: planned.plan, date: planned.date, streak: streak(entries, reference))
        }
        if let lastWorkout = latestWorkout(entries) {
            return .freeMode(lastWorkout: lastWorkout, suggestion: suggestedExercise(entries), streak: streak(entries, reference))
        }
        return .firstRun
    }

    static func achievements(_ snapshot: ProgressSnapshot) -> HomeAchievementsSummary {
        let advancement = snapshot.lastAdvancement.flatMap { reference -> HomeAchievementsSummary.Advancement? in
            guard let path = ProgressionCatalog.path(withID: reference.pathID),
                  let step = reference.step,
                  let exercise = ExerciseCatalog.exercise(withID: step.exerciseID)
            else { return nil }
            return HomeAchievementsSummary.Advancement(title: exercise.name, pathName: path.name, symbolName: path.symbolName)
        }
        return HomeAchievementsSummary(level: snapshot.level.level,
                                       xpToNextLevel: snapshot.level.xpToNextLevel,
                                       progressToNextLevel: snapshot.level.progressToNextLevel,
                                       earnedBadgeCount: snapshot.badges.count,
                                       totalBadgeCount: Badge.allCases.count,
                                       lastAdvancement: advancement)
    }
}

// MARK: - HomeEngine matches the old per-render answers
@Suite("HomeSnapshot equals Home's per-render derivations")
struct HomeSnapshotEquivalenceTests {
    /// Start, middle and last second of the day: only the day matters.
    static let instants = [F.day(F.today, hour: 0), F.day(F.today, hour: 12, minute: 30),
                           Date(timeIntervalSince1970: Double(F.today + 1) * 86_400 - 1)]

    @Test(arguments: Scenario.all)
    fileprivate func snapshotMatchesTheLegacyDerivations(_ scenario: Scenario) {
        let entries = F.newestFirst(scenario.entries)
        let progress = scenario.progress
        for instant in Self.instants {
            let snapshot = HomeEngine.snapshot(entries: entries, plans: scenario.plans, progress: progress,
                                               calendar: F.calendar, today: instant)

            #expect(snapshot.hero == LegacyHome.heroState(entries, scenario.plans, instant))
            #expect(snapshot.nextWorkout == LegacyHome.nextWorkoutState(entries, scenario.plans, instant))
            #expect(snapshot.latestWorkout == LegacyHome.latestWorkout(entries))
            #expect(snapshot.streak == LegacyHome.streak(entries, instant))
            #expect(snapshot.achievements == LegacyHome.achievements(progress))
            #expect(snapshot.progressionHint == progress.hint.flatMap(ProgressionFormat.hintLine))
        }
    }

    @Test(arguments: Scenario.all)
    fileprivate func anyInstantOfTheDayGivesTheSameSnapshot(_ scenario: Scenario) {
        let entries = F.newestFirst(scenario.entries)
        let snapshots = Self.instants.map {
            HomeEngine.snapshot(entries: entries, plans: scenario.plans, progress: scenario.progress,
                                calendar: F.calendar, today: $0)
        }
        #expect(snapshots.allSatisfy { $0 == snapshots[0] })
    }

    @Test
    func theScenariosReachEveryHeroState() {
        let heroes = Scenario.all.map {
            HomeEngine.snapshot(entries: F.newestFirst($0.entries), plans: $0.plans, progress: $0.progress,
                                calendar: F.calendar, today: F.day(F.today)).hero
        }
        #expect(heroes.contains(.firstRun))
        #expect(heroes.contains { if case .planToday = $0 { true } else { false } })
        #expect(heroes.contains { if case .completedToday = $0 { true } else { false } })
        #expect(heroes.contains { if case .restDay = $0 { true } else { false } })
        #expect(heroes.contains { if case .freeMode = $0 { true } else { false } })
    }
}

// MARK: - The dashboard computes it once per change
@MainActor
@Suite("Home computes its snapshot once per change")
struct HomeSnapshotCachingTests {
    final class Clock {
        var now = F.day(F.today, hour: 8)
    }

    struct Home {
        let harness: HomeHarness
        let planStore: InMemoryWorkoutPlanStore
        let placementStore: InMemorySkillPlacementStore
        let clock: Clock

        var dashboard: HomeDashboardViewModel { harness.dashboard }
        var journal: TrainingJournal { harness.journal }
        var progress: ProgressService { harness.progress }
    }

    func home(entries: [WorkoutLogEntry] = [], plans: [WorkoutPlan] = []) -> Home {
        let clock = Clock()
        let planStore = InMemoryWorkoutPlanStore(initial: plans)
        let placementStore = InMemorySkillPlacementStore()
        let harness = HomeHarness(logStore: InMemoryWorkoutLogStore(initial: entries),
                                  planStore: planStore,
                                  placementStore: placementStore,
                                  calendar: F.calendar,
                                  clock: { clock.now })
        return Home(harness: harness, planStore: planStore, placementStore: placementStore, clock: clock)
    }

    @Test
    func rendersReadTheSameSnapshotUntilSomethingChanges() {
        let home = home(entries: [F.entry(at: F.day(9))], plans: [F.plan("Środa", .weekly([.wednesday]))])
        let dashboard = home.dashboard

        // A render reads all of these, several times over.
        for _ in 0..<5 {
            _ = dashboard.heroState()
            _ = dashboard.streak
            _ = dashboard.latestWorkout
            _ = dashboard.nextWorkoutState
            _ = dashboard.achievementsSummary
            _ = dashboard.progressionHint
        }
        #expect(dashboard.snapshotComputationCount == 1)

        // Coming back to Home later the same day changes nothing.
        home.clock.now = F.day(F.today, hour: 21)
        dashboard.reload()
        _ = dashboard.heroState()
        #expect(dashboard.snapshotComputationCount == 1)
    }

    @Test
    func aSaveAPlanChangeADayAndAPlacementEachRecomputeOnce() async throws {
        let home = home(entries: [F.entry(at: F.day(9))])
        let dashboard = home.dashboard
        _ = dashboard.heroState()
        #expect(dashboard.snapshotComputationCount == 1)

        try await home.journal.log(F.entry(at: F.day(F.today, hour: 7)))
        _ = dashboard.heroState()
        _ = dashboard.streak
        #expect(dashboard.snapshotComputationCount == 2)
        #expect(dashboard.streak.current == 2)

        try home.planStore.save(F.plan("Środa", .weekly([.wednesday])))
        dashboard.reload()
        _ = dashboard.nextWorkoutState
        #expect(dashboard.snapshotComputationCount == 3)
        dashboard.reload()
        _ = dashboard.nextWorkoutState
        #expect(dashboard.snapshotComputationCount == 3)

        home.clock.now = F.day(F.today + 1, hour: 8)
        dashboard.reload()
        _ = dashboard.heroState()
        #expect(dashboard.snapshotComputationCount == 4)

        try home.placementStore.save(SkillPlacement(declaredRungByPath: [.core: 2]))
        home.progress.reloadPlacement()
        _ = dashboard.achievementsSummary
        #expect(dashboard.snapshotComputationCount == 5)
    }

    @Test
    func theCachedSnapshotIsTheFreshOne() async throws {
        let wednesday = F.plan("Środa", .weekly([.wednesday]))
        let home = home(entries: [F.entry(at: F.day(8)), F.entry(ExerciseCatalog.dipsID, at: F.day(9))],
                        plans: [wednesday])
        let dashboard = home.dashboard
        _ = dashboard.heroState()
        try await home.journal.log(F.entry(at: F.day(F.today, hour: 7)))

        let fresh = HomeEngine.snapshot(entries: home.journal.newestFirst, plans: [wednesday],
                                        progress: home.progress.snapshot, calendar: F.calendar,
                                        today: home.clock.now)
        #expect(dashboard.snapshot == fresh)
        #expect(dashboard.heroState() == dashboard.heroState(asOf: home.clock.now))
        #expect(dashboard.nextWorkoutState == dashboard.nextWorkoutState(asOf: home.clock.now))
        #expect(dashboard.streak == dashboard.streak(asOf: home.clock.now))
    }
}
