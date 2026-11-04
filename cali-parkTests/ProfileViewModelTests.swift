import Foundation
import Testing

@testable import cali_park

@MainActor
@Suite("Profile statistics")
struct ProfileViewModelTests {
    private typealias F = WeeklyGoalFixtures

    /// Wednesday noon of the reference week.
    private nonisolated static let now = F.day(week: 0, 2)

    /// Three met weeks of the default 3-day goal, ending today, with today's
    /// workout logged as one two-exercise session.
    private nonisolated static let entries: [WorkoutLogEntry] = {
        let session = UUID()
        return F.trained(week: -2, days: [0, 1, 2])
            + F.trained(week: -1, days: [0, 2, 4])
            + F.trained(week: 0, days: [0, 1])
            + [
                WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID, date: now, sets: [LoggedSet(reps: 8)], sessionID: session),
                WorkoutLogEntry(exerciseID: ExerciseCatalog.dipsID, date: now, sets: [LoggedSet(reps: 10)], sessionID: session)
            ]
    }()

    /// A profile over the shared services, plus the journal to log through.
    private func profile(
        log: WorkoutLogStoring = InMemoryWorkoutLogStore(initial: entries),
        goal: WeeklyGoalStoring = InMemoryWeeklyGoalStore()
    ) -> (ProfileViewModel, TrainingJournal) {
        let journal = TrainingJournal(store: log)
        let progress = ProgressService(
            journal: journal, placementStore: InMemorySkillPlacementStore(),
            calendar: F.calendar, clock: { Self.now })
        let goals = WeeklyGoalService(
            journal: journal, store: goal,
            planService: .testing(InMemoryWorkoutPlanStore(), logStore: log),
            calendar: F.calendar, clock: { Self.now })
        let model = ProfileViewModel(
            journal: journal, progress: progress, goals: goals,
            calendar: F.calendar, clock: { Self.now })
        return (model, journal)
    }

    @Test("Statistics count sessions, both streaks, and the level from the log")
    func statistics() {
        let stats = profile().0.statistics

        #expect(stats.workouts == 9)
        #expect(stats.dayStreak == 3)
        #expect(stats.longestDayStreak == 3)
        #expect(stats.weekStreak == 3)
        #expect(stats.level == ProgressionEngine.playerLevel(for: Self.entries))
    }

    @Test("An empty journal shows zeros and level 1")
    func empty() {
        let stats = profile(log: InMemoryWorkoutLogStore()).0.statistics

        #expect(stats.workouts == 0)
        #expect(stats.dayStreak == 0)
        #expect(stats.weekStreak == 0)
        #expect(stats.level.level == 1)
    }

    @Test("The weekly goal row shows the primary goal and this week's progress")
    func weeklyGoalCopy() {
        let (model, _) = profile(
            goal: InMemoryWeeklyGoalStore(
                initial: WeeklyGoalHistory(versions: [
                    F.version([F.days(4)], from: F.day(week: -3))
                ])))

        #expect(model.weeklyGoalTitle == "4 dni treningowe")
        #expect(model.weeklyGoalProgressText == "Ten tydzień: 3 / 4 dni")
    }

    @Test("A paused week shows only the pause, not \"Ten tydzień: Pauza…\"")
    func pausedWeekCopy() throws {
        let pause = WeeklyGoalPause(start: F.day(week: 0, hour: 0), plannedEnd: F.day(week: 1, hour: 0))
        let (model, _) = profile(
            goal: InMemoryWeeklyGoalStore(
                initial: WeeklyGoalHistory(
                    versions: [F.version([F.days(4)], from: F.day(week: -3))],
                    pauses: [pause]
                )))

        let text = try #require(model.weeklyGoalProgressText)
        #expect(text == WeeklyGoalFormat.pauseLine(pause, calendar: F.calendar))
        #expect(text.hasPrefix("Pauza do "))
    }

    @Test("A workout logged anywhere shows up without a reload")
    func observesTheJournal() async throws {
        let (model, journal) = profile()
        try await journal.log(F.entry(at: Self.now))

        #expect(model.statistics.workouts == 10)
    }

    @Test("An unreadable log shows an error instead of claiming zero workouts silently")
    func unreadableLog() {
        let (model, _) = profile(log: UnreadableWorkoutLogStore())

        #expect(model.errorMessage == StoreLoadFailure.message)
        #expect(model.hasLoadError)
        #expect(model.statistics.workouts == 0)
        #expect(model.statistics.level.level == 1)
    }

    @Test("An unreadable goal hides the week streak but keeps the rest")
    func unreadableGoal() {
        let (model, _) = profile(goal: BrokenWeeklyGoalStore())

        #expect(model.weeklyGoal == nil)
        #expect(model.weeklyGoalProgressText == nil)
        #expect(model.statistics.weekStreak == nil)
        #expect(model.statistics.workouts == 9)
        #expect(model.errorMessage == StoreLoadFailure.message)
    }
}

@Suite("About screen")
struct AboutContentTests {
    @Test func osmCreditMatchesTheMapAttribution() {
        #expect(AboutContent.mapAttribution.name == ParkFormat.attribution)
        #expect(AboutContent.mapAttribution.name == "© Współtwórcy OpenStreetMap")
    }
}
