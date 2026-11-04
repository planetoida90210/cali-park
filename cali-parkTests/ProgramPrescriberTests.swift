import Foundation
import Testing

@testable import cali_park

private typealias E = ExerciseCatalog

// MARK: - Catalog

@Suite("Program catalog (ticket 016)")
struct TrainingProgramCatalogTests {
    @Test
    func shipsTheFourProgramsInPlannerOrder() {
        #expect(ProgramCatalog.all.map(\.id) == [.minimum, .fundamentals, .firstPullUp, .skills])
        #expect(ProgramCatalog.all.map(\.name) == ["Minimum", "Fundamenty", "Pierwsze podciągnięcie", "Skille"])
    }

    @Test(arguments: ProgramCatalog.all)
    func everyProgramIsComplete(program: TrainingProgram) {
        #expect(program.version >= 1)
        #expect(program.tagline.isEmpty == false)
        #expect(program.audience.isEmpty == false)
        #expect(program.details.isEmpty == false)
        #expect(program.frequency.isEmpty == false)
        #expect(program.sessionLength.isEmpty == false)
        #expect(program.creditLine.isEmpty == false)
        #expect(program.weekdays.isEmpty == false)
        #expect(program.sessions.isEmpty == false)
        #expect(program.sessions.allSatisfy { !$0.items.isEmpty })
    }

    @Test(arguments: ProgramCatalog.all)
    func everyItemPointsAtAnExistingLadderOrExercise(program: TrainingProgram) {
        for item in program.sessions.flatMap(\.items) {
            switch item.movement {
            case .ladder(let path, _):
                #expect(ProgressionCatalog.path(withID: path) != nil)
            case .exercise(let id):
                #expect(E.exercise(withID: id) != nil)
            }
        }
    }

    /// We never call a program official or claim RR's endorsement.
    @Test(arguments: ProgramCatalog.all)
    func creditLinesNeverClaimToBeOfficial(program: TrainingProgram) {
        let text = ([program.creditLine, program.tagline] + program.details).joined(separator: " ").lowercased()
        #expect(text.contains("oficjalny rr") == false)
        #expect(text.contains("official") == false)
    }

    @Test
    func creditLinesNameTheirSources() {
        #expect(ProgramCatalog.minimum.creditLine.contains("Minimalist Routine"))
        #expect(ProgramCatalog.fundamentals.creditLine.hasPrefix("Inspirowane Recommended Routine"))
        #expect(ProgramCatalog.firstPullUp.creditLine.contains("StartBodyweight"))
        #expect(ProgramCatalog.skills.creditLine.contains("Skill Day"))
    }

    @Test
    func fundamentalsPairsTheLaddersLikeRR() {
        let items = ProgramCatalog.fundamentals.sessions[0].items
        let pairs = Dictionary(grouping: items, by: { $0.group ?? 0 }).mapValues { group in
            group.compactMap { item -> ProgressionPathID? in
                if case .ladder(let path, _) = item.movement { return path }
                return nil
            }
        }
        #expect(pairs == [1: [.pullUp, .legs], 2: [.dip, .core], 3: [.row, .pushUp]])
        #expect(items.allSatisfy { $0.restSeconds == 90 })
    }

    @Test
    func planOriginResolvesOnlyKnownPrograms() {
        var plan = WorkoutPlan(name: "x", programID: "fundamentals", programVersion: 1)
        #expect(ProgramCatalog.program(for: plan)?.id == .fundamentals)
        plan.programID = "programFromTheFuture"
        #expect(ProgramCatalog.program(for: plan) == nil)
        plan.programID = nil
        #expect(ProgramCatalog.program(for: plan) == nil)
    }

    @Test
    func shoulderTapsAreAPlankVariantOffTheLadders() throws {
        let taps = try #require(E.exercise(withID: E.plankShoulderTapsID))
        #expect(taps.variantOf == E.plankID)
        #expect(taps.unilateralSide == .side)
        #expect(taps.measurement == .reps)
        #expect(ProgressionCatalog.paths(containing: taps.id).isEmpty)
        #expect(E.mainMovements.contains(taps) == false)
    }
}

// MARK: - Prescriber

@Suite("ProgramPrescriber turns a program into plans")
struct ProgramPrescriberTests {
    private func plan(
        _ program: TrainingProgram,
        _ states: [ProgressionPathID: PathState]
    ) throws -> WorkoutPlan {
        let plans = ProgramPrescriber.plans(for: program, pathStates: states, today: ProgramFixtures.today)
        #expect(plans.count == 1)
        return try #require(plans.first)
    }

    @Test(arguments: ProgramCatalog.all)
    func plansRememberTheProgramAndAreOrdinaryPlans(program: TrainingProgram) throws {
        let plan = try plan(program, ProgramFixtures.newcomer)

        #expect(plan.programID == program.id.rawValue)
        #expect(plan.programVersion == program.version)
        #expect(plan.name == program.sessions[0].name)
        #expect(plan.schedule == .weekly(program.weekdays))
        #expect(plan.createdAt == ProgramFixtures.today)
        #expect(plan.isActive)
        #expect(plan.reminderTime == nil)
        #expect(plan.exercises.count == program.sessions[0].items.count)
    }

    // MARK: Minimum

    @Test
    func minimumIsOneCircuitOnTheCurrentRungs() throws {
        let plan = try plan(ProgramCatalog.minimum, ProgramFixtures.zeroPullUps)

        #expect(plan.exercises.map(\.exerciseID) == [E.assistedSquatsID, E.kneePushUpsID, E.inclineRowsID, E.plankShoulderTapsID])
        #expect(plan.exercises.map(\.pathID) == [.legs, .pushUp, .row, nil])
        #expect(plan.exercises.allSatisfy { $0.group == 1 && $0.rounds == 2...6 && $0.repsInReserve == 2 })
        #expect(plan.exercises.allSatisfy { $0.targetSets == nil && $0.targetReps == nil })
        #expect(plan.schedule == .weekly([.monday, .wednesday, .friday]))
    }

    @Test
    func minimumForAnAdvancedAthleteStartsLegsOnLunges() throws {
        let plan = try plan(ProgramCatalog.minimum, ProgramFixtures.advanced)

        #expect(plan.exercises.map(\.exerciseID) == [E.lungesID, E.diamondPushUpsID, E.inclineRowsID, E.plankShoulderTapsID])
    }

    // MARK: Fundamenty

    @Test
    func fundamentalsForANewcomerStartsEveryLadderAtTheBottom() throws {
        let plan = try plan(ProgramCatalog.fundamentals, ProgramFixtures.newcomer)
        let items = plan.exercises

        #expect(
            items.map(\.exerciseID) == [
                E.deadHangID, E.assistedSquatsID, E.parallelBarSupportID,
                E.plankID, E.inclineRowsID, E.wallPushUpsID
            ])
        #expect(items.map(\.pathID) == [.pullUp, .legs, .dip, .core, .row, .pushUp])
        #expect(items.map(\.group) == [1, 1, 2, 2, 3, 3])
        #expect(items.allSatisfy { $0.restSeconds == 90 && $0.targetSets == 3 })
        // Holds 3 × 10–30 s, reps 3 × 5–8.
        let deadHang = items[0]
        #expect(deadHang.targetSecondsMin == 10 && deadHang.targetSeconds == 30)
        #expect(deadHang.targetReps == nil && deadHang.targetRepsMin == nil)
        let squats = items[1]
        #expect(squats.targetRepsMin == 5 && squats.targetReps == 8)
        #expect(squats.targetSeconds == nil)
    }

    @Test
    func fundamentalsForAnAdvancedAthleteUsesTheirRungs() throws {
        let plan = try plan(ProgramCatalog.fundamentals, ProgramFixtures.advanced)
        let byPath = Dictionary(uniqueKeysWithValues: plan.exercises.compactMap { item in item.pathID.map { ($0, item) } })

        #expect(byPath[.pullUp]?.exerciseID == E.lPullUpsID)
        #expect(byPath[.pullUp]?.targetRepsMin == 3) // 3 × 5 rung → 3 × 3–5
        #expect(byPath[.pullUp]?.targetReps == 5)
        #expect(byPath[.dip]?.exerciseID == E.ringSupportHoldID)
        #expect(byPath[.dip]?.targetSecondsMin == 10) // 1 × 60 s rung → 3 × 10–60 s
        #expect(byPath[.dip]?.targetSeconds == 60)
        #expect(byPath[.legs]?.exerciseID == E.lungesID)
        #expect(byPath[.pushUp]?.exerciseID == E.diamondPushUpsID)
    }

    // MARK: Pierwsze podciągnięcie

    @Test
    func firstPullUpWithZeroPullUpsStartsOnNegatives() throws {
        let plan = try plan(ProgramCatalog.firstPullUp, ProgramFixtures.zeroPullUps)
        let items = plan.exercises

        #expect(items.map(\.exerciseID) == [E.negativePullUpsID, E.inclineRowsID, E.kneePushUpsID, E.assistedSquatsID])
        #expect(items[0].targetSets == 3 && items[0].targetRepsMin == 3 && items[0].targetReps == 5)
        #expect(items[0].group == nil && items[0].restSeconds == nil)
        #expect(items[2].group == 1 && items[3].group == 1)
        #expect(items[2].restSeconds == 90)
    }

    @Test
    func firstPullUpSkipsTheBandTrackOnceNegativesAreConquered() throws {
        let logs = [ProgramFixtures.reps(E.negativePullUpsID, 5)]
        let states = ProgramFixtures.states(placement: nil, logs: logs)

        let plan = try plan(ProgramCatalog.firstPullUp, states)

        #expect(plan.exercises[0].exerciseID == E.pullUpsID)
        #expect(plan.exercises[0].targetRepsMin == 5 && plan.exercises[0].targetReps == 8)
    }

    // MARK: Skille

    @Test
    func skillsForANewcomerPracticeTheWallAndASupportedLSit() throws {
        let plan = try plan(ProgramCatalog.skills, ProgramFixtures.newcomer)

        #expect(plan.exercises.map(\.exerciseID) == [E.wallPlankID, E.footSupportedLSitID])
        #expect(plan.exercises[0].holdRungsOnly)
        #expect(plan.exercises[0].timeBoxMinutes == 10)
        #expect(plan.exercises[0].targetSets == nil)
        #expect(plan.exercises[1].totalSeconds == 180)
        #expect(plan.exercises[1].targetSecondsMin == 10 && plan.exercises[1].targetSeconds == 30)
        #expect(plan.schedule == .weekly([.tuesday, .thursday]))
    }

    @Test
    func skillsKeepToHeldRungsWhenTheLadderIsOnPushUps() throws {
        // The advanced athlete trains pike push-ups on the handstand ladder;
        // the skill block stays on the wall handstand hold below it.
        let plan = try plan(ProgramCatalog.skills, ProgramFixtures.advanced)

        #expect(plan.exercises.map(\.exerciseID) == [E.wallHandstandHoldID, E.lSitID])
    }

    // MARK: Dose

    @Test(
        arguments: [
            (E.pullUpsID, 3, 5...8), // 3 × 8
            (E.negativePullUpsID, 3, 3...5), // 3 × 5
            (E.negativeMuscleUpsID, 3, 2...3), // 3 × 3
            (E.deadHangID, 3, 10...30), // 3 × 30 s
            (E.tuckLSitID, 3, 10...20), // 3 × 20 s
            (E.plankShoulderTapsID, 3, 5...8) // off the ladders
        ] as [(UUID, Int, ClosedRange<Int>)])
    func ladderDoseFollowsTheRungCriterion(exerciseID: UUID, sets: Int, range: ClosedRange<Int>) throws {
        let exercise = try #require(E.exercise(withID: exerciseID))
        let dose = ProgramPrescriber.ladderDose(for: exercise)
        #expect(dose.sets == sets)
        #expect(dose.range == range)
    }
}

// MARK: - Following the ladder

@Suite("Program items follow the athlete's current rung")
struct ProgramResolutionTests {
    private static let deadHangItem = PlannedExercise(
        exerciseID: E.deadHangID, targetSets: 3, pathID: .pullUp,
        targetSeconds: 30, targetSecondsMin: 10, restSeconds: 90, group: 1)

    @Test
    func anItemMovesToTheNewRungWithItsDose() {
        let states = ProgramFixtures.states(logs: [ProgramFixtures.hold(E.deadHangID, 30)])

        let moved = ProgramPrescriber.resolved(Self.deadHangItem, pathStates: states)

        #expect(moved.id == Self.deadHangItem.id)
        #expect(moved.exerciseID == E.scapularPullsID)
        #expect(moved.targetSets == 3)
        #expect(moved.targetRepsMin == 5 && moved.targetReps == 8)
        #expect(moved.targetSeconds == nil && moved.targetSecondsMin == nil)
        #expect(moved.restSeconds == 90 && moved.group == 1 && moved.pathID == .pullUp)
    }

    @Test
    func anItemOnItsCurrentRungIsUnchanged() {
        #expect(ProgramPrescriber.resolved(Self.deadHangItem, pathStates: ProgramFixtures.newcomer) == Self.deadHangItem)
    }

    @Test
    func anItemWithoutALadderIsUnchanged() {
        let fixed = PlannedExercise(exerciseID: E.pushUpsID, targetSets: 3, targetReps: 12)
        #expect(ProgramPrescriber.resolved(fixed, pathStates: ProgramFixtures.advanced) == fixed)
    }

    @Test
    func aTimeBoxKeepsItsShapeOnTheNextHeldRung() {
        let practice = PlannedExercise(exerciseID: E.wallPlankID, pathID: .handstand, holdRungsOnly: true, timeBoxMinutes: 10)
        let states = ProgramFixtures.states(logs: [ProgramFixtures.hold(E.wallPlankID, 30)])

        let moved = ProgramPrescriber.resolved(practice, pathStates: states)

        #expect(moved.exerciseID == E.wallHandstandHoldID)
        #expect(moved.timeBoxMinutes == 10)
        #expect(moved.targetSets == nil && moved.targetSeconds == nil)
    }

    // MARK: Suggested values (+1 rep, RR)

    @Test
    func repsStartAtTheBottomOfTheRange() {
        let item = PlannedExercise(exerciseID: E.pullUpsID, targetSets: 3, targetReps: 8, targetRepsMin: 5)
        #expect(ProgramPrescriber.suggestedValue(for: item, measurement: .reps, logs: []) == 5)
    }

    @Test
    func repsAddOneToTheLastSessionWithinTheRange() {
        let item = PlannedExercise(exerciseID: E.pullUpsID, targetSets: 3, targetReps: 8, targetRepsMin: 5)
        let earlier = ProgramFixtures.reps(E.pullUpsID, 7, on: ProgramFixtures.today.addingTimeInterval(-7 * 86_400))
        let last = ProgramFixtures.reps(E.pullUpsID, 6, on: ProgramFixtures.today.addingTimeInterval(-2 * 86_400))
        let capped = ProgramFixtures.reps(E.pullUpsID, 9, on: ProgramFixtures.today.addingTimeInterval(-86_400))

        #expect(ProgramPrescriber.suggestedValue(for: item, measurement: .reps, logs: [earlier, last]) == 7)
        #expect(ProgramPrescriber.suggestedValue(for: item, measurement: .reps, logs: [earlier, last, capped]) == 8)
    }

    @Test
    func holdsStartFromTheLastBestWithinTheRange() {
        let item = PlannedExercise(exerciseID: E.plankID, targetSets: 3, targetSeconds: 30, targetSecondsMin: 10)
        #expect(ProgramPrescriber.suggestedValue(for: item, measurement: .seconds, logs: []) == 10)
        #expect(
            ProgramPrescriber.suggestedValue(
                for: item, measurement: .seconds,
                logs: [ProgramFixtures.hold(E.plankID, 22)]) == 22)
    }

    @Test
    func noTargetMeansNoSuggestion() {
        let circuit = PlannedExercise(exerciseID: E.pushUpsID, rounds: 2...6, repsInReserve: 2)
        #expect(ProgramPrescriber.suggestedValue(for: circuit, measurement: .reps, logs: []) == nil)
    }
}

// MARK: - Suggestions

@Suite("Which program to suggest")
struct ProgramSuggestionTests {
    @Test(
        arguments: [
            (nil, .fundamentals),
            (.some(.none), .firstPullUp),
            (.some(.few), .fundamentals),
            (.some(.several), .fundamentals),
            (.some(.many), .fundamentals)
        ] as [(RepCountBucket?, ProgramID)])
    func zeroPullUpsSuggestsFirstPullUp(answer: RepCountBucket?, expected: ProgramID) {
        let placement = PlacementCalibration.placement(
            repAnswers: answer.map { [.pullUp: $0] } ?? [:],
            masteredSkills: [],
            ownsBand: false,
            declaredAt: ProgramFixtures.today
        )
        #expect(ProgramPrescriber.suggestedProgram(for: placement) == expected)
    }

    @Test
    func fundamentalsHintsAtFirstPullUpBelowFullPullUps() {
        #expect(ProgramPrescriber.needsFirstPullUp(ProgramFixtures.newcomer))
        #expect(ProgramPrescriber.needsFirstPullUp(ProgramFixtures.zeroPullUps))
        #expect(ProgramPrescriber.needsFirstPullUp(ProgramFixtures.advanced) == false)
    }

    @Test
    func firstPullUpGraduatesAtThreeByEightPullUps() throws {
        let plan = try #require(
            ProgramPrescriber.plans(
                for: ProgramCatalog.firstPullUp,
                pathStates: ProgramFixtures.newcomer,
                today: ProgramFixtures.today
            ).first)
        let almost = ProgramFixtures.states(logs: [ProgramFixtures.reps(E.pullUpsID, 7)])
        let done = ProgramFixtures.states(logs: [ProgramFixtures.reps(E.pullUpsID, 8)])

        #expect(ProgramPrescriber.isReadyToGraduate(plan, pathStates: almost) == false)
        #expect(ProgramPrescriber.isReadyToGraduate(plan, pathStates: done))

        var other = plan
        other.programID = ProgramID.fundamentals.rawValue
        #expect(ProgramPrescriber.isReadyToGraduate(other, pathStates: done) == false)
    }
}
