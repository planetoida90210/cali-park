//
//  PlacementCalibrationTests.swift
//  cali-parkTests
//
//  The placement questionnaire: mapping answers to starting rungs
//  (rep buckets and skill checkboxes, highest wins per path), the resistance
//  band as owned equipment, integrity of every mapped rung, the view model's
//  save/load through the store, and a regression test that declarations grant
//  no XP. Pure and deterministic: the declared date is injected.
//

import Foundation
import Testing
@testable import cali_park

// MARK: - Rep bucket mapping

@MainActor
struct PlacementRepMappingTests {
    private typealias E = ExerciseCatalog

    /// One expected mapping row. `expectedStep == nil` means the answer declares
    /// nothing (a bottom-rung answer is dropped as a no-op).
    struct RepCase: Sendable {
        let path: ProgressionPathID
        let bucket: RepCountBucket
        let expectedStep: UUID?
    }

    /// Every (path, bucket) → expected declared rung, pinning `docs/PROGRESSIONS.md`.
    /// The outcomes survived the 2026-11 ladder revision except dips at "12+",
    /// which now start on the ring support hold instead of ring dips.
    @Test(arguments: [
        RepCase(path: .pullUp, bucket: .none, expectedStep: E.negativePullUpsID),
        RepCase(path: .pullUp, bucket: .few, expectedStep: E.pullUpsID),
        RepCase(path: .pullUp, bucket: .several, expectedStep: E.pullUpsID),
        RepCase(path: .pullUp, bucket: .many, expectedStep: E.lPullUpsID),
        RepCase(path: .pushUp, bucket: .none, expectedStep: E.kneePushUpsID),
        RepCase(path: .pushUp, bucket: .few, expectedStep: E.pushUpsID),
        RepCase(path: .pushUp, bucket: .several, expectedStep: E.pushUpsID),
        RepCase(path: .pushUp, bucket: .many, expectedStep: E.diamondPushUpsID), // not yet conquered
        RepCase(path: .dip, bucket: .none, expectedStep: E.negativeDipsID),
        RepCase(path: .dip, bucket: .few, expectedStep: E.dipsID),
        RepCase(path: .dip, bucket: .several, expectedStep: E.dipsID),
        RepCase(path: .dip, bucket: .many, expectedStep: E.ringSupportHoldID),
        RepCase(path: .legs, bucket: .none, expectedStep: nil),
        RepCase(path: .legs, bucket: .few, expectedStep: E.squatsID),
        RepCase(path: .legs, bucket: .several, expectedStep: E.squatsID),
        RepCase(path: .legs, bucket: .many, expectedStep: E.lungesID)
    ])
    func repBucketMapsToRung(_ testCase: RepCase) {
        let placement = PlacementCalibration.placement(
            repAnswers: [testCase.path: testCase.bucket],
            masteredSkills: [],
            ownsBand: false
        )
        #expect(placement.declaredStepByPath[testCase.path] == testCase.expectedStep)
    }

    /// Dips at "12+": the current rung is the ring support hold (RR's
    /// condition before ring dips), and parallel-bar dips are conquered.
    @Test func manyDipsStartOnTheRingSupportHold() throws {
        let dip = try #require(ProgressionCatalog.path(withID: .dip))
        let placement = PlacementCalibration.placement(repAnswers: [.dip: .many], masteredSkills: [], ownsBand: false)
        let state = ProgressionEngine.pathState(for: dip, logs: [], placement: placement)
        #expect(dip.steps[state.currentRungIndex].exerciseID == E.ringSupportHoldID)
        let dipsRung = try #require(dip.steps.firstIndex { $0.exerciseID == E.dipsID })
        #expect(state.isConquered(rungAt: dipsRung))
    }

    /// 9 push-ups in one set is not 3 × 8 push-ups, let alone diamond push-ups:
    /// the top bucket starts at 12 and even then only makes diamonds current.
    @Test func nineRegularPushUpsDoNotConquerDiamonds() throws {
        let pushUp = try #require(ProgressionCatalog.path(withID: .pushUp))
        let diamondRung = try #require(pushUp.steps.firstIndex { $0.exerciseID == ExerciseCatalog.diamondPushUpsID })

        for bucket in RepCountBucket.allCases {
            let placement = PlacementCalibration.placement(repAnswers: [.pushUp: bucket], masteredSkills: [], ownsBand: false)
            let state = ProgressionEngine.pathState(for: pushUp, logs: [], placement: placement)
            #expect(state.conqueredRungCount <= diamondRung, "\(bucket.label) must not conquer diamond push-ups")
        }
    }

    /// A rep count only speaks for the movement it asks about: no answer on any
    /// question may conquer a rung above that movement.
    @Test func repCountNeverConquersAHarderVariant() throws {
        for question in PlacementCalibration.repQuestions {
            let path = try #require(ProgressionCatalog.path(withID: question.path))
            let movementRung = try #require(question.movementRung)
            for bucket in RepCountBucket.allCases {
                let placement = PlacementCalibration.placement(repAnswers: [question.path: bucket], masteredSkills: [], ownsBand: false)
                let state = ProgressionEngine.pathState(for: path, logs: [], placement: placement)
                #expect(state.conqueredRungCount <= movementRung + 1,
                        "\(question.path) \(bucket.label) conquers a variant harder than the counted movement")
            }
        }
    }

    /// Only the top bucket proves the movement's own 3 × 8; everything below it
    /// keeps the movement as the rung to train.
    @Test func movementIsConqueredOnlyFromTopBucket() throws {
        for question in PlacementCalibration.repQuestions {
            let movementRung = try #require(question.movementRung)
            for bucket in RepCountBucket.allCases {
                let rung = try #require(question.rung(for: bucket))
                #expect((rung > movementRung) == (bucket == .many), "\(question.path) \(bucket.label)")
            }
        }
    }

    /// "12+" makes the next main-line rung above the movement current, never a
    /// parallel track.
    @Test func manyRepsLandOnTheNextMainLineRung() throws {
        for question in PlacementCalibration.repQuestions {
            let path = try #require(ProgressionCatalog.path(withID: question.path))
            let movementRung = try #require(question.movementRung)
            let next = try #require(ProgressionEngine.nextMainLineRung(in: path, from: movementRung + 1))
            #expect(question.nextVariantStep == path.steps[next].exerciseID, "\(question.path)")
        }
    }

    @Test func emptyAnswersDeclareNothing() {
        let placement = PlacementCalibration.placement(
            repAnswers: [:],
            masteredSkills: [],
            ownsBand: false
        )
        #expect(placement.declaredStepByPath.isEmpty)
        #expect(placement.ownedEquipment.isEmpty)
    }
}

// MARK: - Skill checkboxes

@MainActor
struct PlacementSkillMappingTests {
    @Test(arguments: [
        ("muscleUp", ProgressionPathID.muscleUp, ExerciseCatalog.muscleUpID),
        ("fullLSit", .lSit, ExerciseCatalog.lSitID),
        ("pistolSquat", .legs, ExerciseCatalog.pistolSquatsID)
    ])
    func masteredSkillDeclaresItsRung(id: String, path: ProgressionPathID, step: UUID) {
        let placement = PlacementCalibration.placement(
            repAnswers: [:],
            masteredSkills: [id],
            ownsBand: false
        )
        #expect(placement.declaredStepByPath[path] == step)
    }

    /// The pistol checkbox and the squat count both place `legs`; the higher
    /// rung wins regardless of which is larger.
    @Test func highestRungWinsWhenAnswersSharePath() {
        let pistolBeatsSquats = PlacementCalibration.placement(
            repAnswers: [.legs: .many],          // lunges
            masteredSkills: ["pistolSquat"],      // pistol
            ownsBand: false
        )
        #expect(pistolBeatsSquats.declaredStepByPath[.legs] == ExerciseCatalog.pistolSquatsID)

        let squatsBeatNothing = PlacementCalibration.placement(
            repAnswers: [.legs: .many],
            masteredSkills: [],
            ownsBand: false
        )
        #expect(squatsBeatNothing.declaredStepByPath[.legs] == ExerciseCatalog.lungesID)

        let pistolWithoutSquats = PlacementCalibration.placement(
            repAnswers: [.legs: .none],          // bottom rung, dropped
            masteredSkills: ["pistolSquat"],
            ownsBand: false
        )
        #expect(pistolWithoutSquats.declaredStepByPath[.legs] == ExerciseCatalog.pistolSquatsID)
    }
}

// MARK: - Equipment

@MainActor
struct PlacementEquipmentTests {
    @Test func bandAnswerControlsOwnedEquipment() {
        let owns = PlacementCalibration.placement(repAnswers: [:], masteredSkills: [], ownsBand: true)
        #expect(owns.ownsEquipment("Resistance bands"))
        #expect(owns.ownedEquipment == ["Resistance bands"])

        let none = PlacementCalibration.placement(repAnswers: [:], masteredSkills: [], ownsBand: false)
        #expect(none.ownedEquipment.isEmpty)
    }
}

// MARK: - Integrity

@MainActor
struct PlacementCalibrationIntegrityTests {
    /// Every rung a question can declare is on its path's ladder.
    @Test func everyDeclarableRungIsOnItsLadder() throws {
        for question in PlacementCalibration.repQuestions {
            for bucket in RepCountBucket.allCases {
                #expect(question.rung(for: bucket) != nil, "\(question.path) \(bucket.label)")
            }
        }

        for question in PlacementCalibration.skillQuestions {
            let rung = try #require(question.rung, "\(question.id) is not on its ladder")
            #expect(rung > 0, "A skill checkbox at the bottom rung would be a no-op.")
        }
    }
}

// MARK: - View model save/load

@MainActor
struct PlacementCalibrationViewModelTests {
    @Test func saveWritesDeclaredPlacementToStore() throws {
        let store = InMemorySkillPlacementStore()
        let fixedDate = Date(timeIntervalSince1970: 1_000)
        let viewModel = PlacementCalibrationViewModel(store: store, now: { fixedDate })

        let pullUp = try #require(viewModel.repQuestions.first { $0.path == .pullUp })
        viewModel.select(.many, for: pullUp)
        let muscleUp = try #require(viewModel.skillQuestions.first { $0.id == "muscleUp" })
        viewModel.toggleMastery(of: muscleUp)
        viewModel.ownsBand = true

        viewModel.save()

        #expect(viewModel.didSave)
        let saved = try #require(store.load())
        #expect(saved.declaredStepByPath[.pullUp] == ExerciseCatalog.lPullUpsID)
        #expect(saved.declaredRung(for: .muscleUp) == 3)
        #expect(saved.ownsEquipment("Resistance bands"))
        #expect(saved.declaredAt == fixedDate)
    }

    @Test func initPreloadsOwnedBandFromExistingPlacement() {
        let store = InMemorySkillPlacementStore(
            initial: SkillPlacement(ownedEquipment: ["Resistance bands"])
        )
        let viewModel = PlacementCalibrationViewModel(store: store)
        #expect(viewModel.ownsBand)
    }

    @Test func saveSurfacesStoreFailure() {
        let viewModel = PlacementCalibrationViewModel(store: FailingPlacementStore())
        viewModel.save()
        #expect(viewModel.didSave == false)
        #expect(viewModel.errorMessage == "Nie udało się zapisać poziomu.")
    }
}

// MARK: - Regression: declarations grant no XP

@MainActor
struct PlacementNeverGrantsXPTests {
    /// A declaration conquers rungs for display, but XP is scored from logs
    /// alone — `experiencePoints(for:)` cannot even see a placement.
    @Test func declaredPlacementYieldsNoXP() throws {
        let placement = PlacementCalibration.placement(
            repAnswers: [.pullUp: .many, .pushUp: .many, .dip: .many, .legs: .many],
            masteredSkills: ["muscleUp", "fullLSit", "pistolSquat"],
            ownsBand: true
        )
        // The placement really does declare progress…
        #expect(placement.declaredStepByPath[.pullUp] == ExerciseCatalog.lPullUpsID)
        // …yet with no logs there is no XP to earn from it.
        #expect(ProgressionEngine.experiencePoints(for: []) == 0)

        // And the declared rungs still show as conquered without any XP.
        let pullUp = try #require(ProgressionCatalog.path(withID: .pullUp))
        let state = ProgressionEngine.pathState(for: pullUp, logs: [], placement: placement)
        #expect(state.conqueredRungCount == 6)
    }
}

// MARK: - Fixtures

/// A `SkillPlacementStoring` stub whose `save` always throws, to exercise error copy.
private struct FailingPlacementStore: SkillPlacementStoring {
    struct SaveError: Error {}
    func load() -> SkillPlacement? { nil }
    func save(_ placement: SkillPlacement) throws { throw SaveError() }
}
