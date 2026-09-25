//
//  WorkoutSessionTests.swift
//  cali-parkTests
//
//  Findable & reviewable workouts: `WorkoutSession` grouping, the workout
//  detail screen (load + delete), and "Zakończ" → summary in a quick workout.
//

import Foundation
import Testing
@testable import cali_park

// MARK: - Shared stubs

/// Loads fine but refuses to delete — verifies the detail screen's error path.
private final class UndeletableWorkoutLogStore: WorkoutLogStoring {
    struct SampleError: Error {}
    private var entries: [WorkoutLogEntry]

    init(initial: [WorkoutLogEntry]) {
        entries = initial
    }

    func load() -> [WorkoutLogEntry] { entries }
    func append(_ entry: WorkoutLogEntry) throws { entries.append(entry) }
    func delete(id: UUID) throws { throw SampleError() }
}

/// Rejects every write — a finish that never persisted must not show a summary.
private struct ReadOnlyWorkoutLogStore: WorkoutLogStoring {
    struct SampleError: Error {}
    func load() -> [WorkoutLogEntry] { [] }
    func append(_ entry: WorkoutLogEntry) throws { throw SampleError() }
    func delete(id: UUID) throws { throw SampleError() }
}

// MARK: - WorkoutSession grouping

struct WorkoutSessionGroupingTests {
    @Test
    func sessionEntriesShareTheSessionIdentifier() {
        let sessionID = UUID()
        let a = WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID,
                                date: Date(timeIntervalSince1970: 3_000),
                                sets: [LoggedSet(reps: 6), LoggedSet(reps: 8)],
                                sessionID: sessionID)
        let b = WorkoutLogEntry(exerciseID: ExerciseCatalog.plankID,
                                date: Date(timeIntervalSince1970: 3_000),
                                sets: [LoggedSet(reps: 1, durationSeconds: 30)],
                                sessionID: sessionID)

        let sessions = WorkoutSession.grouped(from: [a, b])

        #expect(sessions.count == 1)
        #expect(sessions[0].id == sessionID)
        #expect(sessions[0].entries == [a, b])
        #expect(sessions[0].isSession)
        #expect(sessions[0].totalSets == 3)
        #expect(sessions[0].totalReps == 14)
        #expect(sessions[0].totalSeconds == 30)
    }

    @Test
    func standaloneEntryIsItsOwnWorkout() {
        let entry = WorkoutLogEntry(exerciseID: ExerciseCatalog.pushUpsID, sets: [LoggedSet(reps: 10)])

        let sessions = WorkoutSession.grouped(from: [entry])

        #expect(sessions.map(\.id) == [entry.id])
        #expect(!sessions[0].isSession)
    }

    /// A one-exercise quick workout still carries a `sessionID`; the workout
    /// must be addressable by it so the post-finish summary can find it.
    @Test
    func singleExerciseQuickWorkoutIsAddressableBySessionID() {
        let sessionID = UUID()
        let entry = WorkoutLogEntry(exerciseID: ExerciseCatalog.dipsID,
                                    sets: [LoggedSet(reps: 8)],
                                    sessionID: sessionID)

        let session = WorkoutSession.session(withID: sessionID, in: [entry])

        #expect(session?.entries == [entry])
        #expect(session?.isSession == false)
    }

    @Test
    func sessionIsDatedByItsLatestEntry() {
        let sessionID = UUID()
        let early = WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID,
                                    date: Date(timeIntervalSince1970: 1_000),
                                    sets: [LoggedSet(reps: 6)],
                                    sessionID: sessionID)
        let late = WorkoutLogEntry(exerciseID: ExerciseCatalog.dipsID,
                                   date: Date(timeIntervalSince1970: 2_000),
                                   sets: [LoggedSet(reps: 8)],
                                   sessionID: sessionID)

        let session = WorkoutSession.grouped(from: [early, late]).first

        #expect(session?.date == Date(timeIntervalSince1970: 2_000))
    }

    @Test
    func latestPicksTheWorkoutHoldingTheNewestEntry() {
        let sessionID = UUID()
        let old = WorkoutLogEntry(exerciseID: ExerciseCatalog.squatsID,
                                  date: Date(timeIntervalSince1970: 1_000),
                                  sets: [LoggedSet(reps: 20)])
        let sessionA = WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID,
                                       date: Date(timeIntervalSince1970: 4_000),
                                       sets: [LoggedSet(reps: 6)],
                                       sessionID: sessionID)
        let sessionB = WorkoutLogEntry(exerciseID: ExerciseCatalog.pushUpsID,
                                       date: Date(timeIntervalSince1970: 4_000),
                                       sets: [LoggedSet(reps: 12)],
                                       sessionID: sessionID)

        let latest = WorkoutSession.latest(in: [old, sessionA, sessionB])

        #expect(latest?.id == sessionID)
        #expect(latest?.entries.count == 2)
    }

    @Test
    func emptyJournalHasNoWorkouts() {
        #expect(WorkoutSession.grouped(from: []).isEmpty)
        #expect(WorkoutSession.latest(in: []) == nil)
    }

    @Test
    func unknownIdentifierFindsNothing() {
        let entry = WorkoutLogEntry(exerciseID: ExerciseCatalog.pushUpsID, sets: [LoggedSet(reps: 10)])
        #expect(WorkoutSession.session(withID: UUID(), in: [entry]) == nil)
    }
}

// MARK: - Home + history share the model

@MainActor
struct WorkoutSessionSharingTests {
    @Test
    func homeLatestWorkoutMatchesTheHistoryTopSection() {
        let sessionID = UUID()
        let entries = [
            WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID,
                            date: Date(timeIntervalSince1970: 3_000),
                            sets: [LoggedSet(reps: 6)],
                            sessionID: sessionID),
            WorkoutLogEntry(exerciseID: ExerciseCatalog.dipsID,
                            date: Date(timeIntervalSince1970: 3_000),
                            sets: [LoggedSet(reps: 8)],
                            sessionID: sessionID),
            WorkoutLogEntry(exerciseID: ExerciseCatalog.squatsID,
                            date: Date(timeIntervalSince1970: 1_000),
                            sets: [LoggedSet(reps: 20)])
        ]
        let store = InMemoryWorkoutLogStore(initial: entries)
        let dashboard = HomeDashboardViewModel(store: store, planStore: InMemoryWorkoutPlanStore())
        let history = WorkoutHistoryViewModel(store: store)

        #expect(dashboard.latestWorkout?.id == sessionID)
        #expect(dashboard.latestWorkout == history.sections.first)
    }
}

// MARK: - WorkoutSessionDetailViewModel

@MainActor
struct WorkoutSessionDetailViewModelTests {
    @Test
    func loadsTheWorkoutInSavedOrder() {
        let sessionID = UUID()
        let first = WorkoutLogEntry(exerciseID: ExerciseCatalog.pushUpsID, sets: [LoggedSet(reps: 15)], sessionID: sessionID)
        let second = WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID, sets: [LoggedSet(reps: 6)], sessionID: sessionID)
        let unrelated = WorkoutLogEntry(exerciseID: ExerciseCatalog.squatsID, sets: [LoggedSet(reps: 20)])
        let store = InMemoryWorkoutLogStore(initial: [first, unrelated, second])

        let viewModel = WorkoutSessionDetailViewModel(sessionID: sessionID, store: store)

        #expect(viewModel.session?.entries == [first, second])
        #expect(viewModel.exercise(for: first)?.id == ExerciseCatalog.pushUpsID)
    }

    @Test
    func deleteRemovesEveryEntryOfTheWorkoutOnly() {
        let sessionID = UUID()
        let a = WorkoutLogEntry(exerciseID: ExerciseCatalog.pushUpsID, sets: [LoggedSet(reps: 15)], sessionID: sessionID)
        let b = WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID, sets: [LoggedSet(reps: 6)], sessionID: sessionID)
        let keep = WorkoutLogEntry(exerciseID: ExerciseCatalog.squatsID, sets: [LoggedSet(reps: 20)])
        let store = InMemoryWorkoutLogStore(initial: [a, b, keep])
        let viewModel = WorkoutSessionDetailViewModel(sessionID: sessionID, store: store)

        viewModel.delete()

        #expect(store.load() == [keep])
        #expect(viewModel.session == nil)
        #expect(viewModel.didDelete)
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func deleteFailureSurfacesErrorAndKeepsTheWorkout() {
        let entry = WorkoutLogEntry(exerciseID: ExerciseCatalog.pushUpsID, sets: [LoggedSet(reps: 15)])
        let viewModel = WorkoutSessionDetailViewModel(
            sessionID: entry.id,
            store: UndeletableWorkoutLogStore(initial: [entry])
        )

        viewModel.delete()

        #expect(viewModel.errorMessage != nil)
        #expect(!viewModel.didDelete)
        #expect(viewModel.session?.entries == [entry])
    }

    @Test
    func workoutDeletedElsewhereReadsAsGone() throws {
        let entry = WorkoutLogEntry(exerciseID: ExerciseCatalog.pushUpsID, sets: [LoggedSet(reps: 15)])
        let store = InMemoryWorkoutLogStore(initial: [entry])
        let viewModel = WorkoutSessionDetailViewModel(sessionID: entry.id, store: store)

        try store.delete(id: entry.id)
        viewModel.reload()

        #expect(viewModel.session == nil)
    }
}

// MARK: - Quick workout: "Zakończ" → summary

@MainActor
struct QuickWorkoutSummaryTests {
    private func sets(_ reps: Int...) -> [LoggedSet] {
        reps.map { LoggedSet(reps: $0) }
    }

    @Test
    func noSummaryBeforeFinishing() {
        let viewModel = QuickWorkoutViewModel(store: InMemoryWorkoutLogStore())
        viewModel.addExercise(ExerciseCatalog.all[0], sets: sets(6))

        #expect(viewModel.savedSessionID == nil)
    }

    @Test
    func finishExposesTheSavedSessionForTheSummary() throws {
        let store = InMemoryWorkoutLogStore()
        let viewModel = QuickWorkoutViewModel(store: store)
        let pushUps = try #require(ExerciseCatalog.exercise(withID: ExerciseCatalog.pushUpsID))
        let diamond = try #require(ExerciseCatalog.exercise(withID: ExerciseCatalog.diamondPushUpsID))
        viewModel.addExercise(pushUps, sets: sets(15, 12))
        viewModel.addExercise(diamond, sets: sets(8, 8, 6))

        viewModel.finish()

        let savedID = try #require(viewModel.savedSessionID)
        #expect(Set(store.load().compactMap(\.sessionID)) == [savedID])

        let summary = viewModel.makeSummaryViewModel()
        let session = try #require(summary.session)
        #expect(session.id == savedID)
        #expect(session.entries.map(\.exerciseID) == [pushUps.id, diamond.id])
        #expect(session.totalSets == 5)
        #expect(session.totalReps == 49)
    }

    @Test
    func singleExerciseWorkoutStillHasASummary() throws {
        let viewModel = QuickWorkoutViewModel(store: InMemoryWorkoutLogStore())
        viewModel.addExercise(ExerciseCatalog.all[0], sets: sets(6, 6, 8))

        viewModel.finish()

        let session = try #require(viewModel.makeSummaryViewModel().session)
        #expect(session.entries.count == 1)
        #expect(session.totalReps == 20)
    }

    @Test
    func failedFinishShowsNoSummary() {
        let viewModel = QuickWorkoutViewModel(store: ReadOnlyWorkoutLogStore())
        viewModel.addExercise(ExerciseCatalog.all[0], sets: sets(6))

        viewModel.finish()

        #expect(viewModel.savedSessionID == nil)
        #expect(viewModel.errorMessage != nil)
    }
}
