//
//  LadderRevisionTests.swift
//  cali-parkTests
//
//  Ticket 015, the 2026-11 ladder revision: the frozen ladder order (fails on
//  any reorder), data saved before the revision resolving to the same
//  exercises, the one-time XP jump, and the content of the new rungs.
//

import Foundation
import Testing
@testable import cali_park

// MARK: - Ladder order snapshot

/// The ladder order after the 2026-11 revision (ticket 015). Saved data no
/// longer depends on rung positions (rungs are stored by step ID), but the
/// order is still the content of `docs/PROGRESSIONS.md`: this snapshot fails on
/// any insert, removal or reorder, so a change is always made on purpose and
/// in the doc too. Update it together with the doc; never touch
/// `LadderOrderV1`, which describes files already on devices.
@Suite("Ladder order snapshot (version 2, ticket 015)")
struct LadderOrderSnapshotTests {
    private typealias E = ExerciseCatalog

    static let ladderOrderV2: [ProgressionPathID: [UUID]] = [
        .pullUp: [E.deadHangID, E.scapularPullsID, E.archHangID, E.negativePullUpsID, E.bandPullUpsID,
                  E.pullUpsID, E.lPullUpsID, E.archerPullUpsID],
        .row: [E.inclineRowsID, E.australianPullUpsID, E.wideRowsID, E.archerRowsID, E.tuckFrontLeverRowsID],
        .pushUp: [E.wallPushUpsID, E.inclinePushUpsID, E.kneePushUpsID, E.pushUpsID, E.diamondPushUpsID, E.pseudoPlanchePushUpsID],
        .dip: [E.parallelBarSupportID, E.negativeDipsID, E.dipsID, E.ringSupportHoldID, E.ringDipsID],
        .legs: [E.assistedSquatsID, E.squatsID, E.lungesID, E.splitSquatID, E.bulgarianSplitSquatID,
                E.stepUpsID, E.assistedPistolSquatsID, E.pistolSquatsID],
        .core: [E.plankID, E.hangingKneeRaisesID, E.hangingLegRaisesID, E.toesToBarID],
        .muscleUp: [E.chestToBarPullUpsID, E.negativeMuscleUpsID, E.kippingMuscleUpsID, E.muscleUpID],
        .lSit: [E.footSupportedLSitID, E.oneFootSupportedLSitID, E.tuckLSitID, E.oneLegLSitID, E.lSitID],
        .frontLever: [E.tuckFrontLeverID, E.advancedTuckFrontLeverID, E.straddleFrontLeverID, E.halfLayFrontLeverID, E.frontLeverID],
        .backLever: [E.germanHangID, E.skinTheCatID, E.tuckBackLeverID, E.advancedTuckBackLeverID,
                     E.straddleBackLeverID, E.halfLayBackLeverID, E.backLeverID],
        .planche: [E.frogStandID, E.straightArmFrogStandID, E.tuckPlancheID, E.advancedTuckPlancheID,
                   E.straddlePlancheID, E.halfLayPlancheID, E.plancheID],
        .humanFlag: [E.verticalFlagSupportID, E.tuckFlagID, E.advancedTuckFlagID, E.straddleFlagID, E.humanFlagID],
        .handstand: [E.wallPlankID, E.wallHandstandHoldID, E.pikePushUpsID, E.elevatedPikePushUpsID,
                     E.wallHandstandPushUpNegativesID, E.wallHandstandPushUpsID]
    ]

    @Test func everyLadderMatchesTheSnapshot() {
        let live = Dictionary(uniqueKeysWithValues: ProgressionCatalog.all.map { ($0.id, $0.steps.map(\.exerciseID)) })
        #expect(live == Self.ladderOrderV2)
    }

    @Test func elevenRungsWereAddedAndNoneRemoved() {
        let before = Set(LadderOrderV1.stepIDs.values.flatMap { $0 })
        let after = Set(Self.ladderOrderV2.values.flatMap { $0 })
        #expect(before.isSubset(of: after))
        #expect(after.count - before.count == 11)
    }

    /// Only the L-sit ladder changed the relative order of rungs that existed
    /// before: one-leg L-sit moved above the tuck.
    @Test func onlyTheOneLegLSitMoved() {
        for (path, oldOrder) in LadderOrderV1.stepIDs {
            let newOrder = (Self.ladderOrderV2[path] ?? []).filter(oldOrder.contains)
            if path == .lSit {
                #expect(newOrder == [E.footSupportedLSitID, E.tuckLSitID, E.oneLegLSitID, E.lSitID])
            } else {
                #expect(newOrder == oldOrder, "\(path)")
            }
        }
    }
}

// MARK: - Data saved before the revision

@Suite("Data saved before the ladder revision keeps its meaning")
struct PreRevisionDataTests {
    private typealias E = ExerciseCatalog

    /// Every version 1 rung, placement or celebration, still resolves to the
    /// same exercise on the revised ladder, just at its new position.
    @Test func everyVersion1RungResolvesToTheSameExercise() throws {
        let decoder = JSONFileFormat.decoder(forSchemaVersion: 1)
        for (path, stepIDs) in LadderOrderV1.stepIDs {
            for (index, stepID) in stepIDs.enumerated() {
                let placementJSON = #"{"declaredRungByPath":["\#(path.rawValue)",\#(index)],"ownedEquipment":[],"declaredAt":"2026-10-01T07:30:00Z"}"#
                let placement = try decoder.decode(SkillPlacement.self, from: Data(placementJSON.utf8))
                #expect(placement.declaredReference(for: path)?.step?.exerciseID == stepID, "\(path) rung \(index)")

                let progressJSON = #"{"celebratedRungs":[{"pathID":"\#(path.rawValue)","rungIndex":\#(index)}],"celebratedLevel":1}"#
                let progress = try decoder.decode(SkillProgress.self, from: Data(progressJSON.utf8))
                let reference = try #require(progress.celebratedRungs.first)
                #expect(reference.step?.exerciseID == stepID, "\(path) rung \(index)")
            }
        }
    }

    /// A version 2 file written before the revision (step IDs) needs nothing:
    /// the IDs are still on their ladders.
    @Test func aVersion2PlacementFromBeforeTheRevisionStillPlaces() throws {
        let json = #"{"declaredStepByPath":{"pullUp":"\#(E.pullUpsID.uuidString)","lSit":"\#(E.oneLegLSitID.uuidString)","dip":"\#(E.ringDipsID.uuidString)"},"ownedEquipment":[],"declaredAt":"2026-10-01T07:30:00Z"}"#
        let placement = try JSONFileFormat.decoder(forSchemaVersion: 2).decode(SkillPlacement.self, from: Data(json.utf8))

        let states = ProgressionEngine.pathStates(logs: [], placement: placement)
        for (pathID, stepID) in [(ProgressionPathID.pullUp, E.pullUpsID), (.lSit, E.oneLegLSitID), (.dip, E.ringDipsID)] {
            let path = try #require(ProgressionCatalog.path(withID: pathID))
            let state = try #require(states[pathID])
            #expect(path.steps[state.currentRungIndex].exerciseID == stepID, "\(pathID)")
        }
    }

    /// The old "pull-up rung 4" (full pull-ups) is still full pull-ups, now at
    /// index 5 because the arch hang went in below it.
    @Test func anOldPullUpDeclarationStillPointsAtPullUps() throws {
        let decoder = JSONFileFormat.decoder(forSchemaVersion: 1)
        let json = #"{"declaredRungByPath":["pullUp",4],"ownedEquipment":[],"declaredAt":"2026-10-01T07:30:00Z"}"#
        let placement = try decoder.decode(SkillPlacement.self, from: Data(json.utf8))
        #expect(placement.declaredStepByPath[.pullUp] == E.pullUpsID)
        #expect(placement.declaredRung(for: .pullUp) == 5)
    }

    /// The one-time XP jump the owner accepted: rungs inserted below the
    /// highest conquered rung count as conquered. 3 × 8 full pull-ups conquered
    /// 5 rungs before the revision and 6 after (+100 XP); 3 × 5 wall handstand
    /// push-ups went from 3 to 6 handstand rungs (+300 XP).
    @Test func rungsInsertedBelowTheTopConqueredRungAddXPOnce() {
        let day = Date(timeIntervalSince1970: 1_759_303_800)
        let pullUps = WorkoutLogEntry(exerciseID: E.pullUpsID, date: day, sets: Array(repeating: LoggedSet(reps: 8), count: 3))
        let hspu = WorkoutLogEntry(exerciseID: E.wallHandstandPushUpsID, date: day, sets: Array(repeating: LoggedSet(reps: 5), count: 3))

        let pullUpVolume = 24 * ProgressionEngine.xpPerRep
        let hspuVolume = 15 * ProgressionEngine.xpPerRep
        let rungXP = ProgressionEngine.xpPerConqueredRung

        #expect(ProgressionEngine.experiencePoints(for: [pullUps]) == pullUpVolume + 6 * rungXP)
        #expect(LadderOrderV1.stepIDs[.pullUp]?.firstIndex(of: E.pullUpsID) == 4) // 5 rungs before
        #expect(ProgressionEngine.experiencePoints(for: [hspu]) == hspuVolume + 6 * rungXP)
        #expect(LadderOrderV1.stepIDs[.handstand]?.count == 3) // 3 rungs before
    }

    /// Celebrations are keyed by exercise: a record from before the revision
    /// does not replay old rungs. The inserted arch hang, now implied by
    /// full pull-ups, celebrates once: the visible side of the XP jump.
    @Test func anOldCelebrationRecordDoesNotReplayItsRungs() {
        let day = Date(timeIntervalSince1970: 1_759_303_800)
        let logs = [WorkoutLogEntry(exerciseID: E.pullUpsID, date: day, sets: Array(repeating: LoggedSet(reps: 8), count: 3))]
        let oldRecord = SkillProgress(
            celebratedRungs: Set(LadderOrderV1.stepIDs[.pullUp]!.prefix(5).map { RungReference(pathID: .pullUp, stepID: $0) }),
            celebratedLevel: ProgressionEngine.playerLevel(for: logs).level
        )

        let evaluation = RewardEvaluator.evaluate(logs: logs, placement: nil, celebrated: oldRecord)
        let rungEvents = evaluation.pendingEvents.compactMap { event -> RungReference? in
            if case let .rungConquered(rung) = event { return rung }
            return nil
        }
        #expect(rungEvents == [RungReference(pathID: .pullUp, stepID: E.archHangID)])
    }
}

// MARK: - Content of the revised ladders

@Suite("Revised ladder content (ticket 015)")
struct LadderRevisionContentTests {
    private typealias E = ExerciseCatalog

    static let newExerciseIDs: [UUID] = [
        E.archHangID, E.ringSupportHoldID, E.splitSquatID, E.bulgarianSplitSquatID, E.oneFootSupportedLSitID,
        E.straightArmFrogStandID, E.halfLayPlancheID, E.advancedTuckFlagID, E.pikePushUpsID,
        E.elevatedPikePushUpsID, E.wallHandstandPushUpNegativesID
    ]

    @Test func theNewExercisesUseTheNextFixedIDs() {
        let expected = (66...76).map { UUID(uuidString: String(format: "E0000000-0000-4000-8000-%012d", $0))! }
        #expect(Self.newExerciseIDs == expected)
    }

    @Test(arguments: LadderRevisionContentTests.newExerciseIDs)
    func everyNewExerciseIsAVariantOfAMainMovement(id: UUID) throws {
        let exercise = try #require(E.exercise(withID: id))
        let parent = try #require(exercise.variantOf.flatMap(E.exercise(withID:)))
        #expect(parent.variantOf == nil)
        #expect(!ProgressionCatalog.paths(containing: id).isEmpty)
    }

    @Test func theUnilateralExercisesCountPerSide() {
        let expected: [UUID: UnilateralSide] = [
            E.archerPullUpsID: .arm, E.archerRowsID: .arm,
            E.lungesID: .leg, E.splitSquatID: .leg, E.bulgarianSplitSquatID: .leg, E.stepUpsID: .leg,
            E.assistedPistolSquatsID: .leg, E.pistolSquatsID: .leg,
            E.oneFootSupportedLSitID: .side, E.oneLegLSitID: .side
        ]
        let actual = Dictionary(uniqueKeysWithValues: E.all.compactMap { exercise in
            exercise.unilateralSide.map { (exercise.id, $0) }
        })
        #expect(actual == expected)
    }

    @Test func staticsAskForThreeByTwentySecondsIncludingTheFullLSit() throws {
        let lSit = try #require(ProgressionCatalog.path(withID: .lSit))
        #expect(lSit.steps.allSatisfy { $0.criterion == .setsOfHold(sets: 3, seconds: 20) })
        #expect(lSit.steps.allSatisfy { $0.criterionSource == .og2Table })
    }

    @Test func theTableSourceOnlyLabelsThreeByTwentySecondHolds() {
        for step in ProgressionCatalog.all.flatMap(\.steps) where step.criterionSource == .og2Table {
            #expect(step.criterion == .setsOfHold(sets: 3, seconds: 20), "\(step.exerciseID)")
        }
    }

    /// Mastery markers (first clean rep, first 5 s) are our own convention.
    @Test func masteryMarkersAreLabelledAsOurConvention() {
        for step in ProgressionCatalog.all.flatMap(\.steps) where step.criterion.sets == 1 && step.criterion.targetValue <= 5 {
            #expect(step.criterionSource == .caliPark, "\(step.exerciseID)")
        }
    }

    @Test func theRingSupportHoldIsRRsSixtySeconds() throws {
        let step = try #require(ProgressionCatalog.path(withID: .dip)?.steps.first { $0.exerciseID == E.ringSupportHoldID })
        #expect(step.criterion == .setsOfHold(sets: 1, seconds: 60))
        #expect(step.criterionSource == .rr)
        #expect(step.criterionNote != nil)
    }

    @Test func negativesCarryTheDescentTempo() {
        let negatives = [E.negativePullUpsID, E.negativeDipsID, E.wallHandstandPushUpNegativesID]
        let steps = ProgressionCatalog.all.flatMap(\.steps).filter { negatives.contains($0.exerciseID) }
        #expect(steps.count == 3)
        for step in steps {
            #expect(step.criterionNote == "zjazd 5–10 s")
            #expect(step.criterionSource == .caliPark)
            #expect(E.exercise(withID: step.exerciseID)?.description.contains("5–10 sekund") == true)
        }
    }

    @Test func scapularPullsPauseAtTheTop() throws {
        let step = try #require(ProgressionCatalog.path(withID: .pullUp)?.steps.first { $0.exerciseID == E.scapularPullsID })
        #expect(step.criterionNote == "pauza 3–5 s na górze")
    }

    @Test func archerPullUpsCiteStartBodyweight() throws {
        let step = try #require(ProgressionCatalog.path(withID: .pullUp)?.steps.last)
        #expect(step.exerciseID == E.archerPullUpsID)
        #expect(step.criterionSource == .sbw)
    }

    @Test func theFlagTrainsOnAVerticalPoleOrWallBars() throws {
        let flag = try #require(ProgressionCatalog.path(withID: .humanFlag))
        for step in flag.steps {
            #expect(step.equipment == ["fitness_pole", "wall_bars"])
            #expect(E.exercise(withID: step.exerciseID)?.equipment == ["fitness_pole", "wall_bars"])
        }
    }

    @Test func floorExercisesNeedNoEquipment() throws {
        for id in [E.pseudoPlanchePushUpsID, E.frogStandID, E.straightArmFrogStandID] {
            #expect(E.exercise(withID: id)?.equipment == [])
            let step = try #require(ProgressionCatalog.all.flatMap(\.steps).first { $0.exerciseID == id })
            #expect(step.equipment.isEmpty)
        }
    }

    @Test func newEquipmentKeysHavePolishLabels() {
        #expect(EquipmentItem.displayName(for: "fitness_pole") == "Pionowy drążek")
        #expect(EquipmentItem.displayName(for: "wall_bars") == "Drabinki gimnastyczne")
        #expect(EquipmentItem.displayName(for: "Monkey bars") == "Drabinka pozioma")
    }

    @Test func everyStepHasASourceLabel() {
        for step in ProgressionCatalog.all.flatMap(\.steps) {
            #expect(!step.criterionSource.label.isEmpty)
            #expect(!step.criterionSource.explanation.isEmpty)
        }
    }
}
