//
//  StoreScreenshotTour.swift
//  cali-parkUITests
//
//  The App Store screenshots: six screens of the `storeTour` seed, each kept
//  as a screenshot attachment named after its file ("01-home" and so on).
//  Skipped unless CALIPARK_STORE_SHOTS=1 reaches the test runner, so the
//  normal UI test run never takes it. Run it through
//  scripts/store-screenshots.sh, which also sets the status bar and exports
//  the PNGs into docs/release/screenshots/raw/.
//

import XCTest

final class StoreScreenshotTour: CaliParkUITestCase {
    /// The environment value that turns the tour on; xcodebuild passes
    /// `TEST_RUNNER_CALIPARK_STORE_SHOTS` to the runner without its prefix.
    private static let switchKey = "CALIPARK_STORE_SHOTS"

    override func setUp() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment[Self.switchKey] == "1",
                          "App Store screenshots run only through scripts/store-screenshots.sh")
        try await super.setUp()
    }

    /// The six screens, in the App Store order.
    func testStoreScreenshots() {
        let app = XCUIApplication.launched(.storeTour)
        app.dismissCelebrations()

        // 1. Home: today's "Fundamenty" with the weekly ring.
        app.element("home.hero.start").waitToAppear()
        capture("01-home")

        // 2. The pull-up ladder with its criteria.
        app.openTab("Ścieżki")
        app.element("skills.path.pullUp").waitToAppear().tap()
        app.navigationBars["Podciąganie"].waitToAppear()
        capture("02-ladder")

        // 3. Ready programs, through Home's plans. The browser is a sheet:
        // "Zamknij", then back from the plans to Home.
        app.openTab("Start")
        app.element("home.plans").waitToAppear().tap()
        app.element("plans.programs").waitToAppear().tap()
        app.element("programs.row.fundamentals").waitToAppear()
        capture("03-programs")
        app.buttons["Zamknij"].firstMatch.tap()
        app.element("plans.programs").waitToAppear()
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // 4. The workout: the first pair after one round, resting. "Anuluj"
        // closes it without asking, since no set was changed.
        app.element("home.hero.start").waitToAppear().tap()
        app.element("quickWorkout.round.finish").waitToAppear().tap()
        app.element("quickWorkout.finish").waitToAppear()
        capture("04-workout")
        app.buttons["Anuluj"].firstMatch.tap()
        app.element("home.hero.start").waitToAppear()

        // 5. Profile: the week streak, the day streak, the level and this
        // week's goal.
        app.openTab("Profil")
        app.element("profile.history").waitToAppear()
        capture("05-profile")

        // 6. The Parks map around central Warsaw with the nearest Park's
        // card, through Home's "Najbliższy Park".
        app.openTab("Start")
        app.scrolledTo("home.module.nearestPark").tap()
        app.scrolledTo("home.nearestPark.showOnMap").tap()
        app.element("parks.card").waitToAppear()
        settle(seconds: 4)  // map tiles load from Apple's servers
        capture("06-parks")
    }

    // MARK: Helpers

    /// Keeps a full-screen screenshot named `name` in the result bundle.
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Waits for content with nothing to observe, such as map tiles.
    private func settle(seconds: TimeInterval) {
        let never = XCTestExpectation(description: "settle")
        _ = XCTWaiter().wait(for: [never], timeout: seconds)
    }
}
