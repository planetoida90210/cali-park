//
//  SetSecondsTests.swift
//  cali-parkTests
//
//  Sprint SK2 — seconds in the journal: timed sets (LoggedSet.durationSeconds),
//  Codable back-compat, honest reps/seconds totals, and Polish formatting.
//

import Foundation
import Testing
@testable import cali_park

// MARK: - LoggedSet: measurement-aware construction

struct LoggedSetMeasurementTests {
    @Test
    func repsValueBuildsARepSet() {
        let set = LoggedSet(value: 8, measurement: .reps)
        #expect(set.reps == 8)
        #expect(set.durationSeconds == nil)
        #expect(!set.isTimed)
    }

    @Test
    func secondsValueBuildsATimedSet() {
        let set = LoggedSet(value: 20, measurement: .seconds)
        // reps stays at 1 as a technical marker that one hold occurred.
        #expect(set.reps == 1)
        #expect(set.durationSeconds == 20)
        #expect(set.isTimed)
    }

    @Test(arguments: [
        (LoggedSet(value: 8, measurement: .reps), ExerciseMeasurement.reps, 8),
        (LoggedSet(value: 20, measurement: .seconds), ExerciseMeasurement.seconds, 20)
    ])
    func padValueReturnsTheEditableUnit(set: LoggedSet, measurement: ExerciseMeasurement, expected: Int) {
        #expect(set.padValue(for: measurement) == expected)
    }
}

// MARK: - LoggedSet: Codable backward compatibility

struct LoggedSetCodableTests {
    @Test
    func durationSecondsRoundtrips() throws {
        let set = LoggedSet(reps: 1, durationSeconds: 20)
        let data = try JSONEncoder().encode(set)
        let decoded = try JSONDecoder().decode(LoggedSet.self, from: data)
        #expect(decoded == set)
        #expect(decoded.durationSeconds == 20)
    }

    /// Sets saved before timed sets existed have no `durationSeconds` key and
    /// must still decode (to `nil`), so old logs stay valid.
    @Test
    func legacyJSONWithoutDurationDecodesToNil() throws {
        let json = #"{ "reps": 6 }"#
        let decoded = try JSONDecoder().decode(LoggedSet.self, from: Data(json.utf8))
        #expect(decoded.reps == 6)
        #expect(decoded.durationSeconds == nil)
        #expect(!decoded.isTimed)
    }
}

// MARK: - WorkoutLogEntry: honest reps/seconds split

struct WorkoutLogEntryTotalsTests {
    private func entry(_ sets: [LoggedSet]) -> WorkoutLogEntry {
        WorkoutLogEntry(exerciseID: ExerciseCatalog.frontLeverID, sets: sets)
    }

    @Test
    func repEntryCountsRepsOnly() {
        let e = entry([LoggedSet(reps: 6), LoggedSet(reps: 6), LoggedSet(reps: 8)])
        #expect(e.totalReps == 20)
        #expect(e.totalSeconds == 0)
        #expect(!e.isTimed)
    }

    @Test
    func timedEntryCountsSecondsOnly() {
        let e = entry([
            LoggedSet(value: 20, measurement: .seconds),
            LoggedSet(value: 20, measurement: .seconds),
            LoggedSet(value: 20, measurement: .seconds)
        ])
        // Timed holds never leak into the rep total (no apples with oranges).
        #expect(e.totalReps == 0)
        #expect(e.totalSeconds == 60)
        #expect(e.isTimed)
    }
}

// MARK: - SetLogFormat

struct SetLogFormatTests {
    private func reps(_ values: Int...) -> [LoggedSet] {
        values.map { LoggedSet(value: $0, measurement: .reps) }
    }

    private func holds(_ values: Int...) -> [LoggedSet] {
        values.map { LoggedSet(value: $0, measurement: .seconds) }
    }

    @Test
    func breakdownJoinsReps() {
        #expect(SetLogFormat.breakdown(of: reps(6, 6, 8)) == "6 + 6 + 8")
    }

    @Test
    func breakdownCollapsesEqualHolds() {
        #expect(SetLogFormat.breakdown(of: holds(20, 20, 20)) == "3 × 20 s")
        #expect(SetLogFormat.breakdown(of: holds(15, 15, 15)) == "3 × 15 s")
    }

    @Test
    func breakdownListsVariedHolds() {
        #expect(SetLogFormat.breakdown(of: holds(20, 15, 20)) == "20 + 15 + 20 s")
    }

    @Test
    func breakdownOfEmptySetsIsEmpty() {
        #expect(SetLogFormat.breakdown(of: []).isEmpty)
    }

    @Test
    func totalReadsRepsOrSeconds() {
        #expect(SetLogFormat.total(of: reps(6, 6, 8)) == "20 powtórzeń")
        #expect(SetLogFormat.total(of: holds(20, 20, 20)) == "60 s")
    }

    @Test(arguments: [
        (40, 0, "40 powtórzeń"),
        (0, 60, "60 s"),
        (40, 60, "40 powtórzeń · 60 s"),
        (0, 0, "0 powtórzeń")
    ])
    func totalsListsOnlyPresentMeasures(reps: Int, seconds: Int, expected: String) {
        #expect(SetLogFormat.totals(reps: reps, seconds: seconds) == expected)
    }

    @Test
    func spokenBreakdownReadsEqualHoldsNaturally() {
        #expect(SetLogFormat.spokenBreakdown(of: holds(20, 20, 20)) == "3 serie po 20 sekund")
    }
}

// MARK: - PolishPlural.seconds

struct PolishPluralSecondsTests {
    @Test(arguments: [
        (1, "1 sekunda"),
        (2, "2 sekundy"),
        (3, "3 sekundy"),
        (5, "5 sekund"),
        (12, "12 sekund"),   // teens exception
        (20, "20 sekund"),
        (22, "22 sekundy"),
        (0, "0 sekund")
    ])
    func secondsForms(count: Int, expected: String) {
        #expect(PolishPlural.seconds(count) == expected)
    }
}

// MARK: - Logging a timed exercise from the SetPad

@MainActor
struct TimedWorkoutLogViewModelTests {
    @Test
    func savingATimedExerciseStoresSecondsNotReps() throws {
        let frontLever = try #require(ExerciseCatalog.exercise(withID: ExerciseCatalog.frontLeverID))
        #expect(frontLever.measurement == .seconds)

        let store = InMemoryWorkoutLogStore()
        let viewModel = WorkoutLogViewModel(exercise: frontLever, store: store)

        // Log "3 × 15 s" (the SK2 acceptance example) via the pad.
        viewModel.input.appendDigit(1); viewModel.input.appendDigit(5); viewModel.input.commitSet()
        viewModel.input.appendDigit(1); viewModel.input.appendDigit(5); viewModel.input.commitSet()
        viewModel.input.appendDigit(1); viewModel.input.appendDigit(5)
        viewModel.save()

        let entry = try #require(store.load().first)
        #expect(entry.sets.allSatisfy(\.isTimed))
        #expect(entry.sets.map(\.durationSeconds) == [15, 15, 15])
        #expect(entry.totalSeconds == 45)
        #expect(entry.totalReps == 0)
        #expect(SetLogFormat.breakdown(of: entry.sets) == "3 × 15 s")
    }
}
