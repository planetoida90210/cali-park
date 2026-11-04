//
//  QuickWorkoutFlowTests.swift
//  cali-parkUITests
//
//  "Szybki trening": add an exercise, log a set, finish; the workout is in
//  "Historia treningów" and in Home's last workout.
//

import XCTest

final class QuickWorkoutFlowTests: CaliParkUITestCase {
    func testAQuickWorkoutShowsInHistoryAndOnHome() {
        let app = XCUIApplication.launched(.onboarded)

        app.element("home.hero.firstRun").waitToAppear()
        app.element("home.quickWorkout").tap()

        app.element("quickWorkout.addExercise").waitToAppear().tap()
        // "Dipy" has variants, so the picker asks which one: the base movement.
        app.element("exercisePicker.\(CatalogID.dips)").waitToAppear().tap()
        app.element("exerciseVariant.\(CatalogID.dips)").waitToAppear().tap()
        app.logOneSet(10)

        app.element("quickWorkout.item.\(CatalogID.dips)").waitToAppear()
        app.finishWorkout()

        app.element("home.hero.completedToday").waitToAppear()
        app.scrolledTo("home.module.lastWorkout").tap()
        let lastWorkout = app.element("home.lastWorkout").waitToAppear()
        XCTAssertTrue(lastWorkout.label.contains("Dipy"), "Home's last workout is \"\(lastWorkout.label)\"")

        app.openTab("Profil")
        app.element("profile.history").waitToAppear().tap()
        app.element("history.entry.\(CatalogID.dips)").waitToAppear()
    }
}
