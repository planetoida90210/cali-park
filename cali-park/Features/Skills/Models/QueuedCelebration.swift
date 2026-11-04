import Foundation

// MARK: - QueuedCelebration
/// One overlay in `RewardCenter`'s queue: a single advance, or the rungs that
/// came in together, shown as one card.
///
/// One save can clear several rungs at once (a first logged workout often
/// clears five or six). They read as one moment, "6 nowych szczebli", instead
/// of six overlays in a row; a level-up still follows on its own card.
/// Dismissing the card marks each of its rungs as celebrated.
nonisolated enum QueuedCelebration: Equatable, Hashable, Identifiable, Sendable {
    /// One advance: a rung conquered alone, or a level reached.
    case single(CelebrationEvent)
    /// Two or more rungs conquered together, in display order.
    case rungs([RungReference])

    /// The advances this overlay celebrates, in display order.
    var events: [CelebrationEvent] {
        switch self {
        case .single(let event): [event]
        case .rungs(let rungs): rungs.map(CelebrationEvent.rungConquered)
        }
    }

    /// A stable identity: it replays the haptic and the entrance pulse only
    /// when the overlay shows something else.
    var id: String {
        switch self {
        case .single(let event): event.id
        case .rungs: "rungs-" + events.map(\.id).joined(separator: "+")
        }
    }

    /// The overlays for `events` (as `RewardEvaluator` orders them: rungs
    /// first, then level-ups): the rungs waiting together become one card when
    /// there are two or more, every other event keeps its own.
    static func grouping(_ events: [CelebrationEvent]) -> [QueuedCelebration] {
        var queue: [QueuedCelebration] = []
        var rungs: [RungReference] = []

        func flushRungs() {
            switch rungs.count {
            case 0: break
            case 1: queue.append(.single(.rungConquered(rungs[0])))
            default: queue.append(.rungs(rungs))
            }
            rungs = []
        }

        for event in events {
            if case .rungConquered(let rung) = event {
                rungs.append(rung)
            } else {
                flushRungs()
                queue.append(.single(event))
            }
        }
        flushRungs()
        return queue
    }
}
