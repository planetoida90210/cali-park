//
//  SetPadTests.swift
//  cali-parkTests
//
//  Sprint 3 — SetPad input logic, workout log view models, Polish plurals.
//

import Foundation
import Testing
@testable import cali_park

// MARK: - Key sequences

/// One SetPad key press, so sequences read like the real interaction.
private enum Key {
    case digit(Int)
    case plus
    case backspace
    case clear
}

private func run(_ keys: [Key]) -> SetPadInput {
    var input = SetPadInput()
    for key in keys {
        switch key {
        case .digit(let digit): input.appendDigit(digit)
        case .plus: input.commitSet()
        case .backspace: input.deleteBackward()
        case .clear: input.clear()
        }
    }
    return input
}

struct SetPadInputTests {
    @Test(arguments: [
        // (sequence, committed sets, pending entry)
        ([Key.digit(6), .plus, .digit(6), .plus, .digit(8)], [6, 6], "8"),
        // the trailing 8 has no `+` yet — still counts when saving
        ([.digit(1), .digit(2), .plus], [12], ""),
        // `+` with an empty entry is blocked
        ([.plus, .digit(5), .plus, .plus], [5], ""),
        // `⌫` deletes a digit first…
        ([.digit(1), .digit(2), .backspace], [], "1"),
        // …and with an empty entry it undoes the last committed set
        ([.digit(6), .plus, .digit(8), .plus, .backspace], [6], ""),
        // `⌫` on a completely empty pad is a no-op
        ([.backspace], [], ""),
        // `C` clears everything
        ([.digit(6), .plus, .digit(8), .clear], [], ""),
        // entry is capped at 3 digits
        ([.digit(9), .digit(9), .digit(9), .digit(9)], [], "999"),
        // leading zero is ignored (no 0-rep sets), but 10 works
        ([.digit(0)], [], ""),
        ([.digit(1), .digit(0), .plus], [10], "")
    ])
    func keySequences(keys: [Key], committed: [Int], entry: String) {
        let input = run(keys)
        #expect(input.committedSets == committed)
        #expect(input.currentEntry == entry)
    }

    @Test
    func savingIncludesThePendingEntry() {
        let input = run([.digit(6), .plus, .digit(6), .plus, .digit(8)])
        #expect(input.setsForSaving == [6, 6, 8])
        #expect(input.totalReps == 20)
        #expect(input.canSave)
    }

    @Test
    func emptyPadCannotSaveOrCommit() {
        let input = SetPadInput()
        #expect(!input.canSave)
        #expect(!input.canCommit)
        #expect(input.displayText == "0")
    }

    @Test
    func displayTextJoinsSetsWithPlus() {
        let input = run([.digit(6), .plus, .digit(6), .plus, .digit(8)])
        #expect(input.displayText == "6 + 6 + 8")
    }
}

// MARK: - WorkoutLogViewModel

/// Always fails — verifies error surfacing (pattern: `FailingReviewsService`).
private struct FailingWorkoutLogStore: WorkoutLogStoring {
    struct SampleError: Error {}
    func load() -> [WorkoutLogEntry] { [] }
    func append(_ entry: WorkoutLogEntry) throws { throw SampleError() }
    func delete(id: UUID) throws { throw SampleError() }
}

@MainActor
struct WorkoutLogViewModelTests {
    @Test
    func savePersistsCommittedAndPendingSets() throws {
        let store = InMemoryWorkoutLogStore()
        let viewModel = WorkoutLogViewModel(exercise: ExerciseCatalog.all[0], store: store)

        viewModel.input.appendDigit(6)
        viewModel.input.commitSet()
        viewModel.input.appendDigit(8)
        viewModel.save()

        let entry = try #require(store.load().first)
        #expect(entry.exerciseID == ExerciseCatalog.all[0].id)
        #expect(entry.sets.map(\.reps) == [6, 8])
        #expect(viewModel.didSave)
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func saveFailureSurfacesErrorAndDoesNotDismiss() {
        let viewModel = WorkoutLogViewModel(exercise: ExerciseCatalog.all[0],
                                            store: FailingWorkoutLogStore())
        viewModel.input.appendDigit(6)
        viewModel.save()

        #expect(viewModel.errorMessage != nil)
        #expect(!viewModel.didSave)
    }

    @Test
    func saveWithEmptyInputIsANoOp() {
        let store = InMemoryWorkoutLogStore()
        let viewModel = WorkoutLogViewModel(exercise: ExerciseCatalog.all[0], store: store)
        viewModel.save()

        #expect(store.load().isEmpty)
        #expect(!viewModel.didSave)
    }
}

// MARK: - WorkoutHistoryViewModel

@MainActor
struct WorkoutHistoryViewModelTests {
    @Test
    func entriesAreSortedNewestFirst() {
        let old = WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID,
                                  date: Date(timeIntervalSince1970: 1_000),
                                  sets: [LoggedSet(reps: 5)])
        let new = WorkoutLogEntry(exerciseID: ExerciseCatalog.pushUpsID,
                                  date: Date(timeIntervalSince1970: 2_000),
                                  sets: [LoggedSet(reps: 10)])
        let viewModel = WorkoutHistoryViewModel(store: InMemoryWorkoutLogStore(initial: [old, new]))

        #expect(viewModel.entries.map(\.id) == [new.id, old.id])
    }

    @Test
    func deleteRemovesEntryFromStoreAndList() {
        let entry = WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID,
                                    sets: [LoggedSet(reps: 5)])
        let store = InMemoryWorkoutLogStore(initial: [entry])
        let viewModel = WorkoutHistoryViewModel(store: store)

        viewModel.delete(entry)

        #expect(viewModel.entries.isEmpty)
        #expect(store.load().isEmpty)
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func deleteFailureSurfacesError() {
        let viewModel = WorkoutHistoryViewModel(store: FailingWorkoutLogStore())
        let entry = WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID,
                                    sets: [LoggedSet(reps: 5)])

        viewModel.delete(entry)

        #expect(viewModel.errorMessage != nil)
    }
}

// MARK: - PolishPlural

struct PolishPluralTests {
    @Test(arguments: [
        (1, "1 seria"),
        (2, "2 serie"),
        (4, "4 serie"),
        (5, "5 serii"),
        (11, "11 serii"),
        (12, "12 serii"),   // teens exception
        (14, "14 serii"),
        (22, "22 serie"),   // …but 22 goes back to "serie"
        (25, "25 serii"),
        (0, "0 serii")
    ])
    func setsForms(count: Int, expected: String) {
        #expect(PolishPlural.sets(count) == expected)
    }

    @Test(arguments: [
        (1, "1 powtórzenie"),
        (3, "3 powtórzenia"),
        (5, "5 powtórzeń"),
        (13, "13 powtórzeń"),
        (23, "23 powtórzenia"),
        (100, "100 powtórzeń")
    ])
    func repsForms(count: Int, expected: String) {
        #expect(PolishPlural.reps(count) == expected)
    }
}
