import Foundation

// MARK: - LadderOrderV1
/// The rung order of every ladder as it was when placements and celebrated
/// rungs were stored as array indices (store schema version 1).
///
/// Version 1 files say "pull-up rung 4", and that only means something against
/// the ladder order that wrote it. This table freezes that order, so old files
/// keep resolving to the same exercises after the live `ProgressionCatalog`
/// inserts, removes or reorders rungs. Never edit it: it describes data already
/// on users' devices, not the current ladders.
enum LadderOrderV1 {
    /// The exercise ID of the rung at a version 1 index, or `nil` when the
    /// index was never valid for that path.
    static func stepID(for path: ProgressionPathID, rungIndex: Int) -> UUID? {
        guard let steps = stepIDs[path], steps.indices.contains(rungIndex) else { return nil }
        return steps[rungIndex]
    }

    /// Exercise IDs per path, in version 1 rung order.
    static let stepIDs: [ProgressionPathID: [UUID]] = [
        .pullUp: [
            UUID(uuidString: "E0000000-0000-4000-8000-000000000020")!, // 0: deadHang
            UUID(uuidString: "E0000000-0000-4000-8000-000000000021")!, // 1: scapularPulls
            UUID(uuidString: "E0000000-0000-4000-8000-000000000022")!, // 2: negativePullUps
            UUID(uuidString: "E0000000-0000-4000-8000-000000000023")!, // 3: bandPullUps
            UUID(uuidString: "E0000000-0000-4000-8000-000000000001")!, // 4: pullUps
            UUID(uuidString: "E0000000-0000-4000-8000-000000000025")!, // 5: lPullUps
            UUID(uuidString: "E0000000-0000-4000-8000-000000000012")! // 6: archerPullUps
        ],
        .row: [
            UUID(uuidString: "E0000000-0000-4000-8000-000000000026")!, // 0: inclineRows
            UUID(uuidString: "E0000000-0000-4000-8000-000000000007")!, // 1: australianPullUps
            UUID(uuidString: "E0000000-0000-4000-8000-000000000027")!, // 2: wideRows
            UUID(uuidString: "E0000000-0000-4000-8000-000000000028")!, // 3: archerRows
            UUID(uuidString: "E0000000-0000-4000-8000-000000000029")! // 4: tuckFrontLeverRows
        ],
        .pushUp: [
            UUID(uuidString: "E0000000-0000-4000-8000-000000000030")!, // 0: wallPushUps
            UUID(uuidString: "E0000000-0000-4000-8000-000000000031")!, // 1: inclinePushUps
            UUID(uuidString: "E0000000-0000-4000-8000-000000000032")!, // 2: kneePushUps
            UUID(uuidString: "E0000000-0000-4000-8000-000000000002")!, // 3: pushUps
            UUID(uuidString: "E0000000-0000-4000-8000-000000000033")!, // 4: diamondPushUps
            UUID(uuidString: "E0000000-0000-4000-8000-000000000034")! // 5: pseudoPlanchePushUps
        ],
        .dip: [
            UUID(uuidString: "E0000000-0000-4000-8000-000000000035")!, // 0: parallelBarSupport
            UUID(uuidString: "E0000000-0000-4000-8000-000000000036")!, // 1: negativeDips
            UUID(uuidString: "E0000000-0000-4000-8000-000000000003")!, // 2: dips
            UUID(uuidString: "E0000000-0000-4000-8000-000000000013")! // 3: ringDips
        ],
        .legs: [
            UUID(uuidString: "E0000000-0000-4000-8000-000000000037")!, // 0: assistedSquats
            UUID(uuidString: "E0000000-0000-4000-8000-000000000004")!, // 1: squats
            UUID(uuidString: "E0000000-0000-4000-8000-000000000005")!, // 2: lunges
            UUID(uuidString: "E0000000-0000-4000-8000-000000000038")!, // 3: stepUps
            UUID(uuidString: "E0000000-0000-4000-8000-000000000039")!, // 4: assistedPistolSquats
            UUID(uuidString: "E0000000-0000-4000-8000-000000000009")! // 5: pistolSquats
        ],
        .core: [
            UUID(uuidString: "E0000000-0000-4000-8000-000000000006")!, // 0: plank
            UUID(uuidString: "E0000000-0000-4000-8000-000000000040")!, // 1: hangingKneeRaises
            UUID(uuidString: "E0000000-0000-4000-8000-000000000008")!, // 2: hangingLegRaises
            UUID(uuidString: "E0000000-0000-4000-8000-000000000041")! // 3: toesToBar
        ],
        .muscleUp: [
            UUID(uuidString: "E0000000-0000-4000-8000-000000000024")!, // 0: chestToBarPullUps
            UUID(uuidString: "E0000000-0000-4000-8000-000000000042")!, // 1: negativeMuscleUps
            UUID(uuidString: "E0000000-0000-4000-8000-000000000043")!, // 2: kippingMuscleUps
            UUID(uuidString: "E0000000-0000-4000-8000-000000000015")! // 3: muscleUp
        ],
        .lSit: [
            UUID(uuidString: "E0000000-0000-4000-8000-000000000044")!, // 0: footSupportedLSit
            UUID(uuidString: "E0000000-0000-4000-8000-000000000045")!, // 1: oneLegLSit
            UUID(uuidString: "E0000000-0000-4000-8000-000000000046")!, // 2: tuckLSit
            UUID(uuidString: "E0000000-0000-4000-8000-000000000011")! // 3: lSit
        ],
        .frontLever: [
            UUID(uuidString: "E0000000-0000-4000-8000-000000000047")!, // 0: tuckFrontLever
            UUID(uuidString: "E0000000-0000-4000-8000-000000000048")!, // 1: advancedTuckFrontLever
            UUID(uuidString: "E0000000-0000-4000-8000-000000000049")!, // 2: straddleFrontLever
            UUID(uuidString: "E0000000-0000-4000-8000-000000000050")!, // 3: halfLayFrontLever
            UUID(uuidString: "E0000000-0000-4000-8000-000000000016")! // 4: frontLever
        ],
        .backLever: [
            UUID(uuidString: "E0000000-0000-4000-8000-000000000051")!, // 0: germanHang
            UUID(uuidString: "E0000000-0000-4000-8000-000000000052")!, // 1: skinTheCat
            UUID(uuidString: "E0000000-0000-4000-8000-000000000053")!, // 2: tuckBackLever
            UUID(uuidString: "E0000000-0000-4000-8000-000000000054")!, // 3: advancedTuckBackLever
            UUID(uuidString: "E0000000-0000-4000-8000-000000000055")!, // 4: straddleBackLever
            UUID(uuidString: "E0000000-0000-4000-8000-000000000056")!, // 5: halfLayBackLever
            UUID(uuidString: "E0000000-0000-4000-8000-000000000019")! // 6: backLever
        ],
        .planche: [
            UUID(uuidString: "E0000000-0000-4000-8000-000000000057")!, // 0: frogStand
            UUID(uuidString: "E0000000-0000-4000-8000-000000000058")!, // 1: tuckPlanche
            UUID(uuidString: "E0000000-0000-4000-8000-000000000059")!, // 2: advancedTuckPlanche
            UUID(uuidString: "E0000000-0000-4000-8000-000000000060")!, // 3: straddlePlanche
            UUID(uuidString: "E0000000-0000-4000-8000-000000000018")! // 4: planche
        ],
        .humanFlag: [
            UUID(uuidString: "E0000000-0000-4000-8000-000000000061")!, // 0: verticalFlagSupport
            UUID(uuidString: "E0000000-0000-4000-8000-000000000062")!, // 1: tuckFlag
            UUID(uuidString: "E0000000-0000-4000-8000-000000000063")!, // 2: straddleFlag
            UUID(uuidString: "E0000000-0000-4000-8000-000000000017")! // 3: humanFlag
        ],
        .handstand: [
            UUID(uuidString: "E0000000-0000-4000-8000-000000000064")!, // 0: wallPlank
            UUID(uuidString: "E0000000-0000-4000-8000-000000000065")!, // 1: wallHandstandHold
            UUID(uuidString: "E0000000-0000-4000-8000-000000000010")! // 2: wallHandstandPushUps
        ]
    ]
}
