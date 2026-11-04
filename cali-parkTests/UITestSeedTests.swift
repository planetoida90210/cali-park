//
//  UITestSeedTests.swift
//  cali-parkTests
//
//  The UI tests' seeded launch (`-uitest-reset`, `CALIPARK_UITEST_SEED`):
//  which seed a launch asks for, and the state each seed starts in.
//

import Foundation
import Testing

@testable import cali_park

@MainActor
@Suite("The UI tests' seeded launch")
struct UITestSeedTests {
    private let calendar = TestCalendar.utc
    private let now = TestDate.reference

    @Test
    func aNormalLaunchHasNoSeed() {
        #expect(UITestSeed.requested(arguments: ["cali-park"], environment: ["CALIPARK_UITEST_SEED": "veteran"]) == nil)
    }

    @Test(arguments: [
        ([:], UITestSeed.fresh),
        (["CALIPARK_UITEST_SEED": "onboarded"], .onboarded),
        (["CALIPARK_UITEST_SEED": "planToday"], .planToday),
        (["CALIPARK_UITEST_SEED": "veteran"], .veteran)
    ])
    func theResetArgumentPicksTheNamedSeed(environment: [String: String], seed: UITestSeed) {
        #expect(UITestSeed.requested(arguments: ["cali-park", "-uitest-reset"], environment: environment) == seed)
    }

    @Test(arguments: UITestSeed.allCases)
    func onlyTheFreshSeedShowsOnboarding(seed: UITestSeed) {
        let defaults = UserDefaults.throwaway()
        let environment = AppEnvironment.uiTest(seed, defaults: defaults, calendar: calendar, now: now)
        #expect(environment.defaults === defaults)
        #expect(defaults.bool(forKey: DefaultsKey.hasCompletedOnboarding.rawValue) == (seed != .fresh))
    }

    @Test(arguments: [UITestSeed.fresh, .onboarded])
    func theEmptySeedsHaveNothingSaved(seed: UITestSeed) throws {
        let environment = AppEnvironment.uiTest(seed, defaults: .throwaway(), calendar: calendar, now: now)
        #expect(environment.journal.entries.isEmpty)
        #expect(try environment.workoutPlanService.loadPlans().isEmpty)
    }

    @Test
    func thePlanTodaySeedHasAPlanDueToday() throws {
        let environment = AppEnvironment.uiTest(.planToday, defaults: .throwaway(), calendar: calendar, now: now)
        let plans = try environment.workoutPlanService.loadPlans()
        let hero = HomeEngine.heroState(entries: environment.journal.newestFirst, plans: plans,
                                        calendar: calendar, today: now)
        guard case .planToday(let plan, 0, 0) = hero else {
            Issue.record("Hero is \(hero)")
            return
        }
        #expect(plan.name == "Push Day")
    }

    @Test
    func theVeteranSeedRestsTodayAndIsReadyForFundamentals() throws {
        let environment = AppEnvironment.uiTest(.veteran, defaults: .throwaway(), calendar: calendar, now: now)
        let plans = try environment.workoutPlanService.loadPlans()
        let snapshot = HomeEngine.snapshot(entries: environment.journal.newestFirst, plans: plans,
                                           progress: environment.progressService.snapshot,
                                           calendar: calendar, today: now)
        guard case .restDay = snapshot.hero else {
            Issue.record("Hero is \(snapshot.hero)")
            return
        }
        #expect(snapshot.graduationCandidate?.programID == ProgramID.firstPullUp.rawValue)
    }
}
