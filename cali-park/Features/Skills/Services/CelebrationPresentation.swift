import Foundation

// MARK: - CelebrationPresentation
/// The resolved copy and symbol for one `CelebrationEvent`, ready to render.
///
/// Kept separate from the event so the event stays a pure reference and the
/// display strings — Polish copy, tuned for a celebratory moment — live in one
/// testable place. Resolution reads only the static catalogs, so it is pure.
struct CelebrationPresentation: Equatable, Sendable {
    /// Short eyebrow above the title, e.g. "ZALICZONY SZCZEBEL".
    let eyebrow: String
    /// The headline: the conquered exercise, or "Poziom 3".
    let title: String
    /// Supporting context, e.g. the path name; `nil` when the title stands alone.
    let subtitle: String?
    /// A concrete XP note when the advance grants a fixed bonus; else `nil`.
    let xpNote: String?
    /// SF Symbol in the app's Watch-Workout style.
    let symbolName: String
    /// A single spoken sentence for VoiceOver.
    let accessibilityLabel: String

    /// The presentation for an event, resolved from the catalogs.
    static func resolving(_ event: CelebrationEvent) -> CelebrationPresentation {
        switch event {
        case let .rungConquered(rung): rungPresentation(rung)
        case let .levelReached(level): levelPresentation(level)
        }
    }

    // MARK: Rung

    private static func rungPresentation(_ rung: RungReference) -> CelebrationPresentation {
        let path = ProgressionCatalog.path(withID: rung.pathID)
        let step = path?.steps.indices.contains(rung.rungIndex) == true ? path?.steps[rung.rungIndex] : nil
        let exerciseName = step.flatMap { ExerciseCatalog.exercise(withID: $0.exerciseID)?.name } ?? "Nowy szczebel"
        let pathName = path?.name
        let xpNote = "+\(ProgressionEngine.xpPerConqueredRung) XP"

        let spokenPath = pathName.map { " na ścieżce \($0)" } ?? ""
        return CelebrationPresentation(
            eyebrow: "ZALICZONY SZCZEBEL",
            title: exerciseName,
            subtitle: pathName,
            xpNote: xpNote,
            symbolName: path?.symbolName ?? "checkmark.seal.fill",
            accessibilityLabel: "Zaliczony szczebel: \(exerciseName)\(spokenPath). \(xpNote)."
        )
    }

    // MARK: Level

    private static func levelPresentation(_ level: Int) -> CelebrationPresentation {
        CelebrationPresentation(
            eyebrow: "NOWY POZIOM",
            title: "Poziom \(level)",
            subtitle: nil,
            xpNote: nil,
            symbolName: "trophy.fill",
            accessibilityLabel: "Nowy poziom: \(level)."
        )
    }
}
