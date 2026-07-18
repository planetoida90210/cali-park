//
//  ProgressionCatalogTests.swift
//  cali-parkTests
//
//  Sprint SK1 — integrity of the progression paths and their encoding of
//  docs/PROGRESSIONS.md. Content correctness lives in the doc; these tests
//  guard the structural invariants the later sprints rely on.
//

import Foundation
import Testing
@testable import cali_park

// MARK: - ProgressionCatalog integrity

struct ProgressionCatalogTests {
    @Test
    func everyPathIdentifierIsDefined() {
        let ids = ProgressionCatalog.all.map(\.id)
        #expect(Set(ids) == Set(ProgressionPathID.allCases))
        #expect(ids.count == ProgressionPathID.allCases.count)
    }

    @Test
    func lookupResolvesEveryPath() {
        for id in ProgressionPathID.allCases {
            #expect(ProgressionCatalog.path(withID: id)?.id == id)
        }
    }

    @Test(arguments: ProgressionCatalog.all)
    func pathHasStepsAndDisplayText(path: ProgressionPath) {
        #expect(!path.name.isEmpty)
        #expect(path.symbolName.hasPrefix("figure."))
        #expect(path.steps.count >= 3)
        #expect(path.recommendedBase.map { !$0.isEmpty } ?? true)
    }

    @Test(arguments: ProgressionCatalog.all)
    func stepsAreUniqueWithinPath(path: ProgressionPath) {
        let ids = path.steps.map(\.exerciseID)
        #expect(Set(ids).count == ids.count)
    }

    @Test(arguments: ProgressionCatalog.all)
    func everyStepResolvesToACatalogExercise(path: ProgressionPath) {
        for step in path.steps {
            #expect(ExerciseCatalog.exercise(withID: step.exerciseID) != nil)
        }
    }

    @Test(arguments: ProgressionCatalog.all)
    func criterionMeasurementMatchesExercise(path: ProgressionPath) {
        for step in path.steps {
            let exercise = ExerciseCatalog.exercise(withID: step.exerciseID)
            #expect(exercise?.measurement == step.criterion.measurement)
        }
    }

    @Test
    func onlyBandPullUpsIsAParallelTrack() {
        let parallel = ProgressionCatalog.all
            .flatMap(\.steps)
            .filter(\.isParallelTrack)
            .map(\.exerciseID)
        #expect(parallel == [ExerciseCatalog.bandPullUpsID])
    }

    @Test
    func parallelTrackStepsCarryTheirEquipment() {
        let bandStep = ProgressionCatalog.path(withID: .pullUp)?
            .steps.first { $0.exerciseID == ExerciseCatalog.bandPullUpsID }
        #expect(bandStep?.equipment.contains("Resistance bands") == true)
    }

    @Test(arguments: ProgressionCatalog.all)
    func pathRoundtripsThroughJSON(path: ProgressionPath) throws {
        let data = try JSONEncoder().encode(path)
        let decoded = try JSONDecoder().decode(ProgressionPath.self, from: data)
        #expect(decoded == path)
    }
}

// MARK: - AdvancementCriterion

struct AdvancementCriterionTests {
    @Test
    func repCriterionReportsRepsMeasurement() {
        let criterion = AdvancementCriterion.setsOfReps(sets: 3, reps: 8)
        #expect(criterion.measurement == .reps)
        #expect(criterion.sets == 3)
    }

    @Test
    func holdCriterionReportsSecondsMeasurement() {
        let criterion = AdvancementCriterion.setsOfHold(sets: 3, seconds: 20)
        #expect(criterion.measurement == .seconds)
        #expect(criterion.sets == 3)
    }

    @Test(arguments: [
        AdvancementCriterion.setsOfReps(sets: 3, reps: 8),
        AdvancementCriterion.setsOfHold(sets: 3, seconds: 20)
    ])
    func criterionRoundtripsThroughJSON(criterion: AdvancementCriterion) throws {
        let data = try JSONEncoder().encode(criterion)
        let decoded = try JSONDecoder().decode(AdvancementCriterion.self, from: data)
        #expect(decoded == criterion)
    }
}
