import Foundation

// MARK: - ProgressionCatalog
/// Built-in, production definition of every calisthenics progression path.
///
/// This is a 1:1 encoding of `docs/PROGRESSIONS.md`, which cites the sources
/// for each ladder (Recommended Routine, Overcoming Gravity 2, GMB,
/// StartBodyweight, Cali Move). Every step references a `ExerciseCatalog`
/// exercise by ID, so there is a single source of truth: the ladder is a map
/// and a yardstick, never a gate. Paths are fully independent — nothing here
/// links one to another beyond the non-binding `recommendedBase` note.
///
/// Rungs are identified by exercise ID, so saved placements and celebrated
/// rungs survive inserting or reordering rungs (see `RungReference`). Change
/// the order only together with `PROGRESSIONS.md` and the frozen order in
/// `LadderOrderSnapshotTests`.
///
/// One-time XP jump from the 2026-11 revision (ticket 015, accepted by the
/// owner): the engine counts every rung below the highest conquered one as
/// conquered, and `ProgressionEngine.experiencePoints` pays
/// `xpPerConqueredRung` (100) per conquered rung. So a rung inserted below an
/// athlete's highest conquered rung raises their XP once, without training.
/// Example: 3 × 8 full pull-ups conquered 5 pull-up rungs before (500 XP) and
/// 6 after the arch hang went in (600 XP), +100 XP. A wall handstand push-up
/// 3 × 5 goes from 3 to 6 handstand rungs, +300 XP. Celebrations are keyed by
/// exercise ID, so nothing already celebrated plays again.
enum ProgressionCatalog {
    // MARK: Shared criteria
    // Dynamic ladders advance on Recommended Routine's "3 × 8 clean → next";
    // harder rep rungs (negatives, unilateral skills) use lower counts, which
    // is our own convention. Isometric ladders advance on 3 × 20 s, derived
    // from the OG2 isometrics table; entry holds get RR's 3 × 30 s, and full
    // skills use a single clean hold as the "you own it" marker (ours).
    private static let reps3x8 = AdvancementCriterion.setsOfReps(sets: 3, reps: 8)
    private static let reps3x5 = AdvancementCriterion.setsOfReps(sets: 3, reps: 5)
    private static let reps3x3 = AdvancementCriterion.setsOfReps(sets: 3, reps: 3)
    private static let firstCleanRep = AdvancementCriterion.setsOfReps(sets: 1, reps: 1)
    private static let hold3x30 = AdvancementCriterion.setsOfHold(sets: 3, seconds: 30)
    private static let hold3x20 = AdvancementCriterion.setsOfHold(sets: 3, seconds: 20)
    private static let hold1x60 = AdvancementCriterion.setsOfHold(sets: 1, seconds: 60)
    private static let firstFiveSecondHold = AdvancementCriterion.setsOfHold(sets: 1, seconds: 5)

    // Criterion notes: what a rep must look like when "3 × 5" can't say it.
    private static let slowDescent = "zjazd 5–10 s"

    // MARK: Lookup
    /// The path with the given identifier, or `nil` if none matches.
    static func path(withID id: ProgressionPathID) -> ProgressionPath? {
        byID[id]
    }

    /// Every path whose ladder includes the given exercise as a rung — used to
    /// link a movement's detail screen to the progressions it belongs to.
    /// Usually one path; empty for an exercise no ladder references.
    static func paths(containing exerciseID: UUID) -> [ProgressionPath] {
        all.filter { path in path.steps.contains { $0.exerciseID == exerciseID } }
    }

    private static let byID: [ProgressionPathID: ProgressionPath] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.id, $0) }
    )

    // MARK: Paths
    static let all: [ProgressionPath] = [
        pullUp, row, pushUp, dip, legs, core, muscleUp,
        lSit, frontLever, backLever, planche, humanFlag, handstand
    ]

    // MARK: Dynamic ladders (Recommended Routine)
    private static let pullUp = ProgressionPath(
        id: .pullUp,
        name: "Podciąganie",
        symbolName: "figure.climbing",
        steps: [
            ProgressionStep(exerciseID: ExerciseCatalog.deadHangID, criterion: hold3x30, source: .rr, equipment: ["Pull-up bar"]),
            ProgressionStep(exerciseID: ExerciseCatalog.scapularPullsID, criterion: reps3x8, source: .rr, note: "pauza 3–5 s na górze", equipment: ["Pull-up bar"]),
            ProgressionStep(exerciseID: ExerciseCatalog.archHangID, criterion: reps3x8, source: .rr, equipment: ["Pull-up bar"]),
            ProgressionStep(exerciseID: ExerciseCatalog.negativePullUpsID, criterion: reps3x5, source: .caliPark, note: slowDescent, equipment: ["Pull-up bar"]),
            ProgressionStep(exerciseID: ExerciseCatalog.bandPullUpsID, criterion: reps3x8, source: .rr, equipment: ["Pull-up bar", "Resistance bands"], isParallelTrack: true),
            ProgressionStep(exerciseID: ExerciseCatalog.pullUpsID, criterion: reps3x8, source: .rr, equipment: ["Pull-up bar"]),
            ProgressionStep(exerciseID: ExerciseCatalog.lPullUpsID, criterion: reps3x5, source: .caliPark, equipment: ["Pull-up bar"]),
            ProgressionStep(exerciseID: ExerciseCatalog.archerPullUpsID, criterion: reps3x5, source: .sbw, equipment: ["Pull-up bar"])
        ]
    )

    private static let row = ProgressionPath(
        id: .row,
        name: "Wiosłowanie",
        symbolName: "figure.play",
        steps: [
            ProgressionStep(exerciseID: ExerciseCatalog.inclineRowsID, criterion: reps3x8, source: .rr, equipment: ["Pull-up bar", "Parallel bars"]),
            ProgressionStep(exerciseID: ExerciseCatalog.australianPullUpsID, criterion: reps3x8, source: .rr, equipment: ["Pull-up bar", "Parallel bars"]),
            ProgressionStep(exerciseID: ExerciseCatalog.wideRowsID, criterion: reps3x8, source: .rr, equipment: ["Pull-up bar", "Parallel bars"]),
            ProgressionStep(exerciseID: ExerciseCatalog.archerRowsID, criterion: reps3x5, source: .caliPark, equipment: ["Pull-up bar", "Parallel bars"]),
            ProgressionStep(exerciseID: ExerciseCatalog.tuckFrontLeverRowsID, criterion: reps3x8, source: .rr,
                            tip: "RR najpierw chce 20–30 s tuck front levera.", equipment: ["Pull-up bar", "Rings"])
        ],
        recommendedBase: "Wiosłowanie i podciąganie budują się razem — to dwie strony siły pleców."
    )

    private static let pushUp = ProgressionPath(
        id: .pushUp,
        name: "Pompki",
        symbolName: "figure.strengthtraining.traditional",
        steps: [
            ProgressionStep(exerciseID: ExerciseCatalog.wallPushUpsID, criterion: reps3x8, source: .rr),
            ProgressionStep(exerciseID: ExerciseCatalog.inclinePushUpsID, criterion: reps3x8, source: .rr),
            ProgressionStep(exerciseID: ExerciseCatalog.kneePushUpsID, criterion: reps3x8, source: .rr),
            ProgressionStep(exerciseID: ExerciseCatalog.pushUpsID, criterion: reps3x8, source: .rr),
            ProgressionStep(exerciseID: ExerciseCatalog.diamondPushUpsID, criterion: reps3x8, source: .rr),
            ProgressionStep(exerciseID: ExerciseCatalog.pseudoPlanchePushUpsID, criterion: reps3x8, source: .rr)
        ]
    )

    private static let dip = ProgressionPath(
        id: .dip,
        name: "Dipy",
        symbolName: "figure.strengthtraining.traditional",
        steps: [
            ProgressionStep(exerciseID: ExerciseCatalog.parallelBarSupportID, criterion: hold3x30, source: .rr, equipment: ["Dip bar", "Parallel bars"]),
            ProgressionStep(exerciseID: ExerciseCatalog.negativeDipsID, criterion: reps3x5, source: .caliPark, note: slowDescent, equipment: ["Dip bar", "Parallel bars"]),
            ProgressionStep(exerciseID: ExerciseCatalog.dipsID, criterion: reps3x8, source: .rr, equipment: ["Dip bar", "Parallel bars"]),
            ProgressionStep(exerciseID: ExerciseCatalog.ringSupportHoldID, criterion: hold1x60, source: .rr,
                            note: "docelowo z kółkami obróconymi na zewnątrz", equipment: ["Rings"]),
            ProgressionStep(exerciseID: ExerciseCatalog.ringDipsID, criterion: reps3x8, source: .rr, equipment: ["Rings"])
        ]
    )

    private static let legs = ProgressionPath(
        id: .legs,
        name: "Nogi",
        symbolName: "figure.strengthtraining.functional",
        steps: [
            ProgressionStep(exerciseID: ExerciseCatalog.assistedSquatsID, criterion: reps3x8, source: .rr),
            ProgressionStep(exerciseID: ExerciseCatalog.squatsID, criterion: reps3x8, source: .rr),
            ProgressionStep(exerciseID: ExerciseCatalog.lungesID, criterion: reps3x8, source: .rr),
            ProgressionStep(exerciseID: ExerciseCatalog.splitSquatID, criterion: reps3x8, source: .rr),
            ProgressionStep(exerciseID: ExerciseCatalog.bulgarianSplitSquatID, criterion: reps3x8, source: .rr),
            ProgressionStep(exerciseID: ExerciseCatalog.stepUpsID, criterion: reps3x8, source: .rr, isParallelTrack: true),
            ProgressionStep(exerciseID: ExerciseCatalog.assistedPistolSquatsID, criterion: reps3x5, source: .caliPark),
            ProgressionStep(exerciseID: ExerciseCatalog.pistolSquatsID, criterion: reps3x5, source: .caliPark)
        ]
    )

    private static let core = ProgressionPath(
        id: .core,
        name: "Core",
        symbolName: "figure.core.training",
        steps: [
            ProgressionStep(exerciseID: ExerciseCatalog.plankID, criterion: hold3x30, source: .rr),
            ProgressionStep(exerciseID: ExerciseCatalog.hangingKneeRaisesID, criterion: reps3x8, source: .rr, equipment: ["Pull-up bar"]),
            ProgressionStep(exerciseID: ExerciseCatalog.hangingLegRaisesID, criterion: reps3x8, source: .rr, equipment: ["Pull-up bar"]),
            ProgressionStep(exerciseID: ExerciseCatalog.toesToBarID, criterion: reps3x8, source: .rr, equipment: ["Pull-up bar"])
        ]
    )

    private static let muscleUp = ProgressionPath(
        id: .muscleUp,
        name: "Muscle-up",
        symbolName: "figure.gymnastics",
        steps: [
            ProgressionStep(exerciseID: ExerciseCatalog.chestToBarPullUpsID, criterion: reps3x5, source: .caliPark, equipment: ["Pull-up bar"]),
            ProgressionStep(exerciseID: ExerciseCatalog.negativeMuscleUpsID, criterion: reps3x3, source: .caliPark, equipment: ["Pull-up bar", "Rings"]),
            ProgressionStep(exerciseID: ExerciseCatalog.kippingMuscleUpsID, criterion: reps3x3, source: .caliPark, equipment: ["Pull-up bar", "Rings"]),
            ProgressionStep(exerciseID: ExerciseCatalog.muscleUpID, criterion: firstCleanRep, source: .caliPark, equipment: ["Pull-up bar", "Rings"])
        ],
        recommendedBase: "Większość osób buduje muscle-upa na bazie pewnych podciągnięć i dipów."
    )

    // MARK: Isometric ladders (Overcoming Gravity 2)
    private static let lSit = ProgressionPath(
        id: .lSit,
        name: "L-sit",
        symbolName: "figure.core.training",
        steps: [
            ProgressionStep(exerciseID: ExerciseCatalog.footSupportedLSitID, criterion: hold3x20, source: .og2Table, equipment: ["Parallel bars", "Push-up handles"]),
            ProgressionStep(exerciseID: ExerciseCatalog.oneFootSupportedLSitID, criterion: hold3x20, source: .og2Table, equipment: ["Parallel bars", "Push-up handles"]),
            ProgressionStep(exerciseID: ExerciseCatalog.tuckLSitID, criterion: hold3x20, source: .og2Table, equipment: ["Parallel bars", "Push-up handles"]),
            ProgressionStep(exerciseID: ExerciseCatalog.oneLegLSitID, criterion: hold3x20, source: .og2Table, equipment: ["Parallel bars", "Push-up handles"]),
            ProgressionStep(exerciseID: ExerciseCatalog.lSitID, criterion: hold3x20, source: .og2Table, equipment: ["Parallel bars", "Push-up handles"])
        ]
    )

    private static let frontLever = ProgressionPath(
        id: .frontLever,
        name: "Front lever",
        symbolName: "figure.gymnastics",
        steps: [
            ProgressionStep(exerciseID: ExerciseCatalog.tuckFrontLeverID, criterion: hold3x20, source: .og2Table,
                            tip: "RR przed tuckiem: skin the cat 5 × 2 i zwis z wygięciem 3 × 8.", equipment: ["Pull-up bar", "Rings"]),
            ProgressionStep(exerciseID: ExerciseCatalog.advancedTuckFrontLeverID, criterion: hold3x20, source: .og2Table, equipment: ["Pull-up bar", "Rings"]),
            ProgressionStep(exerciseID: ExerciseCatalog.straddleFrontLeverID, criterion: hold3x20, source: .og2Table, equipment: ["Pull-up bar", "Rings"]),
            ProgressionStep(exerciseID: ExerciseCatalog.halfLayFrontLeverID, criterion: hold3x20, source: .og2Table, equipment: ["Pull-up bar", "Rings"]),
            ProgressionStep(exerciseID: ExerciseCatalog.frontLeverID, criterion: firstFiveSecondHold, source: .caliPark, equipment: ["Pull-up bar", "Rings"])
        ],
        recommendedBase: "Zwykle buduje się na bazie mocnych podciągnięć i wiosłowania."
    )

    private static let backLever = ProgressionPath(
        id: .backLever,
        name: "Back lever",
        symbolName: "figure.gymnastics",
        steps: [
            ProgressionStep(exerciseID: ExerciseCatalog.germanHangID, criterion: hold3x30, source: .rr, equipment: ["Pull-up bar", "Rings"]),
            ProgressionStep(exerciseID: ExerciseCatalog.skinTheCatID, criterion: reps3x5, source: .caliPark, equipment: ["Pull-up bar", "Rings"]),
            ProgressionStep(exerciseID: ExerciseCatalog.tuckBackLeverID, criterion: hold3x20, source: .og2Table, equipment: ["Pull-up bar", "Rings"]),
            ProgressionStep(exerciseID: ExerciseCatalog.advancedTuckBackLeverID, criterion: hold3x20, source: .og2Table, equipment: ["Pull-up bar", "Rings"]),
            ProgressionStep(exerciseID: ExerciseCatalog.straddleBackLeverID, criterion: hold3x20, source: .og2Table, equipment: ["Pull-up bar", "Rings"]),
            ProgressionStep(exerciseID: ExerciseCatalog.halfLayBackLeverID, criterion: hold3x20, source: .og2Table, equipment: ["Pull-up bar", "Rings"]),
            ProgressionStep(exerciseID: ExerciseCatalog.backLeverID, criterion: firstFiveSecondHold, source: .caliPark, equipment: ["Pull-up bar", "Rings"])
        ]
    )

    private static let planche = ProgressionPath(
        id: .planche,
        name: "Planche",
        symbolName: "figure.gymnastics",
        steps: [
            ProgressionStep(exerciseID: ExerciseCatalog.frogStandID, criterion: hold3x30, source: .rr),
            ProgressionStep(exerciseID: ExerciseCatalog.straightArmFrogStandID, criterion: hold3x20, source: .og2Table),
            ProgressionStep(exerciseID: ExerciseCatalog.tuckPlancheID, criterion: hold3x20, source: .og2Table, equipment: ["Push-up handles", "Parallel bars"]),
            ProgressionStep(exerciseID: ExerciseCatalog.advancedTuckPlancheID, criterion: hold3x20, source: .og2Table, equipment: ["Push-up handles", "Parallel bars"]),
            ProgressionStep(exerciseID: ExerciseCatalog.straddlePlancheID, criterion: hold3x20, source: .og2Table, equipment: ["Push-up handles", "Parallel bars"]),
            ProgressionStep(exerciseID: ExerciseCatalog.halfLayPlancheID, criterion: hold3x20, source: .og2Table, equipment: ["Push-up handles", "Parallel bars"]),
            ProgressionStep(exerciseID: ExerciseCatalog.plancheID, criterion: firstFiveSecondHold, source: .caliPark, equipment: ["Push-up handles", "Parallel bars"])
        ],
        recommendedBase: "Zwykle buduje się na bazie pompek pseudo-planche i mocnych barków."
    )

    private static let humanFlag = ProgressionPath(
        id: .humanFlag,
        name: "Flaga",
        symbolName: "figure.climbing",
        steps: [
            ProgressionStep(exerciseID: ExerciseCatalog.verticalFlagSupportID, criterion: hold3x20, source: .caliPark, equipment: ExerciseCatalog.flagEquipment),
            ProgressionStep(exerciseID: ExerciseCatalog.tuckFlagID, criterion: hold3x20, source: .og2Table, equipment: ExerciseCatalog.flagEquipment),
            ProgressionStep(exerciseID: ExerciseCatalog.advancedTuckFlagID, criterion: hold3x20, source: .og2Table, equipment: ExerciseCatalog.flagEquipment),
            ProgressionStep(exerciseID: ExerciseCatalog.straddleFlagID, criterion: hold3x20, source: .og2Table, equipment: ExerciseCatalog.flagEquipment),
            ProgressionStep(exerciseID: ExerciseCatalog.humanFlagID, criterion: firstFiveSecondHold, source: .caliPark, equipment: ExerciseCatalog.flagEquipment)
        ]
    )

    private static let handstand = ProgressionPath(
        id: .handstand,
        name: "Stanie na rękach",
        symbolName: "figure.gymnastics",
        steps: [
            ProgressionStep(exerciseID: ExerciseCatalog.wallPlankID, criterion: hold3x30, source: .rr),
            ProgressionStep(exerciseID: ExerciseCatalog.wallHandstandHoldID, criterion: hold3x30, source: .rr),
            ProgressionStep(exerciseID: ExerciseCatalog.pikePushUpsID, criterion: reps3x8, source: .rr),
            ProgressionStep(exerciseID: ExerciseCatalog.elevatedPikePushUpsID, criterion: reps3x8, source: .rr),
            ProgressionStep(exerciseID: ExerciseCatalog.wallHandstandPushUpNegativesID, criterion: reps3x5, source: .caliPark, note: slowDescent),
            ProgressionStep(exerciseID: ExerciseCatalog.wallHandstandPushUpsID, criterion: reps3x5, source: .caliPark)
        ]
    )
}
