//
//  TrainingJournalTests.swift
//  cali-parkTests
//
//  Foundation step F2: one training journal, one progress snapshot per
//  revision, one reward center for the whole app, plus the scoring fixes that
//  ride on it (A-5 per-session scoring, A-8 holds in seconds, A-12 the rung
//  sheet reading live progress).
//

import Foundation
import Testing

@testable import cali_park

// MARK: - Fixtures

private enum JournalFixture {
    static let day = Date(timeIntervalSince1970: 1_790_000_000)

    static func pullUps(_ reps: [Int], session: UUID? = nil, date: Date = day) -> WorkoutLogEntry {
        WorkoutLogEntry(
            exerciseID: ExerciseCatalog.pullUpsID, date: date,
            sets: reps.map { LoggedSet(reps: $0) }, sessionID: session)
    }

    static func dips(_ reps: [Int], session: UUID? = nil, date: Date = day) -> WorkoutLogEntry {
        WorkoutLogEntry(
            exerciseID: ExerciseCatalog.dipsID, date: date,
            sets: reps.map { LoggedSet(reps: $0) }, sessionID: session)
    }

    static var pullUpStep: ProgressionStep {
        ProgressionCatalog.path(withID: .pullUp)!.steps.first { $0.exerciseID == ExerciseCatalog.pullUpsID }!
    }

    static var plankStep: ProgressionStep {
        ProgressionCatalog.path(withID: .core)!.steps.first { $0.exerciseID == ExerciseCatalog.plankID }!
    }
}

/// Fails to load until `isReadable` is set, then behaves like memory.
private final class FlakyJournalStore: WorkoutLogStoring {
    struct Unreadable: Error {}
    var isReadable = false
    private var entries: [WorkoutLogEntry]

    init(initial: [WorkoutLogEntry]) { entries = initial }

    func load() throws -> [WorkoutLogEntry] {
        guard isReadable else { throw Unreadable() }
        return entries
    }
    func append(_ entry: WorkoutLogEntry) throws { entries.append(entry) }
    func delete(id: UUID) throws { entries.removeAll { $0.id == id } }
}

// MARK: - TrainingJournal

@MainActor
@Suite("TrainingJournal is the one write path for workouts", .temporaryDirectories)
struct TrainingJournalTests {
    @Test
    func loggingAppendsInSavedOrderAndBumpsTheRevision() async throws {
        let store = InMemoryWorkoutLogStore()
        let journal = TrainingJournal(store: store)
        let start = journal.revision
        let older = JournalFixture.pullUps([5], date: JournalFixture.day)
        let newer = JournalFixture.dips([8], date: JournalFixture.day + 60)

        try await journal.log(newer)
        try await journal.log(older)

        #expect(journal.entries == [newer, older])
        #expect(journal.newestFirst == [newer, older])
        #expect(journal.revision == start + 2)
        #expect(store.load() == [newer, older])
    }

    @Test
    func aSessionIsSavedInOneWriteAndOneRevision() async throws {
        let store = InMemoryWorkoutLogStore()
        let journal = TrainingJournal(store: store)
        let start = journal.revision
        let session = UUID()

        try await journal.logSession([
            JournalFixture.pullUps([8], session: session),
            JournalFixture.dips([10], session: session)
        ])

        #expect(journal.entries.count == 2)
        #expect(journal.revision == start + 1)
        #expect(store.load().count == 2)
    }

    @Test
    func deletingAWholeWorkoutIsOneWrite() async throws {
        let session = UUID()
        let a = JournalFixture.pullUps([8], session: session)
        let b = JournalFixture.dips([10], session: session)
        let keep = JournalFixture.pullUps([5])
        let store = SpyWorkoutLogStore(initial: [a, b, keep])
        let journal = TrainingJournal(store: store)
        let start = journal.revision

        try await journal.delete(ids: [a.id, b.id])

        #expect(store.writes == [.delete([a.id, b.id])])
        #expect(journal.entries == [keep])
        #expect(journal.revision == start + 1)
    }

    @Test
    func deletingAWholeWorkoutFromTheFileIsAllOrNothing() async throws {
        let directory = try TemporaryDirectory.make("TrainingJournalTests")
        let session = UUID()
        let a = JournalFixture.pullUps([8], session: session)
        let b = JournalFixture.dips([10], session: session)
        let keep = JournalFixture.pullUps([5])
        let file = FileWorkoutLogStore(directory: directory)
        try await file.append(contentsOf: [a, b, keep])
        let journal = TrainingJournal(store: file)

        try await journal.delete(ids: [a.id, b.id])

        #expect(try FileWorkoutLogStore(directory: directory).load() == [keep])
    }

    @Test
    func anUnreadableJournalIsAFailureNotAnEmptyJournal() async {
        let journal = TrainingJournal(store: UnreadableWorkoutLogStore())

        #expect(journal.hasLoadFailure)
        #expect(journal.loadFailure?.message == StoreLoadFailure.message)
        #expect(journal.entries.isEmpty)
        await #expect(throws: UnreadableWorkoutLogStore.Unreadable.self) { try await journal.log(JournalFixture.pullUps([5])) }
    }

    @Test
    func aFailedLoadIsRetriedAndThenReadsTheSavedEntries() {
        let saved = JournalFixture.pullUps([5])
        let store = FlakyJournalStore(initial: [saved])
        let journal = TrainingJournal(store: store)
        #expect(journal.hasLoadFailure)

        store.isReadable = true
        journal.reloadIfFailed()

        #expect(journal.hasLoadFailure == false)
        #expect(journal.entries == [saved])
    }

    @Test
    func aWriteAfterAFailedLoadReReadsInsteadOfGuessing() async throws {
        let saved = JournalFixture.pullUps([5])
        let store = FlakyJournalStore(initial: [saved])
        let journal = TrainingJournal(store: store)
        store.isReadable = true // the next read works, the journal hasn't noticed

        let new = JournalFixture.dips([8])
        try await journal.log(new)

        #expect(journal.entries == [saved, new])
    }

    @Test
    func screensSeeEachOthersWritesWithoutReloading() async throws {
        let journal = TrainingJournal(store: InMemoryWorkoutLogStore())
        let history = WorkoutHistoryViewModel(journal: journal)
        let setPad = WorkoutLogViewModel(
            exercise: try #require(ExerciseCatalog.exercise(withID: ExerciseCatalog.pullUpsID)),
            journal: journal)

        setPad.input.appendDigit(7)
        await setPad.save()

        #expect(history.entries.count == 1)
        #expect(history.entries.first?.sets == [LoggedSet(reps: 7)])
    }
}

// MARK: - ProgressService

@MainActor
@Suite("Progress is computed once per journal revision and placement change")
struct ProgressServiceTests {
    @Test
    func readingTheSnapshotRepeatedlyComputesItOnce() {
        let stack = TrainingStack(logStore: InMemoryWorkoutLogStore(initial: [JournalFixture.pullUps([8, 8, 8])]))
        let computed = stack.progress.computationCount

        let skills = stack.skillPaths()
        let ladder = stack.skillPaths()
        _ = skills.summaries
        _ = skills.level
        _ = ladder.badges
        _ = ladder.rungProgress(for: JournalFixture.pullUpStep)
        _ = stack.progress.snapshot

        #expect(stack.progress.computationCount == computed)
    }

    @Test
    func aNewRevisionIsComputedOnceForEveryScreen() async throws {
        let logStore = InMemoryWorkoutLogStore()
        let journal = TrainingJournal(store: logStore)
        let clock = { TestDate.reference }
        let progress = ProgressService(
            journal: journal, placementStore: InMemorySkillPlacementStore(),
            calendar: TestCalendar.utc, clock: clock)
        let rewards = RewardCenter(progress: progress, store: InMemorySkillProgressStore(), goals: nil)
        let planService = WorkoutPlanService.testing(InMemoryWorkoutPlanStore())
        let home = HomeDashboardViewModel(
            journal: journal,
            planService: planService,
            progress: progress,
            goals: WeeklyGoalService(
                journal: journal, store: InMemoryWeeklyGoalStore(),
                planService: planService,
                calendar: TestCalendar.utc, clock: clock),
            defaults: .throwaway(),
            calendar: TestCalendar.utc,
            clock: clock)
        let skills = SkillPathsViewModel(progress: progress)
        let before = progress.computationCount

        try await journal.log(JournalFixture.pullUps([8, 8, 8]))
        await home.settle()
        _ = rewards.currentCelebration
        _ = home.achievementsSummary
        _ = home.progressionHint
        _ = skills.summaries
        _ = skills.level

        #expect(progress.computationCount == before + 1)
        #expect(skills.summary(for: .pullUp)?.state.conqueredRungCount == 6)
        #expect(home.achievementsSummary.level == skills.level.level)
    }

    @Test
    func aPlacementChangeRecomputesOnlyWhenItChanged() async throws {
        let placementStore = InMemorySkillPlacementStore()
        let stack = TrainingStack(placementStore: placementStore)
        _ = stack.progress.snapshot
        let before = stack.progress.computationCount

        stack.progress.reloadPlacement() // nothing saved: no change
        await stack.settle()
        #expect(stack.progress.computationCount == before)

        try placementStore.save(SkillPlacement(declaredStepByPath: [.pullUp: ExerciseCatalog.pullUpsID]))
        stack.progress.reloadPlacement()
        await stack.settle()
        #expect(stack.progress.snapshot.pathStates[.pullUp]?.currentRungIndex == 5)
        #expect(stack.progress.computationCount == before + 1)
    }

    @Test
    func savingACalibrationUpdatesSharedProgress() async {
        let environment = AppEnvironment.seeded()
        let skills = environment.makeSkillPathsViewModel()
        #expect(skills.needsCalibration)

        let calibration = environment.makePlacementCalibrationViewModel()
        let question = PlacementCalibration.repQuestions.first { $0.path == .pullUp }!
        calibration.select(.many, for: question)
        calibration.save()
        await environment.progressService.settle()

        #expect(calibration.didSave)
        #expect(skills.needsCalibration == false)
    }

    @Test
    func theSnapshotMatchesTheSingleQuestionFunctions() {
        let logs = [
            JournalFixture.pullUps([8, 8, 8]),
            JournalFixture.dips([6, 6, 6], date: JournalFixture.day + 86_400)
        ]
        let placement = SkillPlacement(declaredRungByPath: [.legs: 2])
        let calendar = TestCalendar.utc
        let today = JournalFixture.day + 2 * 86_400

        let snapshot = ProgressionEngine.snapshot(logs: logs, placement: placement, calendar: calendar, today: today)

        #expect(snapshot.pathStates == ProgressionEngine.pathStates(logs: logs, placement: placement))
        #expect(snapshot.logPathStates == ProgressionEngine.pathStates(logs: logs, placement: nil))
        #expect(snapshot.level == ProgressionEngine.playerLevel(for: logs))
        #expect(snapshot.badges == ProgressionEngine.earnedBadges(from: logs, calendar: calendar, today: today))
        #expect(snapshot.lastAdvancement == ProgressionEngine.lastAdvancement(from: logs))
        #expect(snapshot.hint == ProgressionEngine.mostActionableHint(logs: logs, placement: placement))
    }
}

// MARK: - RewardCenter

@MainActor
@Suite("An award is presented exactly once, whichever screen logged it")
struct RewardCenterTests {
    /// F-4 / D-V1: the ladder trains, the grid reappears. Before, each screen
    /// kept its own XP baseline and the grid toasted the same gain again.
    @Test
    func theSameGainIsToastedOnceAcrossTwoScreens() async throws {
        let stack = TrainingStack(logStore: InMemoryWorkoutLogStore(initial: [JournalFixture.pullUps([8, 8, 8])]))
        let grid = stack.skillPaths()
        let ladder = stack.skillPaths()

        // Logged from the rung sheet's SetPad.
        let setPad = WorkoutLogViewModel(
            exercise: try #require(ExerciseCatalog.exercise(withID: ExerciseCatalog.pullUpsID)),
            journal: stack.journal)
        setPad.input.appendDigit(5)
        await setPad.save()
        await stack.settle()

        let toast = try #require(stack.rewards.xpToastAmount)
        #expect(toast == 5 * ProgressionEngine.xpPerRep)
        stack.rewards.clearXPToast(toast) // shown by the overlay

        // Both screens reappear and refresh: nothing is announced again.
        ladder.load()
        grid.load()
        stack.rewards.refresh()
        #expect(stack.rewards.xpToastAmount == nil)
        #expect(stack.rewards.currentCelebration == nil)
    }

    /// D-13: the overlay timer of an older toast must not hide a newer one.
    @Test
    func clearingAnOlderToastKeepsTheNewerOne() async throws {
        let stack = TrainingStack(logStore: InMemoryWorkoutLogStore(initial: [JournalFixture.pullUps([8, 8, 8])]))
        let pullUps = try #require(ExerciseCatalog.exercise(withID: ExerciseCatalog.pullUpsID))
        // Each save is its own SetPad sheet: a saved pad ignores further taps (C-12).
        let setPad = WorkoutLogViewModel(exercise: pullUps, journal: stack.journal)
        setPad.input.appendDigit(5)
        await setPad.save()
        await stack.settle()
        let first = try #require(stack.rewards.xpToastAmount)

        let secondPad = WorkoutLogViewModel(exercise: pullUps, journal: stack.journal)
        secondPad.input.appendDigit(3)
        await secondPad.save()
        await stack.settle()
        let second = try #require(stack.rewards.xpToastAmount)
        #expect(second != first)

        stack.rewards.clearXPToast(first)
        #expect(stack.rewards.xpToastAmount == second)

        stack.rewards.clearXPToast(second)
        #expect(stack.rewards.xpToastAmount == nil)
    }

    /// A-10: after a celebration plays, popping back must not toast the same
    /// save (including the rung's bonus XP).
    @Test
    func noToastFollowsACelebrationForTheSameSave() async throws {
        let stack = TrainingStack()

        try await stack.journal.log(JournalFixture.pullUps([8, 8, 8]))
        await stack.settle()
        #expect(stack.rewards.currentCelebration == .rungs(0...5, on: .pullUp))
        #expect(stack.rewards.xpToastAmount == nil)

        #expect(stack.drainCelebrations() > 0)
        stack.skillPaths().load()
        stack.rewards.refresh()

        #expect(stack.rewards.xpToastAmount == nil)
        #expect(stack.rewards.currentCelebration == nil)
    }

    @Test
    func aWorkoutLoggedOnHomeCelebratesWithoutVisitingSkills() async throws {
        let environment = AppEnvironment.seeded()
        _ = environment.makeHomeDashboardViewModel()

        let session = environment.makeQuickWorkoutViewModel()
        session.addExercise(
            try #require(ExerciseCatalog.exercise(withID: ExerciseCatalog.pullUpsID)),
            sets: [LoggedSet(reps: 8), LoggedSet(reps: 8), LoggedSet(reps: 8)])
        await session.finish()
        await environment.progressService.settle()

        #expect(environment.rewardCenter.currentCelebration == .rungs(0...5, on: .pullUp))
    }

    /// Row 19 of the second visual pass: one save that clears six rungs
    /// showed six overlays in a row. Now it is one card, then the level-up.
    @Test
    func rungsClearedByOneSaveShareOneCard() async throws {
        let progressStore = InMemorySkillProgressStore()
        let stack = TrainingStack(progressStore: progressStore)

        try await stack.journal.log(JournalFixture.pullUps([8, 8, 8]))
        await stack.settle()

        let card = try #require(stack.rewards.current)
        #expect(stack.rewards.currentCelebration == .rungs(0...5, on: .pullUp))
        #expect(card.presentation.eyebrow == "ZALICZONE SZCZEBLE")
        #expect(card.presentation.title == "6 nowych szczebli")
        #expect(card.presentation.subtitle == "Podciąganie")
        #expect(card.presentation.list.count == 6)
        #expect(card.presentation.xpNote == "+600 XP")
        #expect(card.hasNext) // the level-up follows

        // One dismissal marks every rung on the card as celebrated.
        stack.rewards.dismissCurrent()
        let record = try #require(progressStore.load())
        for index in 0...5 {
            #expect(record.hasCelebrated(try #require(RungReference(pathID: .pullUp, rungIndex: index))))
        }

        // The level-up keeps its own card, the last one.
        #expect(stack.rewards.currentCelebration == .single(.levelReached(2)))
        stack.rewards.dismissCurrent()
        #expect(stack.rewards.current == nil)
    }

    @Test
    func theCombinedCardReadsAsOneSentence() throws {
        let rungs =
            (0...1).compactMap { RungReference(pathID: .pullUp, rungIndex: $0) }
            + (0...2).compactMap { RungReference(pathID: .dip, rungIndex: $0) }
        let presentation = CelebrationPresentation.resolving(QueuedCelebration.rungs(rungs))

        #expect(presentation.title == "5 nowych szczebli")
        #expect(presentation.list.count == 5)
        #expect(presentation.xpNote == "+500 XP")
        #expect(presentation.symbolName == "checkmark.seal.fill") // two paths
        let pathNames = try #require(presentation.subtitle)
        #expect(
            presentation.accessibilityLabel
                == "5 nowych szczebli na ścieżkach \(pathNames): \(presentation.list.joined(separator: ", ")). +500 XP.")
    }

    @Test
    func aSingleRungKeepsItsOwnCard() async throws {
        // A 3 × 8 seeds the baseline; L-pull-ups then clear one more rung.
        let stack = TrainingStack(logStore: InMemoryWorkoutLogStore(initial: [JournalFixture.pullUps([8, 8, 8])]))

        try await stack.journal.log(
            WorkoutLogEntry(
                exerciseID: ExerciseCatalog.lPullUpsID, date: JournalFixture.day,
                sets: [LoggedSet(reps: 5), LoggedSet(reps: 5), LoggedSet(reps: 5)]))
        await stack.settle()

        let card = try #require(stack.rewards.current)
        #expect(card.presentation.eyebrow == "ZALICZONY SZCZEBEL")
        #expect(card.presentation.list.isEmpty)
    }

    @Test
    func rungsFromALaterSaveGetTheirOwnCard() async throws {
        let stack = TrainingStack()
        try await stack.journal.log(JournalFixture.pullUps([8, 8, 8]))
        await stack.settle()
        let first = try #require(stack.rewards.currentCelebration)

        // Saved again while the first card is still up: it stays, and the new
        // rungs queue behind it on a card of their own.
        try await stack.journal.log(JournalFixture.dips([10, 10, 10]))
        await stack.settle()
        #expect(stack.rewards.currentCelebration == first)

        var cards: [QueuedCelebration] = []
        while let current = stack.rewards.currentCelebration, cards.count < 10 {
            cards.append(current)
            stack.rewards.dismissCurrentCelebration()
        }
        #expect(cards.first == first)
        let dipCards = cards.filter { $0.events.contains { if case .rungConquered(let rung) = $0 { rung.pathID == .dip } else { false } } }
        #expect(dipCards.count == 1)
        #expect((dipCards.first?.events.count ?? 0) >= 2)
    }

    @Test
    func groupingJoinsRungsWaitingTogetherOnly() throws {
        let a = try #require(CelebrationEvent.rung(0, on: .pullUp))
        let b = try #require(CelebrationEvent.rung(1, on: .pullUp))
        let level = CelebrationEvent.levelReached(2)

        #expect(QueuedCelebration.grouping([]) == [])
        #expect(QueuedCelebration.grouping([a]) == [.single(a)])
        #expect(QueuedCelebration.grouping([a, level]) == [.single(a), .single(level)])
        #expect(QueuedCelebration.grouping([a, b, level]).map(\.events) == [[a, b], [level]])
        #expect(QueuedCelebration.grouping([level, .levelReached(3)]) == [.single(level), .single(.levelReached(3))])
    }

    @Test
    func onlyTheTopmostOverlayPresents() {
        let stack = TrainingStack()
        let root = UUID()
        let sheet = UUID()

        stack.rewards.register(presenter: root)
        #expect(stack.rewards.isPresenting(root))

        stack.rewards.register(presenter: sheet)
        #expect(stack.rewards.isPresenting(sheet))
        #expect(stack.rewards.isPresenting(root) == false)

        stack.rewards.unregister(presenter: sheet)
        #expect(stack.rewards.isPresenting(root))
    }

    @Test
    func rewardsWaitWhileTheJournalIsUnreadable() {
        let progressStore = InMemorySkillProgressStore()
        let stack = TrainingStack(logStore: UnreadableWorkoutLogStore(), progressStore: progressStore)

        #expect(stack.rewards.currentCelebration == nil)
        // No baseline from a journal that only looks empty.
        #expect(progressStore.load() == nil)
    }
}

// MARK: - A-5: per-session scoring

@Suite("A workout's entries for one exercise are scored together (A-5)")
struct PerSessionScoringTests {
    @Test
    func interleavedSupersetSetsCountAsOneSession() {
        let session = UUID()
        let logs = [
            JournalFixture.pullUps([8], session: session),
            JournalFixture.dips([10], session: session),
            JournalFixture.pullUps([8], session: session),
            JournalFixture.dips([10], session: session),
            JournalFixture.pullUps([8], session: session)
        ]

        let progress = ProgressionEngine.rungProgress(for: JournalFixture.pullUpStep, in: logs)

        #expect(progress.bestValue == 8)
        #expect(progress.isMet)
        #expect(ProgressionEngine.pathStates(logs: logs, placement: nil)[.pullUp]?.conqueredRungCount == 6)
    }

    @Test
    func separateStandaloneSavesStillDoNotAddUp() {
        let logs = [
            JournalFixture.pullUps([8]),
            JournalFixture.pullUps([8]),
            JournalFixture.pullUps([8])
        ]

        #expect(ProgressionEngine.rungProgress(for: JournalFixture.pullUpStep, in: logs).bestValue == 0)
    }

    @Test
    func twoWorkoutsAreNotMerged() {
        let logs = [
            JournalFixture.pullUps([8, 8], session: UUID()),
            JournalFixture.pullUps([8], session: UUID())
        ]

        #expect(ProgressionEngine.rungProgress(for: JournalFixture.pullUpStep, in: logs).bestValue == 0)
    }

    @MainActor
    @Test
    func addingTheSameExerciseTwiceInAQuickWorkoutAdvances() async throws {
        let stack = TrainingStack()
        let session = QuickWorkoutViewModel(journal: stack.journal, clock: { TestDate.reference })
        let pullUps = try #require(ExerciseCatalog.exercise(withID: ExerciseCatalog.pullUpsID))
        let dips = try #require(ExerciseCatalog.exercise(withID: ExerciseCatalog.dipsID))

        session.addExercise(pullUps, sets: [LoggedSet(reps: 8), LoggedSet(reps: 8)])
        session.addExercise(dips, sets: [LoggedSet(reps: 10)])
        session.addExercise(pullUps, sets: [LoggedSet(reps: 8)])
        await session.finish()
        await stack.settle()

        #expect(stack.journal.entries.count == 3)
        #expect(stack.skillPaths().summary(for: .pullUp)?.state.conqueredRungCount == 6)
        #expect(stack.rewards.currentCelebration == .rungs(0...5, on: .pullUp))
    }

    @Test
    func theFirstMetDateIsTheSessionDate() {
        let session = UUID()
        let workoutDay = JournalFixture.day + 3 * 86_400
        let logs = [
            JournalFixture.pullUps([8, 8], session: session, date: workoutDay),
            JournalFixture.pullUps([8], session: session, date: workoutDay)
        ]

        let last = ProgressionEngine.lastAdvancement(from: logs)

        #expect(last?.stepID == JournalFixture.pullUpStep.id)
    }
}

// MARK: - A-8: holds read in seconds

@Suite("Rep-type sets of a hold exercise are read as seconds (A-8)")
struct HoldSecondsTests {
    /// A plank saved before holds existed: three "reps" of 60.
    private static let legacyPlank = WorkoutLogEntry(
        exerciseID: ExerciseCatalog.plankID,
        date: JournalFixture.day,
        sets: [LoggedSet(reps: 60), LoggedSet(reps: 60), LoggedSet(reps: 60)]
    )

    @Test
    func aLegacyPlankMeetsTheHoldCriterion() {
        let progress = ProgressionEngine.rungProgress(for: JournalFixture.plankStep, in: [Self.legacyPlank])

        #expect(progress.bestValue == 60)
        #expect(progress.isMet)
    }

    @Test
    func aLegacyPlankEarnsHoldXPNotRepXP() {
        let xp = ProgressionEngine.experiencePoints(for: [Self.legacyPlank])

        // 180 s of holding plus the conquered plank rung; 1800 reps would be
        // 18 000 XP.
        #expect(xp == 180 * ProgressionEngine.xpPerHoldSecond + ProgressionEngine.xpPerConqueredRung)
    }

    @Test
    func aLegacyPlankDoesNotCountTowardTheRepBadge() {
        let planks = Array(repeating: Self.legacyPlank, count: 6) // 1080 "reps"

        #expect(ProgressionEngine.earnedBadges(from: planks).contains(.thousandReps) == false)
    }

    @Test
    func theStoredLogIsNotRewritten() {
        let scoring = ScoringLog([Self.legacyPlank])

        #expect(scoring.entries.first?.totalSeconds == 180)
        #expect(Self.legacyPlank.sets.allSatisfy { !$0.isTimed })
    }

    @Test
    func repExercisesKeepTheirReps() {
        let pullUps = JournalFixture.pullUps([8, 8, 8])

        #expect(ScoringLog.normalized(pullUps) == pullUps)
    }

    // MARK: Everywhere else (rest of A-8)

    @Test @MainActor
    func theJournalReadsLegacyHoldsAsSecondsAndLeavesTheFileAlone() {
        let store = InMemoryWorkoutLogStore(initial: [Self.legacyPlank, JournalFixture.pullUps([8])])
        let journal = TrainingJournal(store: store)

        let plank = journal.entries[0]
        #expect(plank.isTimed)
        #expect(plank.totalSeconds == 180)
        #expect(plank.totalReps == 0)
        #expect(journal.entries[1].sets == [LoggedSet(reps: 8)])
        #expect(store.load()[0].sets.allSatisfy { !$0.isTimed })
    }

    @Test @MainActor
    func historyAndHomeShowALegacyPlankInSeconds() {
        let journal = TrainingJournal(store: InMemoryWorkoutLogStore(initial: [Self.legacyPlank]))
        let session = WorkoutSession.latest(in: journal.newestFirst)

        #expect(session?.totalSeconds == 180)
        #expect(session?.totalReps == 0)
        #expect(MeasureFormat.total(of: journal.entries[0].sets) == MeasureFormat.amount(180, .seconds))
    }

    @Test
    func aSecondsVolumeGoalCountsLegacyHolds() {
        let goal = WeeklyGoal(
            metric: .exerciseVolume(
                exerciseID: ExerciseCatalog.plankID,
                measurement: .seconds, amount: 180))
        let week = WeeklyGoalEvaluator.week(containing: JournalFixture.day, calendar: TestCalendar.utc)
        let progress = WeeklyGoalEvaluator.progress(
            of: goal, in: week,
            entries: [Self.legacyPlank.inCatalogUnits], plans: [],
            calendar: TestCalendar.utc)
        #expect(progress.value == 180)
        #expect(progress.isMet)
    }
}

// MARK: - A-12: the rung sheet reads live progress

@MainActor
@Suite("The rung sheet shows fresh results after training (A-12, E-19)")
struct LiveRungProgressTests {
    @Test
    func aSetSavedFromTheSheetShowsUpWithoutClosingIt() async throws {
        let environment = AppEnvironment.seeded()
        let ladder = environment.makeSkillPathsViewModel()
        let step = JournalFixture.pullUpStep
        #expect(ladder.rungProgress(for: step).bestValue == 0)

        // "Trenuj" → SetPad → 3 × 6.
        let setPad = environment.makeWorkoutLogViewModel(exercise: try #require(ExerciseCatalog.exercise(withID: step.exerciseID)))
        for _ in 0..<3 {
            setPad.input.appendDigit(6)
            setPad.input.commitSet()
        }
        await setPad.save()
        await environment.progressService.settle()

        // The sheet reads progress through the same view model, no reload.
        #expect(ladder.rungProgress(for: step).bestValue == 6)
        #expect(MeasureFormat.best(ladder.rungProgress(for: step)) == "3 × 6".keptTogether)
    }
}

// MARK: - MeasureFormat

@Suite("MeasureFormat keeps the Polish copy")
struct MeasureFormatTests {
    @Test
    func valuesSetsAndSpokenForms() {
        #expect(MeasureFormat.amount(20, .reps) == "20 powtórzeń")
        #expect(MeasureFormat.amount(60, .seconds) == "60 s".keptTogether)
        #expect(MeasureFormat.sets(3, of: 8, .reps) == "3 × 8".keptTogether)
        #expect(MeasureFormat.sets(3, of: 20, .seconds) == "3 × 20 s".keptTogether)
        #expect(MeasureFormat.spokenSets(3, of: 8, .reps) == "3 serie po 8 powtórzeń")
        #expect(MeasureFormat.spokenSets(3, of: 20, .seconds) == "3 serie po 20 sekund")
    }

    @Test
    func aWorkoutSummaryLine() {
        let session = UUID()
        let workout = WorkoutSession.grouped(from: [
            JournalFixture.pullUps([8, 8], session: session),
            WorkoutLogEntry(
                exerciseID: ExerciseCatalog.plankID, date: JournalFixture.day,
                sets: [LoggedSet(reps: 1, durationSeconds: 30)], sessionID: session)
        ]).first!

        #expect(MeasureFormat.summary(of: workout) == "2 ćwiczenia · 16 powtórzeń · 30 s".keptTogether)
    }
}

// MARK: - One overlay queue: XP totals and weekly goals

@MainActor
@Suite("One overlay queue for rungs, levels and weekly goals")
struct RewardQueueTests {
    private typealias F = WeeklyGoalFixtures

    /// The whole chain as `AppEnvironment` wires it, on the weekly goal's
    /// fixed calendar and clock.
    @MainActor
    private struct Stack {
        let journal: TrainingJournal
        let progress: ProgressService
        let goals: WeeklyGoalService
        let rewards: RewardCenter

        init(entries: [WorkoutLogEntry], now: Date = F.day(3)) {
            journal = TrainingJournal(store: InMemoryWorkoutLogStore(initial: entries))
            progress = ProgressService(
                journal: journal, placementStore: InMemorySkillPlacementStore(),
                calendar: F.calendar, clock: { now })
            goals = WeeklyGoalService(
                journal: journal, store: InMemoryWeeklyGoalStore(),
                planService: .testing(InMemoryWorkoutPlanStore()),
                calendar: F.calendar, clock: { now })
            rewards = RewardCenter(progress: progress, store: InMemorySkillProgressStore(), goals: goals)
        }

        func settle() async {
            await progress.settle()
        }
    }

    @Test
    func theLastRungOverlayShowsTheBatchTotal() async throws {
        let stack = Stack(entries: [])
        let before = stack.progress.snapshot.level.totalXP

        try await stack.journal.log(F.entry(at: F.day(1), sets: Array(repeating: LoggedSet(reps: 8), count: 3)))
        await stack.settle()
        let gained = stack.progress.snapshot.level.totalXP - before

        var overlays: [RewardPresentation] = []
        while let current = stack.rewards.current, overlays.count < 50 {
            overlays.append(current)
            stack.rewards.dismissCurrent()
        }
        // Six rungs on one card, then the level-up with the batch total.
        #expect(overlays.count == 2)
        let rungs = try #require(overlays.first)
        #expect(rungs.presentation.xpNote == "+600 XP")
        let last = try #require(overlays.last)
        #expect(last.presentation.xpNote?.hasSuffix("Razem +\(gained) XP") == true)
        #expect(last.hasNext == false)
        #expect(stack.rewards.xpToastAmount == nil) // no separate toast
    }

    @Test
    func aGoalMetByALogCelebratesWithoutAReload() async throws {
        let stack = Stack(entries: F.trained(week: 0, days: [0, 1]))
        #expect(stack.rewards.current == nil)

        // The third training day meets the default goal (3 days).
        try await stack.journal.log(F.entry(at: F.day(3)))
        await stack.settle()

        let goal = try #require(stack.rewards.current)
        #expect(goal.presentation.eyebrow == "CEL TYGODNIOWY WYKONANY")
        #expect(goal.presentation.xpNote == nil)

        stack.rewards.dismissCurrent()
        #expect(stack.rewards.current == nil)
    }

    @Test
    func rungsComeFirstThenTheGoal() async throws {
        let stack = Stack(entries: F.trained(week: 0, days: [0, 1]))

        try await stack.journal.log(F.entry(at: F.day(3), sets: Array(repeating: LoggedSet(reps: 8), count: 3)))
        await stack.settle()

        var eyebrows: [String] = []
        var lastSkillHasNext = false
        while let current = stack.rewards.current, eyebrows.count < 50 {
            if current.presentation.eyebrow != "CEL TYGODNIOWY WYKONANY" { lastSkillHasNext = current.hasNext }
            eyebrows.append(current.presentation.eyebrow)
            stack.rewards.dismissCurrent()
        }
        #expect(eyebrows.last == "CEL TYGODNIOWY WYKONANY")
        #expect(eyebrows.dropLast().allSatisfy { $0 != "CEL TYGODNIOWY WYKONANY" })
        #expect(eyebrows.count > 1)
        #expect(lastSkillHasNext) // "Dalej" leads on to the goal
    }
}
