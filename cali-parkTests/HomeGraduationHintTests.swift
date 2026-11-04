//
//  HomeGraduationHintTests.swift
//  cali-parkTests
//
//  Home's hint line for "Czas na Fundamenty": shown while the Planner's card
//  would be, gone once the card is dismissed or used.
//

import Foundation
import Testing

@testable import cali_park

private typealias E = ExerciseCatalog

@MainActor
@Suite("Home's line to Czas na Fundamenty")
struct HomeGraduationHintTests {
    /// The day before `ProgramFixtures.today` (a Wednesday).
    private static let yesterday = ProgramFixtures.calendar.date(byAdding: .day, value: -1, to: ProgramFixtures.today)!

    /// A "Pierwsze podciągnięcie" plan on Mondays, so the Wednesday is a rest day.
    private static func firstPullUpPlan() throws -> WorkoutPlan {
        var plan = try #require(
            ProgramPrescriber.plans(
                for: ProgramCatalog.firstPullUp, pathStates: ProgramFixtures.newcomer,
                today: ProgramFixtures.today
            ).first)
        plan.schedule = .weekly([.monday])
        return plan
    }

    private static func dashboard(
        pullUpReps: Int,
        plans: [WorkoutPlan],
        defaults: UserDefaults = .throwaway()
    ) -> HomeDashboardViewModel {
        HomeDashboardViewModel(
            store: InMemoryWorkoutLogStore(initial: [ProgramFixtures.reps(E.pullUpsID, pullUpReps, on: yesterday)]),
            planService: .testing(InMemoryWorkoutPlanStore(initial: plans)),
            defaults: defaults,
            calendar: ProgramFixtures.calendar,
            clock: { ProgramFixtures.today }
        )
    }

    @Test
    func showsOnceFullPullUpsAreConquered() throws {
        let plan = try Self.firstPullUpPlan()
        let ready = Self.dashboard(pullUpReps: 8, plans: [plan])
        #expect(ready.graduationCandidate == plan)
        guard case .restDay = ready.heroState() else {
            Issue.record("Hero is \(ready.heroState()), which has no hint line")
            return
        }

        #expect(Self.dashboard(pullUpReps: 7, plans: [plan]).graduationCandidate == nil)
    }

    @Test
    func aPlanFromAnotherProgramShowsNothing() {
        let plan = WorkoutPlan(name: "Mój", schedule: .weekly([.monday]))
        #expect(Self.dashboard(pullUpReps: 8, plans: [plan]).graduationCandidate == nil)
    }

    @Test
    func aDismissedCardHidesTheLineOnTheNextReload() throws {
        let defaults = UserDefaults.throwaway()
        let dashboard = Self.dashboard(pullUpReps: 8, plans: [try Self.firstPullUpPlan()], defaults: defaults)
        #expect(dashboard.graduationCandidate != nil)

        // "Nie teraz" (or "Przejdź na Fundamenty") in the Planner, then back to Home.
        defaults.set(true, forKey: DefaultsKey.hasDismissedFundamentalsHint.rawValue)
        dashboard.reload()
        #expect(dashboard.graduationCandidate == nil)
    }
}
