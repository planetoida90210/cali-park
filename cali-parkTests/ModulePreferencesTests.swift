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

        #expect(preferences.enabledModules == [.lastWorkout, .nextWorkout, .weeklyGoal, .nearestPark])
        #expect(defaults.object(forKey: key) == nil)
    }

    @Test("The raw values are the IDs every earlier build stored")
    func rawValuesNeverChange() {
        #expect(HomeModule.allCases.map(\.rawValue) == ["log", "next", "parks", "goal", "streak", "achievements"])
    }

    @Test("A stored array from an earlier build decodes to the same modules in the same order")
    func storedArrayFromAnEarlierBuild() {
        let stored = ["goal", "achievements", "streak", "log", "parks", "next"]
        defaults.set(stored, forKey: key)

        let preferences = ModulePreferences(defaults: defaults)

        #expect(preferences.enabledModules == [.weeklyGoal, .achievements, .streak, .lastWorkout, .nearestPark, .nextWorkout])
        #expect(preferences.disabledModules == [])
        #expect(defaults.stringArray(forKey: key) == stored)

        preferences.moveUp(.lastWorkout)
        #expect(defaults.stringArray(forKey: key) == ["goal", "achievements", "log", "streak", "parks", "next"])
    }

    @Test("The stored order and choice from an earlier build is kept")
    func legacyFormatKept() {
        let legacy = ["achievements", "streak", "log"]
        defaults.set(legacy, forKey: key)

        let preferences = ModulePreferences(defaults: defaults)

        #expect(preferences.enabledModules == [.achievements, .streak, .lastWorkout])
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

        #expect(preferences.enabledModules == [.lastWorkout, .nearestPark])
        #expect(defaults.stringArray(forKey: key) == ["log", "parks"])
    }

    @Test("A stored value of the wrong type falls back to the defaults and is not overwritten")
    func wrongTypeFallsBack() {
        defaults.set("log", forKey: key)

        let preferences = ModulePreferences(defaults: defaults)

        #expect(preferences.enabledModules == ModulePreferences.defaultModules)
        #expect(defaults.string(forKey: key) == "log")
    }

    @Test("Changes survive a relaunch")
    func changesPersist() {
        let preferences = ModulePreferences(defaults: defaults)
        preferences.setEnabled(true, for: .streak)
        preferences.setEnabled(false, for: .nextWorkout)
        preferences.moveUp(.streak)

        let relaunched = ModulePreferences(defaults: defaults)

        #expect(relaunched.enabledModules == [.lastWorkout, .weeklyGoal, .streak, .nearestPark])
        #expect(defaults.stringArray(forKey: key) == ["log", "goal", "streak", "parks"])
    }

    // MARK: Show and hide

    @Test("Enabling appends at the end; enabling twice changes nothing")
    func setEnabled() {
        defaults.set(["log"], forKey: key)
        let preferences = ModulePreferences(defaults: defaults)

        preferences.setEnabled(true, for: .nearestPark)
        preferences.setEnabled(true, for: .nearestPark)
        #expect(preferences.enabledModules == [.lastWorkout, .nearestPark])

        preferences.setEnabled(false, for: .lastWorkout)
        #expect(preferences.enabledModules == [.nearestPark])
        #expect(preferences.disabledModules == [.lastWorkout, .nextWorkout, .weeklyGoal, .streak, .achievements])
    }

    // MARK: Move up and down

    @Test("Move up and down swap with the neighbour; the ends do not move")
    func moveUpDown() {
        defaults.set(["log", "next", "parks"], forKey: key)
        let preferences = ModulePreferences(defaults: defaults)

        #expect(preferences.canMoveUp(.lastWorkout) == false)
        #expect(preferences.canMoveDown(.lastWorkout))
        #expect(preferences.canMoveUp(.nearestPark))
        #expect(preferences.canMoveDown(.nearestPark) == false)
        #expect(preferences.canMoveUp(.streak) == false)
        #expect(preferences.canMoveDown(.streak) == false)

        preferences.moveDown(.lastWorkout)
        #expect(preferences.enabledModules == [.nextWorkout, .lastWorkout, .nearestPark])
        preferences.moveUp(.nearestPark)
        #expect(preferences.enabledModules == [.nextWorkout, .nearestPark, .lastWorkout])

        preferences.moveUp(.nextWorkout)
        preferences.moveDown(.lastWorkout)
        preferences.moveUp(.streak)
        #expect(preferences.enabledModules == [.nextWorkout, .nearestPark, .lastWorkout])
        #expect(defaults.stringArray(forKey: key) == ["next", "parks", "log"])
    }

    nonisolated static let listMoves: [(IndexSet, Int, [HomeModule])] = [
        (IndexSet(integer: 0), 3, [.nextWorkout, .nearestPark, .lastWorkout]),
        (IndexSet(integer: 2), 0, [.nearestPark, .lastWorkout, .nextWorkout]),
        (IndexSet(integer: 1), 1, [.lastWorkout, .nextWorkout, .nearestPark]),
        (IndexSet(integer: 5), 0, [.lastWorkout, .nextWorkout, .nearestPark]),
        (IndexSet(integer: 0), 4, [.lastWorkout, .nextWorkout, .nearestPark])
    ]

    @Test("List.onMove offsets reorder; out-of-range offsets are ignored", arguments: listMoves)
    func listMove(source: IndexSet, destination: Int, expected: [HomeModule]) {
        defaults.set(["log", "next", "parks"], forKey: key)
        let preferences = ModulePreferences(defaults: defaults)

        preferences.move(fromOffsets: source, toOffset: destination)

        #expect(preferences.enabledModules == expected)
    }

    nonisolated static let drags: [(HomeModule, HomeModule, [HomeModule])] = [
        (.lastWorkout, .nearestPark, [.nextWorkout, .streak, .nearestPark, .lastWorkout]),
        (.nearestPark, .lastWorkout, [.nearestPark, .lastWorkout, .nextWorkout, .streak]),
        (.nextWorkout, .streak, [.lastWorkout, .streak, .nextWorkout, .nearestPark]),
        (.lastWorkout, .lastWorkout, [.lastWorkout, .nextWorkout, .streak, .nearestPark]),
        (.lastWorkout, .achievements, [.lastWorkout, .nextWorkout, .streak, .nearestPark])
    ]

    @Test("Dragging onto a module takes its place, down or up", arguments: drags)
    func dragOnto(dragged: HomeModule, target: HomeModule, expected: [HomeModule]) {
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
        drag.enter(.lastWorkout, in: preferences)
        #expect(preferences.enabledModules == [.lastWorkout, .nextWorkout, .nearestPark])

        _ = drag.begin(.nearestPark)
        drag.enter(.lastWorkout, in: preferences)
        #expect(preferences.enabledModules == [.nearestPark, .lastWorkout, .nextWorkout])
        #expect(drag.draggingID == .nearestPark)
    }

    @Test("A module shows as lifted only once a drop target on Home has seen the drag")
    func liftedOnlyWhenActive() {
        let preferences = ModulePreferences(defaults: defaults)
        let drag = ModuleDragState()

        // SwiftUI also asks for a drag item right after a drop, with no drag.
        _ = drag.begin(.nearestPark)
        #expect(drag.liftedID == nil)

        drag.enter(.nearestPark, in: preferences)
        #expect(drag.liftedID == .nearestPark)

        drag.clear()
        #expect(drag.liftedID == nil)
        _ = drag.begin(.lastWorkout)
        #expect(drag.liftedID == nil)
    }

    @Test("A drop or the end of the drag clears it; a stale end does not clear a newer drag")
    func dragEnds() {
        let drag = ModuleDragState()

        let first = drag.begin(.lastWorkout)
        drag.clear()
        #expect(drag.draggingID == nil)

        let second = drag.begin(.nextWorkout)
        drag.end(first)
        #expect(drag.draggingID == .nextWorkout)

        drag.end(second)
        #expect(drag.draggingID == nil)
    }

    @Test("The seeded environment never touches the real defaults")
    func seededEnvironmentIsIsolated() {
        let environment = AppEnvironment.seeded()
        let other = AppEnvironment.seeded()

        environment.modulePreferences.setEnabled(true, for: .streak)

        #expect(environment.modulePreferences.isEnabled(.streak))
        #expect(other.modulePreferences.isEnabled(.streak) == false)
    }
}
