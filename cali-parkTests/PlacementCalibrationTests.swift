//
//  PlacementCalibrationTests.swift
//  cali-parkTests
//
//  Sprint SK4 — the placement questionnaire: mapping answers to starting rungs
//  (rep buckets and skill checkboxes, highest wins per path), the resistance
//  band as owned equipment, integrity of every mapped rung, the view model's
//  save/load through the store, and the SK3 regression that declarations grant
//  no XP. Pure and deterministic: the declared date is injected.
//

import Foundation
import Testing
@testable import cali_park

// MARK: - Rep bucket mapping

@MainActor
struct PlacementRepMappingTests {
    /// One expected mapping row. `expectedRung == nil` means the answer declares
    /// nothing (a rung-0 answer is dropped as a no-op).
    struct RepCase: Sendable {
        let path: ProgressionPathID
        let bucket: RepCountBucket
        let expectedRung: Int?
    }

    /// Every (path, bucket) → expected declared rung, pinning `docs/PROGRESSIONS.md`.
    @Test(arguments: [
        RepCase(path: .pullUp, bucket: .none, expectedRung: 2),     // negatives
        RepCase(path: .pullUp, bucket: .few, expectedRung: 4),      // pull-ups
        RepCase(path: .pullUp, bucket: .several, expectedRung: 4),  // pull-ups
        RepCase(path: .pullUp, bucket: .many, expectedRung: 5),     // L-pull-ups
        RepCase(path: .pushUp, bucket: .none, expectedRung: 2),     // knee push-ups
        RepCase(path: .pushUp, bucket: .few, expectedRung: 3),      // push-ups
        RepCase(path: .pushUp, bucket: .several, expectedRung: 3),  // push-ups
        RepCase(path: .pushUp, bucket: .many, expectedRung: 4),     // diamond, not yet conquered
        RepCase(path: .dip, bucket: .none, expectedRung: 1),        // negatives
        RepCase(path: .dip, bucket: .few, expectedRung: 2),         // dips
        RepCase(path: .dip, bucket: .several, expectedRung: 2),     // dips
        RepCase(path: .dip, bucket: .many, expectedRung: 3),        // ring dips
        RepCase(path: .legs, bucket: .none, expectedRung: nil),
        RepCase(path: .legs, bucket: .few, expectedRung: 1),        // squats
        RepCase(path: .legs, bucket: .several, expectedRung: 1),    // squats
        RepCase(path: .legs, bucket: .many, expectedRung: 2)        // lunges
    ])
    func repBucketMapsToRung(_ testCase: RepCase) {
        let placement = PlacementCalibration.placement(
            repAnswers: [testCase.path: testCase.bucket],
            masteredSkills: [],
            ownsBand: false
        )
        #expect(placement.declaredRung(for: testCase.path) == testCase.expectedRung)
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
            for bucket in RepCountBucket.allCases {
                let placement = PlacementCalibration.placement(repAnswers: [question.path: bucket], masteredSkills: [], ownsBand: false)
                let state = ProgressionEngine.pathState(for: path, logs: [], placement: placement)
                #expect(state.conqueredRungCount <= question.movementRung + 1,
                        "\(question.path) \(bucket.label) conquers a variant harder than the counted movement")
            }
        }
    }

    /// Only the top bucket proves the movement's own 3 × 8; everything below it
    /// keeps the movement as the rung to train.
    @Test func movementIsConqueredOnlyFromTopBucket() {
        for question in PlacementCalibration.repQuestions {
            for bucket in RepCountBucket.allCases {
                let conquersMovement = question.rung(for: bucket) > question.movementRung
                #expect(conquersMovement == (bucket == .many), "\(question.path) \(bucket.label)")
            }
        }
    }

    @Test func emptyAnswersDeclareNothing() {
        let placement = PlacementCalibration.placement(
            repAnswers: [:],
            masteredSkills: [],
            ownsBand: false
        )
        #expect(placement.declaredRungByPath.isEmpty)
        #expect(placement.ownedEquipment.isEmpty)
    }
}

// MARK: - Skill checkboxes

@MainActor
struct PlacementSkillMappingTests {
    @Test(arguments: [
        ("muscleUp", ProgressionPathID.muscleUp, 3),
        ("fullLSit", .lSit, 3),
        ("pistolSquat", .legs, 5)
    ])
    func masteredSkillDeclaresItsRung(id: String, path: ProgressionPathID, rung: Int) {
        let placement = PlacementCalibration.placement(
            repAnswers: [:],
            masteredSkills: [id],
            ownsBand: false
        )
        #expect(placement.declaredRung(for: path) == rung)
    }

    /// The pistol checkbox and the squat count both place `legs`; the higher
    /// rung wins regardless of which is larger.
    @Test func highestRungWinsWhenAnswersSharePath() {
        let pistolBeatsSquats = PlacementCalibration.placement(
            repAnswers: [.legs: .many],          // lunges, rung 2
            masteredSkills: ["pistolSquat"],      // pistol, rung 5
            ownsBand: false
        )
        #expect(pistolBeatsSquats.declaredRung(for: .legs) == 5)

        let squatsBeatNothing = PlacementCalibration.placement(
            repAnswers: [.legs: .many],
            masteredSkills: [],
            ownsBand: false
        )
        #expect(squatsBeatNothing.declaredRung(for: .legs) == 2)

        let pistolWithoutSquats = PlacementCalibration.placement(
            repAnswers: [.legs: .none],          // rung 0, dropped
            masteredSkills: ["pistolSquat"],      // rung 5
            ownsBand: false
        )
        #expect(pistolWithoutSquats.declaredRung(for: .legs) == 5)
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
    /// Every rung a question can declare is a valid index into its path's ladder.
    @Test func everyDeclarableRungIsAValidStepIndex() throws {
        for question in PlacementCalibration.repQuestions {
            let path = try #require(ProgressionCatalog.path(withID: question.path))
            for bucket in RepCountBucket.allCases {
                let rung = question.rung(for: bucket)
                #expect(rung >= 0)
                #expect(rung < path.steps.count)
            }
        }

        for question in PlacementCalibration.skillQuestions {
            let path = try #require(ProgressionCatalog.path(withID: question.path))
            #expect(question.rung > 0, "A skill checkbox at rung 0 would be a no-op.")
            #expect(question.rung < path.steps.count)
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
        #expect(saved.declaredRung(for: .pullUp) == 5)
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
        #expect(viewModel.errorMessage != nil)
    }
}

// MARK: - SK3 regression: declarations grant no XP

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
        #expect(placement.declaredRung(for: .pullUp) == 5)
        // …yet with no logs there is no XP to earn from it.
        #expect(ProgressionEngine.experiencePoints(for: []) == 0)

        // And the declared rungs still show as conquered without any XP.
        let pullUp = try #require(ProgressionCatalog.path(withID: .pullUp))
        let state = ProgressionEngine.pathState(for: pullUp, logs: [], placement: placement)
        #expect(state.conqueredRungCount == 5)
    }
}

// MARK: - Fixtures

/// A `PlacementStoring` stub whose `save` always throws, to exercise error copy.
private struct FailingPlacementStore: PlacementStoring {
    struct SaveError: Error {}
    func load() -> SkillPlacement? { nil }
    func save(_ placement: SkillPlacement) throws { throw SaveError() }
}
