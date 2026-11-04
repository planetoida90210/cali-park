//
//  PlanFlowTests.swift
//  cali-parkUITests
//
//  A plan from a ready program, started from Home's "Rozpocznij" and logged:
//  Home then shows the day as done. Also the Home line that leads to
//  "Czas na Fundamenty".
//

import XCTest

final class PlanFlowTests: CaliParkUITestCase {
    func testAPlanFromAProgramStartsFromHomeAndCountsAsDone() {
        let app = XCUIApplication.launched(.onboarded)

        app.element("home.plans").waitToAppear().tap()
        app.element("plans.browsePrograms").waitToAppear().tap()
        app.element("programs.row.minimum").waitToAppear().tap()
        app.element("programDetail.create").waitToAppear().tap()

        // The new plan opens in the editor. Train today whatever the weekday.
        app.element("planEditor.save").waitToAppear()
        let weekday = Calendar.current.component(.weekday, from: .now)
        let today = app.scrolledTo("planEditor.weekday.\(weekday)")
        if !today.isSelected { today.tap() }
        XCTAssertTrue(today.isSelected)
        app.element("planEditor.save").tap()

        app.element("planEditor.save").waitToDisappear()
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.element("home.hero.start").waitToAppear().tap()
        app.element(withIdentifierPrefix: "quickWorkout.item.").waitToAppear().tap()
        app.logOneSet(10)
        app.finishWorkout()

        app.element("home.hero.completedToday").waitToAppear()
        app.scrolledTo("home.module.nextWorkout").tap()
        app.element("home.nextWorkout.doneToday").waitToAppear()
    }

    func testHomeLeadsToTheFundamentalsCard() {
        let app = XCUIApplication.launched(.veteran)

        app.dismissCelebrations()
        app.element("home.hero.restDay").waitToAppear()
        app.element("home.hero.graduationHint").waitToAppear().tap()

        app.element("plans.graduationCard").waitToAppear()
    }
}
