import Foundation
import Observation

// MARK: - SkillPathsViewModel
/// Drives the Skills tab and a path's ladder: a read-only projection of the
/// shared `ProgressService` snapshot (per-path summaries, the overall level,
/// earned badges, any rung's progress).
///
/// The reward loop (celebrations, the XP toast) lives in the app-wide
/// `RewardCenter`, so the grid and the ladder can share this view model, or
/// each build one, without announcing the same save twice.
@MainActor
@Observable
final class SkillPathsViewModel {
    // MARK: State
    /// Set when the log or placement fails to load, for the Skills alert.
    var errorMessage: String?
    /// Whether the current failure streak was already announced.
    @ObservationIgnored private var hasAlertedLoadError = false

    // MARK: Dependencies
    private let progress: ProgressService

    // MARK: Init
    init(progress: ProgressService) {
        self.progress = progress
        alertIfLoadFailed()
    }

    // MARK: Output
    private var snapshot: ProgressSnapshot { progress.snapshot }

    /// One summary per catalog path, in catalog order.
    var summaries: [SkillPathSummary] { snapshot.summaries }
    /// The athlete's level, derived from the whole log history.
    var level: PlayerLevel { snapshot.level }
    /// Badges earned from the whole log history; declarations never grant one.
    var badges: Set<Badge> { snapshot.badges }
    /// Whether the athlete has declared a placement yet; drives the
    /// first-contact calibration prompt.
    var hasPlacement: Bool { snapshot.placement != nil }
    /// Whether the journal or the placement could not be read. The tab then
    /// keeps its previous state and must not offer calibration: an unreadable
    /// placement is not a missing one.
    var hasLoadError: Bool { progress.hasLoadError }

    /// Whether to offer the calibration prompt: no placement declared yet, and
    /// not merely an unreadable one.
    var needsCalibration: Bool { !hasPlacement && !hasLoadError }

    /// The summary for one path, or `nil` if the catalog has no such path.
    func summary(for id: ProgressionPathID) -> SkillPathSummary? {
        guard let path = ProgressionCatalog.path(withID: id),
              let state = snapshot.pathStates[id]
        else { return nil }
        return SkillPathSummary(path: path, state: state)
    }

    /// The athlete's best logged progress toward one rung, scored from the
    /// same snapshot the summaries use.
    func rungProgress(for step: ProgressionStep) -> RungProgress {
        snapshot.rungProgress(for: step)
    }

    // MARK: Intentions
    /// Retries what failed to load and raises the alert once per failure
    /// streak. Call on appear.
    func load() {
        progress.reloadIfFailed()
        alertIfLoadFailed()
    }

    private func alertIfLoadFailed() {
        guard hasLoadError else {
            hasAlertedLoadError = false
            return
        }
        if !hasAlertedLoadError { errorMessage = StoreLoadFailure.message }
        hasAlertedLoadError = true
    }
}
