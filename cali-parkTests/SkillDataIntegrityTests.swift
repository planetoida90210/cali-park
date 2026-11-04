//
//  SkillDataIntegrityTests.swift
//  cali-parkTests
//
//  Skills data integrity (audit A-1, A-2, A-4, A-6, C-5, C-6, C-7): rungs are
//  stored by step ID and old index files migrate to the same exercises,
//  re-calibration keeps the paths it did not touch, a lowered floor never
//  re-celebrates old rungs, and a celebration is recorded only once shown.
//

import Foundation
import Testing
@testable import cali_park

// MARK: - Fixtures

private enum IntegrityFixture {
    /// 2026-10-01T07:30:00Z
    static let day = StoreFixtures.october1

    /// A clean 3 × 8 of full pull-ups: conquers pull-up rungs 0…4.
    static func pullUps3x8() -> WorkoutLogEntry {
        WorkoutLogEntry(
            exerciseID: ExerciseCatalog.pullUpsID,
            date: day,
            sets: [LoggedSet(reps: 8), LoggedSet(reps: 8), LoggedSet(reps: 8)]
        )
    }

    static let pullUpRung = RungReference(pathID: .pullUp, stepID: ExerciseCatalog.pullUpsID)

    static func makeDirectory() throws -> URL {
        let directory = try TemporaryDirectory.make("SkillDataIntegrityTests")
        return directory
    }

    static func rungEvents(_ events: [CelebrationEvent]) -> [RungReference] {
        events.compactMap {
            if case let .rungConquered(rung) = $0 { return rung }
            return nil
        }
    }
}

/// An in-memory progress store that counts writes.
private final class CountingProgressStore: SkillProgressStoring {
    private(set) var progress: SkillProgress?
    private(set) var saveCount = 0

    func load() -> SkillProgress? { progress }

    func save(_ progress: SkillProgress) throws {
        saveCount += 1
        self.progress = progress
    }
}

/// A placement store whose saved file cannot be read.
private final class UnreadablePlacementStore: SkillPlacementStoring {
    struct ReadError: Error {}
    private(set) var saveAttempts = 0
    func load() throws -> SkillPlacement? { throw ReadError() }
    func save(_ placement: SkillPlacement) throws { saveAttempts += 1 }
}

// MARK: - Stable rung identity (A-6, C-5)

@Suite("Rungs are stored by step ID, and version 1 indices migrate", .temporaryDirectories)
struct StableRungIdentityTests {
    private typealias E = ExerciseCatalog

    /// The ladders as they were when indices were stored, written with the
    /// catalog's named constants. Pins every literal UUID in `LadderOrderV1`.
    @Test func frozenVersion1OrderNamesTheVersion1Ladders() {
        let expected: [ProgressionPathID: [UUID]] = [
            .pullUp: [E.deadHangID, E.scapularPullsID, E.negativePullUpsID, E.bandPullUpsID, E.pullUpsID, E.lPullUpsID, E.archerPullUpsID],
            .row: [E.inclineRowsID, E.australianPullUpsID, E.wideRowsID, E.archerRowsID, E.tuckFrontLeverRowsID],
            .pushUp: [E.wallPushUpsID, E.inclinePushUpsID, E.kneePushUpsID, E.pushUpsID, E.diamondPushUpsID, E.pseudoPlanchePushUpsID],
            .dip: [E.parallelBarSupportID, E.negativeDipsID, E.dipsID, E.ringDipsID],
            .legs: [E.assistedSquatsID, E.squatsID, E.lungesID, E.stepUpsID, E.assistedPistolSquatsID, E.pistolSquatsID],
            .core: [E.plankID, E.hangingKneeRaisesID, E.hangingLegRaisesID, E.toesToBarID],
            .muscleUp: [E.chestToBarPullUpsID, E.negativeMuscleUpsID, E.kippingMuscleUpsID, E.muscleUpID],
            .lSit: [E.footSupportedLSitID, E.oneLegLSitID, E.tuckLSitID, E.lSitID],
            .frontLever: [E.tuckFrontLeverID, E.advancedTuckFrontLeverID, E.straddleFrontLeverID, E.halfLayFrontLeverID, E.frontLeverID],
            .backLever: [E.germanHangID, E.skinTheCatID, E.tuckBackLeverID, E.advancedTuckBackLeverID,
                         E.straddleBackLeverID, E.halfLayBackLeverID, E.backLeverID],
            .planche: [E.frogStandID, E.tuckPlancheID, E.advancedTuckPlancheID, E.straddlePlancheID, E.plancheID],
            .humanFlag: [E.verticalFlagSupportID, E.tuckFlagID, E.straddleFlagID, E.humanFlagID],
            .handstand: [E.wallPlankID, E.wallHandstandHoldID, E.wallHandstandPushUpsID]
        ]
        #expect(LadderOrderV1.stepIDs == expected)
        #expect(Set(LadderOrderV1.stepIDs.keys) == Set(ProgressionPathID.allCases))
    }

    @Test func everyVersion1PlacementIndexMigratesToItsExercise() throws {
        let decoder = JSONFileFormat.decoder(forSchemaVersion: 1)
        for (path, stepIDs) in LadderOrderV1.stepIDs {
            for (index, stepID) in stepIDs.enumerated() {
                let json = #"{"declaredRungByPath":["\#(path.rawValue)",\#(index)],"ownedEquipment":[],"declaredAt":"2026-10-01T07:30:00Z"}"#
                let placement = try decoder.decode(SkillPlacement.self, from: Data(json.utf8))
                #expect(placement.declaredStepByPath == [path: stepID], "\(path) rung \(index)")
            }
        }
    }

    @Test func everyVersion1CelebratedIndexMigratesToItsExercise() throws {
        let decoder = JSONFileFormat.decoder(forSchemaVersion: 1)
        for (path, stepIDs) in LadderOrderV1.stepIDs {
            for (index, stepID) in stepIDs.enumerated() {
                let json = #"{"celebratedRungs":[{"pathID":"\#(path.rawValue)","rungIndex":\#(index)}],"celebratedLevel":3}"#
                let progress = try decoder.decode(SkillProgress.self, from: Data(json.utf8))
                #expect(progress.celebratedRungs == [RungReference(pathID: path, stepID: stepID)], "\(path) rung \(index)")
                #expect(progress.celebratedLevel == 3)
            }
        }
    }

    @Test func version1IndicesThatNeverExistedAreDropped() throws {
        let decoder = JSONFileFormat.decoder(forSchemaVersion: 1)
        let placementJSON = #"{"declaredRungByPath":["pullUp",99,"dip",2],"ownedEquipment":[],"declaredAt":"2026-10-01T07:30:00Z"}"#
        let placement = try decoder.decode(SkillPlacement.self, from: Data(placementJSON.utf8))
        #expect(placement.declaredStepByPath == [.dip: E.dipsID])

        let progressJSON = #"{"celebratedRungs":[{"pathID":"pullUp","rungIndex":-1},{"pathID":"dip","rungIndex":2}],"celebratedLevel":2}"#
        let progress = try decoder.decode(SkillProgress.self, from: Data(progressJSON.utf8))
        #expect(progress.celebratedRungs == [RungReference(pathID: .dip, stepID: E.dipsID)])
    }

    /// The golden files (bare legacy format, v1 indices) load as the same
    /// rungs: pull-up rung 3 is still band pull-ups, push-up 5 pseudo-planche.
    @Test func goldenLegacyFilesLoadAsTheSameRungs() throws {
        let directory = try IntegrityFixture.makeDirectory()
        let bundle = Bundle(for: CountingProgressStore.self)
        for (fixture, name) in [("skill-placement-legacy", "skill-placement.json"),
                                ("skill-progress-legacy", "skill-progress.json")] {
            let source = try #require(bundle.url(forResource: fixture, withExtension: "json"))
            try FileManager.default.copyItem(at: source, to: directory.appending(path: name))
        }

        let placement = try #require(try FileSkillPlacementStore(directory: directory).load())
        #expect(placement.declaredReference(for: .pullUp)?.step?.exerciseID == E.bandPullUpsID)
        #expect(placement.declaredReference(for: .pushUp)?.step?.exerciseID == E.pseudoPlanchePushUpsID)
        #expect(placement.declaredRung(for: .pullUp) == 4)
        #expect(placement.declaredRung(for: .pushUp) == 5)

        let progress = try #require(try FileSkillProgressStore(directory: directory).load())
        #expect(progress.celebratedRungs.compactMap(\.rungIndex).sorted() == [1, 4])
        #expect(progress.hasCelebrated(RungReference(pathID: .dip, stepID: E.negativeDipsID)))
    }

    @Test func savingAMigratedPlacementWritesStepIDsUnderVersion2() throws {
        let directory = try IntegrityFixture.makeDirectory()
        let url = directory.appending(path: "skill-placement.json")
        let v1 = #"{"schemaVersion":1,"payload":{"declaredRungByPath":["pullUp",4],"ownedEquipment":[],"declaredAt":"2026-10-01T07:30:00Z"}}"#
        try Data(v1.utf8).write(to: url)
        let store = FileSkillPlacementStore(directory: directory)

        let migrated = try #require(try store.load())
        #expect(migrated.declaredStepByPath == [.pullUp: E.pullUpsID])
        try store.save(migrated)

        let object = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        #expect(object["schemaVersion"] as? Int == 2)
        let payload = try #require(object["payload"] as? [String: Any])
        #expect(payload["declaredRungByPath"] == nil)
        #expect(payload["declaredStepByPath"] as? [String: String] == ["pullUp": E.pullUpsID.uuidString])
        #expect(try store.load() == migrated)
    }

    @Test func progressRoundTripsUnderVersion2() throws {
        let directory = try IntegrityFixture.makeDirectory()
        let store = FileSkillProgressStore(directory: directory)
        let progress = SkillProgress(celebratedRungs: [IntegrityFixture.pullUpRung], celebratedLevel: 2)

        try store.save(progress)

        let url = directory.appending(path: "skill-progress.json")
        let object = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        #expect(object["schemaVersion"] as? Int == 2)
        #expect(try store.load() == progress)
    }

    @Test func skillStoresRefuseAVersionNewerThan2() throws {
        let directory = try IntegrityFixture.makeDirectory()
        let text = #"{"schemaVersion":3,"payload":{}}"#
        let url = directory.appending(path: "skill-progress.json")
        try Data(text.utf8).write(to: url)
        let store = FileSkillProgressStore(directory: directory)

        #expect(throws: JSONFileStoreError.self) { try store.load() }
        #expect(throws: JSONFileStoreError.self) { try store.save(.empty) }
        #expect(try String(contentsOf: url, encoding: .utf8) == text)
    }

    @Test func storesThatStayOnVersion1RefuseVersion2() throws {
        let directory = try IntegrityFixture.makeDirectory()
        try Data(#"{"schemaVersion":2,"payload":[]}"#.utf8).write(to: directory.appending(path: "workout-log.json"))

        let error = #expect(throws: JSONFileStoreError.self) { try FileWorkoutLogStore(directory: directory).load() }
        guard case .unsupportedSchemaVersion(2, _, _) = error else {
            Issue.record("Expected .unsupportedSchemaVersion(2), got \(String(describing: error))")
            return
        }
    }

    /// A declaration names an exercise, so its position follows the live
    /// ladder; a step no longer on the ladder means no declaration.
    @Test func aDeclarationFollowsItsExerciseNotAPosition() throws {
        let pullUp = try #require(ProgressionCatalog.path(withID: .pullUp))
        let liveIndex = try #require(pullUp.steps.firstIndex { $0.exerciseID == E.pullUpsID })

        let placement = SkillPlacement(declaredStepByPath: [.pullUp: E.pullUpsID])
        #expect(placement.declaredRung(for: .pullUp) == liveIndex)

        let removed = SkillPlacement(declaredStepByPath: [.pullUp: UUID()])
        #expect(removed.declaredRung(for: .pullUp) == nil)
        #expect(ProgressionEngine.pathState(for: pullUp, logs: [], placement: removed).conqueredRungCount == 0)
    }
}

// MARK: - Lowered floor (A-2)

@Suite("Lowering the placement floor never re-celebrates old rungs")
struct LoweredFloorTests {
    @Test func loweringTheFloorAfterTrainingCelebratesNothing() {
        let placed = SkillPlacement(declaredStepByPath: [.pullUp: ExerciseCatalog.pullUpsID])
        let logs = [IntegrityFixture.pullUps3x8()]
        let baseline = RewardEvaluator.evaluate(logs: [], placement: placed, celebrated: nil).updatedProgress

        let trained = RewardEvaluator.evaluate(logs: logs, placement: placed, celebrated: baseline)
        // Only the declared rung itself celebrates; 0…4 are recorded silently.
        #expect(IntegrityFixture.rungEvents(trained.pendingEvents) == [IntegrityFixture.pullUpRung])
        let belowFloor = (0...4).compactMap { RungReference(pathID: .pullUp, rungIndex: $0) }
        #expect(belowFloor.allSatisfy(trained.updatedProgress.hasCelebrated))

        let shown = trained.pendingEvents.reduce(trained.updatedProgress) { $0.markingCelebrated($1) }
        for lowered in [nil, SkillPlacement.empty, SkillPlacement(declaredStepByPath: [.pullUp: ExerciseCatalog.negativePullUpsID])] {
            let after = RewardEvaluator.evaluate(logs: logs, placement: lowered, celebrated: shown)
            #expect(after.pendingEvents.isEmpty)
        }
    }

    /// A record written before this fix holds only the rungs at or above the
    /// floor. The next evaluation fills in the ones below it silently, so a
    /// later floor drop stays quiet too.
    @Test func aRecordFromBeforeTheFixIsFilledInSilently() {
        let placed = SkillPlacement(declaredStepByPath: [.pullUp: ExerciseCatalog.pullUpsID])
        let logs = [IntegrityFixture.pullUps3x8()]
        let oldRecord = SkillProgress(celebratedRungs: [IntegrityFixture.pullUpRung], celebratedLevel: 2)

        let upgraded = RewardEvaluator.evaluate(logs: logs, placement: placed, celebrated: oldRecord)
        #expect(upgraded.pendingEvents.isEmpty)
        #expect(upgraded.updatedProgress.celebratedRungs.count == 6)

        let lowered = RewardEvaluator.evaluate(logs: logs, placement: nil, celebrated: upgraded.updatedProgress)
        #expect(lowered.pendingEvents.isEmpty)
    }

    @MainActor
    @Test func recalibratingDownInTheAppShowsNoFalseOverlay() async throws {
        let placementStore = InMemorySkillPlacementStore(initial: SkillPlacement(declaredStepByPath: [.pullUp: ExerciseCatalog.pullUpsID]))
        let stack = TrainingStack(placementStore: placementStore)

        try await stack.journal.log(IntegrityFixture.pullUps3x8())
        await stack.settle()
        #expect(stack.drainCelebrations() > 0)

        try placementStore.save(SkillPlacement(declaredRungByPath: [:]))
        stack.progress.reloadPlacement()
        await stack.settle()

        #expect(stack.rewards.currentCelebration == nil)
    }
}

// MARK: - Celebrated when shown (A-4, C-7)

@MainActor
@Suite("A celebration is recorded when it is dismissed, not when it is queued")
struct CelebratedWhenShownTests {
    @Test func anAdvanceQueuedOffScreenSurvivesARelaunch() throws {
        let logStore = InMemoryWorkoutLogStore()
        let placementStore = InMemorySkillPlacementStore()
        let progressStore = InMemorySkillProgressStore()
        func launch() -> TrainingStack {
            TrainingStack(logStore: logStore, placementStore: placementStore, progressStore: progressStore)
        }
        _ = launch() // seeds the baseline

        try logStore.append(IntegrityFixture.pullUps3x8())
        // The app launches with no overlay on screen: the center queues the
        // advance, but nothing is recorded as celebrated yet.
        let offScreen = launch()
        let queued = try #require(offScreen.rewards.currentCelebration)
        #expect(progressStore.load()?.celebratedRungs.isEmpty == true)

        // Killed before the overlay was seen: the next launch still shows it.
        let relaunched = launch()
        #expect(relaunched.rewards.currentCelebration == queued)

        relaunched.drainCelebrations()
        #expect(progressStore.load()?.hasCelebrated(IntegrityFixture.pullUpRung) == true)
        #expect(launch().rewards.currentCelebration == nil)
    }

    @Test func leavingMidQueueKeepsTheRestForNextTime() throws {
        let logStore = InMemoryWorkoutLogStore()
        let placementStore = InMemorySkillPlacementStore()
        let progressStore = InMemorySkillProgressStore()
        func launch() -> TrainingStack {
            TrainingStack(logStore: logStore, placementStore: placementStore, progressStore: progressStore)
        }
        _ = launch()
        try logStore.append(IntegrityFixture.pullUps3x8())

        let first = launch()
        let shown = try #require(first.rewards.currentCelebration)
        #expect(first.rewards.hasQueuedCelebrations)
        first.rewards.dismissCurrentCelebration()
        let next = try #require(first.rewards.currentCelebration)

        // The athlete leaves (or the app dies) with `next` on screen.
        let later = launch()
        #expect(later.rewards.currentCelebration == next)
        #expect(later.rewards.currentCelebration != shown)
    }

    @Test func evaluationsDoNotRewriteAnUnchangedRecord() async throws {
        let progressStore = CountingProgressStore()
        let stack = TrainingStack(logStore: InMemoryWorkoutLogStore(initial: [IntegrityFixture.pullUps3x8()]),
                                  progressStore: progressStore)
        #expect(progressStore.saveCount == 1) // the first-run baseline

        stack.rewards.refresh()
        stack.progress.reloadPlacement()
        #expect(progressStore.saveCount == 1)

        // A fresh advance is queued without a write, and written on dismissal.
        try await stack.journal.log(WorkoutLogEntry(exerciseID: ExerciseCatalog.lPullUpsID,
                                              date: IntegrityFixture.day,
                                              sets: [LoggedSet(reps: 5), LoggedSet(reps: 5), LoggedSet(reps: 5)]))
        await stack.settle()
        #expect(stack.rewards.currentCelebration == .single(.rungConquered(RungReference(pathID: .pullUp, stepID: ExerciseCatalog.lPullUpsID))))
        #expect(progressStore.saveCount == 1)

        stack.rewards.dismissCurrentCelebration()
        #expect(progressStore.saveCount == 2)
    }
}

// MARK: - Re-calibration (A-1, C-6)

@MainActor
@Suite("Re-calibration keeps what the athlete did not re-answer")
struct RecalibrationTests {
    private static let onboardedAt = Date(timeIntervalSince1970: 1_790_000_000)
    private static let recalibratedAt = Date(timeIntervalSince1970: 1_791_000_000)

    private static func question(_ path: ProgressionPathID) throws -> RepCountQuestion {
        try #require(PlacementCalibration.repQuestions.first { $0.path == path })
    }

    private static func skill(_ id: String) throws -> SkillQuestion {
        try #require(PlacementCalibration.skillQuestions.first { $0.id == id })
    }

    /// The audit scenario: onboarded with pull-ups 1–5, push-ups 6–11 and a
    /// muscle-up, later answers only the dips question from the Dips ladder.
    @Test func aPartialRecalibrationKeepsUntouchedPaths() throws {
        let onboarding = PlacementCalibration.placement(
            repAnswers: [.pullUp: .few, .pushUp: .several],
            masteredSkills: ["muscleUp"],
            ownsBand: true,
            declaredAt: Self.onboardedAt
        )
        let store = InMemorySkillPlacementStore(initial: onboarding)
        let viewModel = PlacementCalibrationViewModel(store: store, now: { Self.recalibratedAt })
        viewModel.load()

        viewModel.select(.few, for: try Self.question(.dip))
        viewModel.save()

        #expect(viewModel.didSave)
        let saved = try #require(store.load())
        #expect(saved.declaredStepByPath[.pullUp] == ExerciseCatalog.pullUpsID)
        #expect(saved.declaredRung(for: .pushUp) == 3)
        #expect(saved.declaredRung(for: .muscleUp) == 3)
        #expect(saved.declaredRung(for: .dip) == 2)
        #expect(saved.ownsEquipment(PlacementCalibration.bandEquipment))
        #expect(saved.declaredAt == Self.recalibratedAt)
    }

    /// Including a declaration no answer can produce (an older mapping, or a
    /// preview seed): opening the sheet and tapping Zapisz changes nothing.
    @Test func savingWithoutAnsweringKeepsEveryDeclaration() throws {
        let saved = SkillPlacement(declaredRungByPath: [.pullUp: 6, .core: 2, .pushUp: 3],
                                   ownedEquipment: ["Resistance bands", "Rings"],
                                   declaredAt: Self.onboardedAt)
        let store = InMemorySkillPlacementStore(initial: saved)
        let viewModel = PlacementCalibrationViewModel(store: store, now: { Self.recalibratedAt })
        viewModel.load()

        viewModel.save()

        let result = try #require(store.load())
        #expect(result.declaredStepByPath == saved.declaredStepByPath)
        #expect(result.ownedEquipment == saved.ownedEquipment)
    }

    @Test func theFormPrefillsUnambiguousAnswers() throws {
        let saved = PlacementCalibration.placement(
            repAnswers: [.pullUp: .many, .dip: .none, .pushUp: .few, .legs: .few],
            masteredSkills: ["pistolSquat", "fullLSit"],
            ownsBand: false
        )
        let viewModel = PlacementCalibrationViewModel(store: InMemorySkillPlacementStore(initial: saved))
        viewModel.load()

        #expect(viewModel.bucket(for: try Self.question(.pullUp)) == .many)
        #expect(viewModel.bucket(for: try Self.question(.dip)) == RepCountBucket.none)
        // 1–5 and 6–11 both declare the push-up rung: no guess, but the saved
        // level is named under the question.
        #expect(viewModel.bucket(for: try Self.question(.pushUp)) == nil)
        let pushUpName = ExerciseCatalog.exercise(withID: ExerciseCatalog.pushUpsID)?.name
        #expect(viewModel.savedRungName(for: try Self.question(.pushUp)) == pushUpName)
        // The pistol explains the legs rung, so the squat count stays open.
        #expect(viewModel.bucket(for: try Self.question(.legs)) == nil)
        #expect(viewModel.savedRungName(for: try Self.question(.legs)) == nil)
        #expect(viewModel.isMastered(try Self.skill("pistolSquat")))
        #expect(viewModel.isMastered(try Self.skill("fullLSit")))
        #expect(viewModel.isMastered(try Self.skill("muscleUp")) == false)
        #expect(viewModel.savedRungName(for: try Self.question(.pullUp)) == nil)
    }

    @Test func uncheckingAPrefilledSkillRemovesItsDeclaration() throws {
        let saved = PlacementCalibration.placement(repAnswers: [.pullUp: .few], masteredSkills: ["muscleUp"], ownsBand: false)
        let store = InMemorySkillPlacementStore(initial: saved)
        let viewModel = PlacementCalibrationViewModel(store: store)
        viewModel.load()

        viewModel.toggleMastery(of: try Self.skill("muscleUp"))
        viewModel.save()

        let result = try #require(store.load())
        #expect(result.declaredRung(for: .muscleUp) == nil)
        #expect(result.declaredStepByPath[.pullUp] == ExerciseCatalog.pullUpsID)
    }

    @Test func answeringAPathAgainReplacesOrClearsIt() throws {
        let saved = PlacementCalibration.placement(repAnswers: [.pullUp: .few, .legs: .many], masteredSkills: [], ownsBand: false)
        let store = InMemorySkillPlacementStore(initial: saved)
        let viewModel = PlacementCalibrationViewModel(store: store)
        viewModel.load()

        viewModel.select(.many, for: try Self.question(.pullUp))
        viewModel.select(.none, for: try Self.question(.legs)) // rung 0: no declaration
        viewModel.save()

        let result = try #require(store.load())
        #expect(result.declaredStepByPath[.pullUp] == ExerciseCatalog.lPullUpsID)
        #expect(result.declaredRung(for: .legs) == nil)
    }

    @Test func saveMergesAgainstWhatIsSavedNow() throws {
        let store = InMemorySkillPlacementStore(initial: SkillPlacement(declaredStepByPath: [.pullUp: ExerciseCatalog.pullUpsID]))
        let viewModel = PlacementCalibrationViewModel(store: store)
        viewModel.load()
        // Another screen saves a push-up declaration while this form is open.
        try store.save(SkillPlacement(declaredStepByPath: [.pullUp: ExerciseCatalog.pullUpsID, .pushUp: ExerciseCatalog.pushUpsID]))

        viewModel.select(.few, for: try Self.question(.dip))
        viewModel.save()

        let result = try #require(store.load())
        #expect(result.declaredRung(for: .pushUp) == 3)
        #expect(result.declaredRung(for: .dip) == 2)
    }

    @Test func anUnreadableSavedPlacementFailsTheSaveInsteadOfReplacingIt() throws {
        let store = UnreadablePlacementStore()
        let viewModel = PlacementCalibrationViewModel(store: store)
        viewModel.load()

        viewModel.select(.few, for: try Self.question(.dip))
        viewModel.save()

        #expect(viewModel.didSave == false)
        #expect(viewModel.errorMessage == "Nie udało się zapisać poziomu.")
        #expect(store.saveAttempts == 0)
    }

    /// Whatever the pre-fill restores reproduces the saved declaration exactly,
    /// so an untouched pre-filled answer can never move a rung.
    @Test(arguments: PlacementCalibration.repQuestions.map(\.path), RepCountBucket.allCases)
    func prefilledAnswersReproduceTheDeclaration(path: ProgressionPathID, bucket: RepCountBucket) {
        let saved = PlacementCalibration.placement(repAnswers: [path: bucket], masteredSkills: [], ownsBand: false)
        let answers = PlacementCalibration.answers(from: saved)
        let rebuilt = PlacementCalibration.placement(repAnswers: answers.repAnswers,
                                                     masteredSkills: answers.masteredSkills,
                                                     ownsBand: false)
        let isAmbiguous = bucket == .few || bucket == .several
        if isAmbiguous {
            #expect(answers.repAnswers[path] == nil)
        } else {
            #expect(rebuilt.declaredStepByPath == saved.declaredStepByPath)
        }
    }

    @Test(arguments: PlacementCalibration.skillQuestions.map(\.id))
    func prefilledSkillsReproduceTheDeclaration(skillID: String) {
        let saved = PlacementCalibration.placement(repAnswers: [:], masteredSkills: [skillID], ownsBand: false)
        let answers = PlacementCalibration.answers(from: saved)
        #expect(answers.masteredSkills == [skillID])
        #expect(answers.repAnswers.isEmpty)
    }
}
