//
//  OnboardingFlowTests.swift
//  cali-parkUITests
//
//  First run: welcome → level test → program → weekly goal → Home, with the
//  chosen program's plan in the hero.
//

import XCTest

final class OnboardingFlowTests: CaliParkUITestCase {
    func testOnboardingLandsOnHomeWithTheProgramsPlan() {
        let app = XCUIApplication.launched(.fresh)

        app.element("onboarding.page.welcome").waitToAppear()
        app.element("onboarding.forward").tap()

        // The level test keeps its defaults: the suggestion follows them.
        app.element("onboarding.page.placement").waitToBeHittable()
        app.element("onboarding.forward").tap()

        app.element("onboarding.page.program").waitToBeHittable()
        let minimum = app.element("onboarding.program.minimum").waitToAppear()
        minimum.tap()
        XCTAssertTrue(minimum.isSelected)
        app.element("onboarding.forward").tap()

        app.element("onboarding.page.weeklyGoal").waitToBeHittable()
        app.element("onboarding.forward").tap()

        // "Minimum" trains Mon/Wed/Fri: today's plan, or a rest day naming it.
        let hero = app.element(anyOf: ["home.hero.planToday", "home.hero.restDay"]).waitToAppear()
        XCTAssertTrue(hero.descendant(labelContaining: "Minimum").exists, "The hero does not name the plan")
        XCTAssertFalse(app.element("onboarding.forward").exists)
    }
}
