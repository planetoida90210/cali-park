import Foundation

// MARK: - CelebrationPresentation
/// The resolved copy and symbol for one `CelebrationEvent`, ready to render.
///
/// Kept separate from the event so the event stays a pure reference and the
/// display strings — Polish copy, tuned for a celebratory moment — live in one
/// testable place. Resolution reads only the static catalogs, so it is pure.
nonisolated struct CelebrationPresentation: Equatable, Sendable {
    /// Short eyebrow above the title, e.g. "ZALICZONY SZCZEBEL".
    let eyebrow: String
    /// The headline: the conquered exercise, or "Poziom 3".
    let title: String
    /// Supporting context, e.g. the path name; `nil` when the title stands alone.
    let subtitle: String?
    /// The conquered exercises, one per line, when one card celebrates
    /// several rungs; empty otherwise.
    let list: [String]
    /// A concrete XP note when the advance grants a fixed bonus; else `nil`.
    let xpNote: String?
    /// SF Symbol in the app's Watch-Workout style.
    let symbolName: String
    /// A single spoken sentence for VoiceOver.
    let accessibilityLabel: String

    init(
        eyebrow: String,
        title: String,
        subtitle: String?,
        list: [String] = [],
        xpNote: String?,
        symbolName: String,
        accessibilityLabel: String
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.list = list
        self.xpNote = xpNote
        self.symbolName = symbolName
        self.accessibilityLabel = accessibilityLabel
    }

    /// The presentation for an event, resolved from the catalogs.
    static func resolving(_ event: CelebrationEvent) -> CelebrationPresentation {
        switch event {
        case .rungConquered(let rung): rungPresentation(rung)
        case .levelReached(let level): levelPresentation(level)
        }
    }

    /// The presentation for one overlay of the reward queue: a single event,
    /// or the card for several rungs conquered together.
    static func resolving(_ celebration: QueuedCelebration) -> CelebrationPresentation {
        switch celebration {
        case .single(let event): resolving(event)
        case .rungs(let rungs): rungsPresentation(rungs)
        }
    }

    /// The same presentation with the batch's real XP total added, for the
    /// last overlay of a batch: "+100 XP · Razem +740 XP".
    func addingTotalXP(_ total: Int) -> CelebrationPresentation {
        let note = String(localized: "Razem +\(total) XP")
        return CelebrationPresentation(
            eyebrow: eyebrow,
            title: title,
            subtitle: subtitle,
            list: list,
            xpNote: xpNote.map { "\($0) · \(note)" } ?? note,
            symbolName: symbolName,
            accessibilityLabel: "\(accessibilityLabel) \(note)."
        )
    }

    // MARK: Rung

    private static func rungPresentation(_ rung: RungReference) -> CelebrationPresentation {
        let path = ProgressionCatalog.path(withID: rung.pathID)
        let step = rung.step
        let exerciseName = step.flatMap { ExerciseCatalog.exercise(withID: $0.exerciseID)?.name } ?? String(localized: "Nowy szczebel")
        let pathName = path?.name
        let xpNote = String(localized: "+\(ProgressionEngine.xpPerConqueredRung) XP")

        let accessibilityLabel =
            if let pathName {
                String(localized: "Zaliczony szczebel: \(exerciseName) na ścieżce \(pathName). \(xpNote).")
            } else {
                String(localized: "Zaliczony szczebel: \(exerciseName). \(xpNote).")
            }
        return CelebrationPresentation(
            eyebrow: String(localized: "ZALICZONY SZCZEBEL"),
            title: exerciseName,
            subtitle: pathName,
            xpNote: xpNote,
            symbolName: path?.symbolName ?? "checkmark.seal.fill",
            accessibilityLabel: accessibilityLabel
        )
    }

    // MARK: Several rungs

    /// "6 nowych szczebli", the exercises listed under it, the paths they are
    /// on, and the XP all of them earned. VoiceOver hears it as one sentence:
    /// "6 nowych szczebli na ścieżce Podciąganie: …. +600 XP."
    private static func rungsPresentation(_ rungs: [RungReference]) -> CelebrationPresentation {
        let names = rungs.map { rung in
            rung.step.flatMap { ExerciseCatalog.exercise(withID: $0.exerciseID)?.name } ?? String(localized: "Nowy szczebel")
        }
        var pathIDs: [ProgressionPathID] = []
        for rung in rungs where !pathIDs.contains(rung.pathID) {
            pathIDs.append(rung.pathID)
        }
        let paths = pathIDs.compactMap { ProgressionCatalog.path(withID: $0) }
        let pathNames = paths.map(\.name).joined(separator: ", ")
        let xpNote = String(localized: "+\(rungs.count * ProgressionEngine.xpPerConqueredRung) XP")
        let list = names.joined(separator: ", ")

        let count = PolishPlural.newRungs(rungs.count)
        let accessibilityLabel =
            switch paths.count {
            case 0: String(localized: "\(count): \(list). \(xpNote).")
            case 1: String(localized: "\(count) na ścieżce \(pathNames): \(list). \(xpNote).")
            default: String(localized: "\(count) na ścieżkach \(pathNames): \(list). \(xpNote).")
            }
        return CelebrationPresentation(
            eyebrow: String(localized: "ZALICZONE SZCZEBLE"),
            title: count,
            subtitle: pathNames.isEmpty ? nil : pathNames,
            list: names,
            xpNote: xpNote,
            symbolName: paths.count == 1 ? paths[0].symbolName : "checkmark.seal.fill",
            accessibilityLabel: accessibilityLabel
        )
    }

    // MARK: Level

    private static func levelPresentation(_ level: Int) -> CelebrationPresentation {
        CelebrationPresentation(
            eyebrow: String(localized: "NOWY POZIOM"),
            title: String(localized: "Poziom \(level)"),
            subtitle: nil,
            xpNote: nil,
            symbolName: "trophy.fill",
            accessibilityLabel: String(localized: "Nowy poziom: \(level).")
        )
    }
}
