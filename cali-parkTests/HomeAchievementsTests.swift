//
//  HomeAchievementsTests.swift
//  cali-parkTests
//
//  Sprint SK6b — Home lives off the same progression data: the real
//  achievements module summary (level / XP / last advancement), the hero's
//  progression hint, and a regression that adding the placement store left the
//  H1 hero state machine untouched. Pure and deterministic: in-memory stores,
//  an injected UTC calendar, no timing.
//

import Foundation
import Testing
@testable import cali_park

// MARK: - Fixtures

private enum AchievementFixture {
    /// UTC calendar so day math never depends on the machine's timezone.
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    static func day(_ n: Int) -> Date {
        Date(timeIntervalSince1970: Double(n) * 86_400)
    }

    /// A clean 3 × 8 of the given rep exercise on `date`.
    static func reps3x8(_ exerciseID: UUID, on date: Date = day(0)) -> WorkoutLogEntry {
        WorkoutLogEntry(
            exerciseID: exerciseID,
            date: date,
            sets: [LoggedSet(reps: 8), LoggedSet(reps: 8), LoggedSet(reps: 8)]
        )
    }
}

// MARK: - ProgressionEngine.lastAdvancement

struct LastAdvancementTests {
    @Test func anEmptyJournalHasNoAdvancement() {
        #expect(ProgressionEngine.lastAdvancement(from: []) == nil)
    }

    @Test func fullPullUpsConquerThePullUpRung() throws {
        let logs = [AchievementFixture.reps3x8(ExerciseCatalog.pullUpsID)]

        let reference = try #require(ProgressionEngine.lastAdvancement(from: logs))

        // Full pull-ups sit at rung index 4 of the pull-up ladder.
        #expect(reference == RungReference(pathID: .pullUp, rungIndex: 4))
    }

    @Test func theLatestConqueredRungWins() throws {
        // Pull-ups conquered first, dips conquered later — the later date is the
        // headline advance.
        let logs = [
            AchievementFixture.reps3x8(ExerciseCatalog.pullUpsID, on: AchievementFixture.day(0)),
            AchievementFixture.reps3x8(ExerciseCatalog.dipsID, on: AchievementFixture.day(5))
        ]

        let reference = try #require(ProgressionEngine.lastAdvancement(from: logs))

        // Full dips sit at rung index 2 of the dip ladder.
        #expect(reference == RungReference(pathID: .dip, rungIndex: 2))
    }
}

// MARK: - ProgressionEngine.mostActionableHint + ProgressionFormat.hintLine

struct ProgressionHintTests {
    @Test func noPartialProgressYieldsNoHint() {
        // A returning athlete with a declaration but no logs: nothing is partway
        // done, so there's nothing to nudge toward.
        let placement = SkillPlacement(declaredRungByPath: [.pullUp: 4])

        #expect(ProgressionEngine.mostActionableHint(logs: [], placement: placement) == nil)
    }

    @Test func partialProgressOnTheCurrentRungIsActionable() throws {
        // Declared at full pull-ups (rung 4); logged 3 × 6 there — 6 of 8 reps.
        let placement = SkillPlacement(declaredRungByPath: [.pullUp: 4])
        let logs = [
            WorkoutLogEntry(
                exerciseID: ExerciseCatalog.pullUpsID,
                sets: [LoggedSet(reps: 6), LoggedSet(reps: 6), LoggedSet(reps: 6)]
            )
        ]

        let hint = try #require(ProgressionEngine.mostActionableHint(logs: logs, placement: placement))
        #expect(hint.pathID == .pullUp)
        #expect(hint.currentRungIndex == 4)

        let line = try #require(ProgressionFormat.hintLine(hint))
        #expect(line.hasPrefix("Jeszcze 2 powtórzenia do 3 × 8"))
        // The next rung (index 5) is what the athlete unlocks.
        let nextRungName = try #require(ExerciseCatalog.exercise(withID: ExerciseCatalog.lPullUpsID)?.name)
        #expect(line.contains("następny szczebel: \(nextRungName)"))
    }
}

// MARK: - HomeDashboardViewModel achievements + hint

@MainActor
struct HomeAchievementsSummaryTests {
    private func dashboard(entries: [WorkoutLogEntry] = [],
                           placement: SkillPlacement? = nil) -> HomeDashboardViewModel {
        HomeDashboardViewModel(
            store: InMemoryWorkoutLogStore(initial: entries),
            planStore: InMemoryWorkoutPlanStore(initial: []),
            placementStore: InMemorySkillPlacementStore(initial: placement),
            calendar: AchievementFixture.calendar
        )
    }

    @Test func aFreshJournalReportsLevelOneAndNoAdvance() {
        let summary = dashboard().achievementsSummary

        #expect(summary.level == 1)
        #expect(summary.earnedBadgeCount == 0)
        #expect(summary.totalBadgeCount == Badge.allCases.count)
        #expect(summary.lastAdvancement == nil)
        // Level 2 begins at 500 XP.
        #expect(summary.xpToNextLevel == 500)
    }

    @Test func logsPopulateTheSummaryFromTheSameCatalogNames() throws {
        let vm = dashboard(entries: [AchievementFixture.reps3x8(ExerciseCatalog.pullUpsID)])

        let summary = vm.achievementsSummary
        // 24 reps × 10 XP + five conquered rungs × 100 XP = 740 XP → level 2.
        #expect(summary.level == 2)
        #expect(summary.earnedBadgeCount >= 1) // at least the first-workout badge

        let advancement = try #require(summary.lastAdvancement)
        let path = try #require(ProgressionCatalog.path(withID: .pullUp))
        let exercise = try #require(ExerciseCatalog.exercise(withID: path.steps[4].exerciseID))
        #expect(advancement.title == exercise.name)
        #expect(advancement.pathName == path.name)
        #expect(advancement.symbolName == path.symbolName)
    }

    @Test func theHintSurfacesThroughTheViewModel() throws {
        let placement = SkillPlacement(declaredRungByPath: [.pullUp: 4])
        let logs = [
            WorkoutLogEntry(
                exerciseID: ExerciseCatalog.pullUpsID,
                sets: [LoggedSet(reps: 6), LoggedSet(reps: 6), LoggedSet(reps: 6)]
            )
        ]
        let hint = try #require(dashboard(entries: logs, placement: placement).progressionHint)

        #expect(hint.hasPrefix("Jeszcze 2 powtórzenia do 3 × 8"))
    }

    // MARK: H1 regression — the placement store must not disturb heroState.
    @Test func placementDoesNotChangeHeroStateForAnEmptyJournal() {
        let vm = dashboard(placement: SkillPlacement(declaredRungByPath: [.pullUp: 4]))

        #expect(vm.heroState(asOf: AchievementFixture.day(0)) == .firstRun)
        #expect(vm.progressionHint == nil)
    }
}
