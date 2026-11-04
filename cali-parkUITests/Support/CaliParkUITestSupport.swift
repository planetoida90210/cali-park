//
//  CaliParkUITestSupport.swift
//  cali-parkUITests
//
//  Launching the app on a known seed and waiting for its screens. The app
//  side is `UITestSeed` (cali-park/PreviewSupport/UITestLaunch.swift).
//

import XCTest

// MARK: - Seed
/// The app's starting data, mirrored from `UITestSeed` in the app.
enum Seed: String {
    /// Nothing saved: onboarding.
    case fresh
    /// Onboarding done, no plans, an empty journal.
    case onboarded
    /// Onboarding done and a one-off plan due today.
    case planToday
    /// A seasoned athlete whose "Pierwsze podciągnięcie" plan is done; today
    /// is a rest day.
    case veteran
    /// Five weeks of "Fundamenty" with a week streak and the plan due
    /// today, for the App Store screenshots.
    case storeTour
}

/// Stable catalog exercise IDs (`ExerciseCatalog`), as the identifiers use them.
enum CatalogID {
    static let dips = "E0000000-0000-4000-8000-000000000003"
}

// MARK: - Launch
extension XCUIApplication {
    /// Launches the app with `-uitest-reset` on `seed`: in-memory stores and
    /// a cleared `UserDefaults` suite, so nothing from an earlier run leaks in.
    static func launched(_ seed: Seed) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset"]
        app.launchEnvironment["CALIPARK_UITEST_SEED"] = seed.rawValue
        app.launch()
        return app
    }

    /// The first element with this accessibility identifier. A toolbar
    /// button shows up twice in the tree, so this never asks for a single match.
    func element(_ identifier: String) -> XCUIElement {
        descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// Swipes the screen up until the element with `identifier` is on screen,
    /// for rows a list only builds once they scroll into view.
    @discardableResult
    func scrolledTo(_ identifier: String,
                    maxSwipes: Int = 8,
                    file: StaticString = #filePath,
                    line: UInt = #line) -> XCUIElement {
        let target = element(identifier)
        var swipes = 0
        while !(target.exists && target.isHittable), swipes < maxSwipes {
            swipeUp()
            swipes += 1
        }
        XCTAssertTrue(target.exists && target.isHittable, "\(identifier) is not on screen", file: file, line: line)
        return target
    }

    /// The first element whose identifier starts with `prefix`.
    func element(withIdentifierPrefix prefix: String) -> XCUIElement {
        descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix)).firstMatch
    }

    /// Closes every celebration (rung, level, weekly goal) on screen, tapping
    /// the dimmed background above the card. Returns at once when none shows.
    func dismissCelebrations() {
        let background = element("celebration.dismiss")
        while background.waitForExistence(timeout: 1) {
            background.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.05)).tap()
        }
    }

    /// Selects a tab by its title.
    func openTab(_ title: String) {
        tabBars.buttons[title].firstMatch.tap()
    }
}

// MARK: - Waiting
extension XCUIElement {
    /// Fails the test unless the element appears within `timeout`, and
    /// returns it for chaining.
    @discardableResult
    func waitToAppear(timeout: TimeInterval = 10,
                      file: StaticString = #filePath,
                      line: UInt = #line) -> XCUIElement {
        XCTAssertTrue(waitForExistence(timeout: timeout), "\(self) did not appear", file: file, line: line)
        return self
    }

    /// Fails the test unless the element becomes tappable on screen within
    /// `timeout` (a paged onboarding step that has scrolled into view).
    @discardableResult
    func waitToBeHittable(timeout: TimeInterval = 10,
                          file: StaticString = #filePath,
                          line: UInt = #line) -> XCUIElement {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "\(self) did not become hittable", file: file, line: line)
        return self
    }

    /// A descendant whose label contains `text`.
    func descendant(labelContaining text: String) -> XCUIElement {
        descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }
}

// MARK: - SetPad
extension XCUIApplication {
    /// Types `value` on the open SetPad, adds it as one set, and hands the
    /// sets to the workout ("Dodaj do treningu").
    func logOneSet(_ value: Int) {
        element("setPad.save").waitToAppear()
        for digit in String(value) {
            element("setPad.digit.\(digit)").tap()
        }
        element("setPad.addSet").tap()
        element("setPad.save").tap()
    }

    /// "Zakończ", then "Gotowe" on the summary: back on Home.
    func finishWorkout() {
        element("quickWorkout.finish").tap()
        dismissCelebrations()
        element("workoutSummary.done").waitToAppear().tap()
        dismissCelebrations()
    }
}

extension XCUIElement {
    /// Fails the test unless the element is gone within `timeout`.
    func waitToDisappear(timeout: TimeInterval = 10, file: StaticString = #filePath, line: UInt = #line) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: self)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: timeout), .completed,
                       "\(self) is still on screen", file: file, line: line)
    }
}
