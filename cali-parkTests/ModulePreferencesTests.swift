//
//  ModulePreferencesTests.swift
//  cali-parkTests
//
//  Ticket 024, audit E-12 / C-15: Home module preferences read and write the
//  `enabledModules` format earlier builds stored, through an injected
//  `UserDefaults`; modules move up and down without dragging; a drag ends on
//  drop or cancel and never reorders anything outside a drag.
//

import Foundation
import Testing

@testable import cali_park

@MainActor
@Suite("Home module preferences")
struct ModulePreferencesTests {
    private let defaults = UserDefaults.throwaway()
    private let key = "enabledModules"

    // MARK: Load and save

    @Test("A fresh install shows the default modules and writes nothing")
    func freshInstallDefaults() {
        let preferences = ModulePreferences(defaults: defaults)

        #expect(preferences.enabledModules == ["log", "next", WeeklyGoalModule.id, "parks"])
        #expect(defaults.object(forKey: key) == nil)
    }

    @Test("The stored order and choice from an earlier build is kept")
    func legacyFormatKept() {
        let legacy = ["achievements", "streak", "log"]
        defaults.set(legacy, forKey: key)

        let preferences = ModulePreferences(defaults: defaults)

        #expect(preferences.enabledModules == legacy)
        #expect(defaults.stringArray(forKey: key) == legacy)
    }

    @Test("An empty stored list stays empty instead of falling back to the defaults")
    func emptyListKept() {
        defaults.set([String](), forKey: key)

        #expect(ModulePreferences(defaults: defaults).enabledModules.isEmpty)
    }

    @Test("Retired, unknown and duplicate IDs are dropped and the cleaned list is saved")
    func unknownIDsFiltered() {
        defaults.set(["friends", "log", "feed", "weather", "log", "parks"], forKey: key)

        let preferences = ModulePreferences(defaults: defaults)

        #expect(preferences.enabledModules == ["log", "parks"])
        #expect(defaults.stringArray(forKey: key) == ["log", "parks"])
    }

    @Test("A stored value of the wrong type falls back to the defaults and is not overwritten")
    func wrongTypeFallsBack() {
        defaults.set("log", forKey: key)

        let preferences = ModulePreferences(defaults: defaults)

        #expect(preferences.enabledModules == ModulePreferences.defaultModuleIDs)
        #expect(defaults.string(forKey: key) == "log")
    }

    @Test("Changes survive a relaunch")
    func changesPersist() {
        let preferences = ModulePreferences(defaults: defaults)
        preferences.setEnabled(true, for: "streak")
        preferences.setEnabled(false, for: "next")
        preferences.moveUp("streak")

        let relaunched = ModulePreferences(defaults: defaults)

        #expect(relaunched.enabledModules == ["log", WeeklyGoalModule.id, "streak", "parks"])
        #expect(defaults.stringArray(forKey: key) == relaunched.enabledModules)
    }

    // MARK: Show and hide

    @Test("Enabling appends at the end; enabling twice or an unknown ID changes nothing")
    func setEnabled() {
        defaults.set(["log"], forKey: key)
        let preferences = ModulePreferences(defaults: defaults)

        preferences.setEnabled(true, for: "parks")
        preferences.setEnabled(true, for: "parks")
        preferences.setEnabled(true, for: "friends")
        #expect(preferences.enabledModules == ["log", "parks"])

        preferences.setEnabled(false, for: "log")
        #expect(preferences.enabledModules == ["parks"])
        #expect(preferences.disabledDefinitions.map(\.id) == ["log", "next", WeeklyGoalModule.id, "streak", "achievements"])
    }

    // MARK: Move up and down

    @Test("Move up and down swap with the neighbour; the ends do not move")
    func moveUpDown() {
        defaults.set(["log", "next", "parks"], forKey: key)
        let preferences = ModulePreferences(defaults: defaults)

        #expect(preferences.canMoveUp("log") == false)
        #expect(preferences.canMoveDown("log"))
        #expect(preferences.canMoveUp("parks"))
        #expect(preferences.canMoveDown("parks") == false)
        #expect(preferences.canMoveUp("streak") == false)
        #expect(preferences.canMoveDown("streak") == false)

        preferences.moveDown("log")
        #expect(preferences.enabledModules == ["next", "log", "parks"])
        preferences.moveUp("parks")
        #expect(preferences.enabledModules == ["next", "parks", "log"])

        preferences.moveUp("next")
        preferences.moveDown("log")
        preferences.moveUp("streak")
        #expect(preferences.enabledModules == ["next", "parks", "log"])
        #expect(defaults.stringArray(forKey: key) == ["next", "parks", "log"])
    }

    @Test(
        "List.onMove offsets reorder; out-of-range offsets are ignored",
        arguments: [
            (IndexSet(integer: 0), 3, ["next", "parks", "log"]),
            (IndexSet(integer: 2), 0, ["parks", "log", "next"]),
            (IndexSet(integer: 1), 1, ["log", "next", "parks"]),
            (IndexSet(integer: 5), 0, ["log", "next", "parks"]),
            (IndexSet(integer: 0), 4, ["log", "next", "parks"])
        ])
    func listMove(source: IndexSet, destination: Int, expected: [String]) {
        defaults.set(["log", "next", "parks"], forKey: key)
        let preferences = ModulePreferences(defaults: defaults)

        preferences.move(fromOffsets: source, toOffset: destination)

        #expect(preferences.enabledModules == expected)
    }

    @Test(
        "Dragging onto a module takes its place, down or up",
        arguments: [
            ("log", "parks", ["next", "streak", "parks", "log"]),
            ("parks", "log", ["parks", "log", "next", "streak"]),
            ("next", "streak", ["log", "streak", "next", "parks"]),
            ("log", "log", ["log", "next", "streak", "parks"]),
            ("log", "achievements", ["log", "next", "streak", "parks"])
        ])
    func dragOnto(dragged: String, target: String, expected: [String]) {
        defaults.set(["log", "next", "streak", "parks"], forKey: key)
        let preferences = ModulePreferences(defaults: defaults)

        preferences.move(dragged, onto: target)

        #expect(preferences.enabledModules == expected)
    }

    // MARK: Drag state

    @Test("Entering a module reorders only during a drag started on Home")
    func dragReordersOnlyWhileDragging() {
        defaults.set(["log", "next", "parks"], forKey: key)
        let preferences = ModulePreferences(defaults: defaults)
        let drag = ModuleDragState()

        // Text dragged in from another app: no drag in progress.
        drag.enter("log", in: preferences)
        #expect(preferences.enabledModules == ["log", "next", "parks"])

        _ = drag.begin("parks")
        drag.enter("log", in: preferences)
        #expect(preferences.enabledModules == ["parks", "log", "next"])
        #expect(drag.draggingID == "parks")
    }

    @Test("A module shows as lifted only once a drop target on Home has seen the drag")
    func liftedOnlyWhenActive() {
        let preferences = ModulePreferences(defaults: defaults)
        let drag = ModuleDragState()

        // SwiftUI also asks for a drag item right after a drop, with no drag.
        _ = drag.begin("parks")
        #expect(drag.liftedID == nil)

        drag.enter("parks", in: preferences)
        #expect(drag.liftedID == "parks")

        drag.clear()
        #expect(drag.liftedID == nil)
        _ = drag.begin("log")
        #expect(drag.liftedID == nil)
    }

    @Test("A drop or the end of the drag clears it; a stale end does not clear a newer drag")
    func dragEnds() {
        let drag = ModuleDragState()

        let first = drag.begin("log")
        drag.clear()
        #expect(drag.draggingID == nil)

        let second = drag.begin("next")
        drag.end(first)
        #expect(drag.draggingID == "next")

        drag.end(second)
        #expect(drag.draggingID == nil)
    }

    @Test("The seeded environment never touches the real defaults")
    func seededEnvironmentIsIsolated() {
        let environment = AppEnvironment.seeded()
        let other = AppEnvironment.seeded()

        environment.modulePreferences.setEnabled(true, for: "streak")

        #expect(environment.modulePreferences.isEnabled("streak"))
        #expect(other.modulePreferences.isEnabled("streak") == false)
    }
}
