import Foundation
import Observation
import os

// MARK: - RewardCenter
/// The app's one reward loop: the queue of celebrations and the XP toast.
/// Conquered rungs and level-ups come first; a met weekly goal from
/// `WeeklyGoalService` follows in the same queue, so one overlay serves the
/// whole app.
///
/// It evaluates `RewardEvaluator` once per progress revision, whichever screen
/// logged the workout, so an award is presented exactly once (audit F-4, D-V1,
/// A-10). Before it, every Skills screen kept its own XP baseline, and the
/// same save was toasted again after popping back to the grid.
///
/// An advance is added to the "celebrated" record only when its overlay is
/// dismissed (audit A-4, C-7), so an evaluation that runs while no overlay is
/// on screen, or an app quit mid-queue, never loses a celebration.
///
/// XP: each rung overlay says "+100 XP", and the last overlay of a batch adds
/// the real total the saves gained ("Razem +740 XP"), so there is no separate
/// toast while celebrations carry the moment. A save that conquers nothing
/// gets the toast.
///
/// Presentation: `.rewardOverlay()` is mounted on the tab root and on the
/// sheets that stay up after a save (the rung sheet, the quick workout). Each
/// registers as a presenter while it is on screen, and only the most recent
/// one shows the overlay, so a celebration never plays hidden under a sheet.
@MainActor
@Observable
final class RewardCenter {
    // MARK: State
    /// The advance being celebrated right now, or `nil` when the queue is empty.
    private(set) var currentCelebration: CelebrationEvent?
    /// XP gained by the most recent save, to show as a toast; `nil` when there
    /// is nothing fresh to announce (or a celebration is carrying the moment).
    private(set) var xpToastAmount: Int?
    /// The overlays on screen, oldest first; the last one presents.
    private(set) var presenters: [UUID] = []

    /// Advances waiting behind `currentCelebration`, shown one at a time.
    private var pendingCelebrations: [CelebrationEvent] = []
    /// Total XP at the previous evaluation, to measure a save's gain; `nil`
    /// until the first one, so launching never toasts historical XP.
    @ObservationIgnored private var previousTotalXP: Int?
    /// Total XP before the save that started the batch on screen; `nil` when
    /// no batch is showing or it was queued at launch (gain unknown).
    private var batchStartXP: Int?
    /// Total XP at the latest evaluation.
    private var latestTotalXP = 0
    /// The progress revision last evaluated, so repeated refreshes are free.
    @ObservationIgnored private var evaluatedRevision: Int?

    // MARK: Dependencies
    private let progress: ProgressService
    private let store: SkillProgressStoring
    /// Met weekly goals, shown after the skill celebrations; `nil` in tests
    /// that only look at skills.
    private let goals: WeeklyGoalService?
    private let logger = AppLog.logger(category: "RewardCenter")

    // MARK: Init
    /// Evaluates once right away (the first run seeds a silent baseline), then
    /// after every progress change.
    init(progress: ProgressService, store: SkillProgressStoring, goals: WeeklyGoalService?) {
        self.progress = progress
        self.store = store
        self.goals = goals
        refresh()
        progress.onChange { [weak self] in self?.refresh() }
    }

    // MARK: Evaluation
    /// Evaluates the current progress if it changed since the last call.
    /// Skipped while the journal or placement can't be read.
    func refresh() {
        guard !progress.hasLoadError else { return }
        let revision = progress.revision
        guard revision != evaluatedRevision else { return }
        evaluatedRevision = revision

        let snapshot = progress.snapshot
        let wasCelebrating = currentCelebration != nil
        enqueueFreshCelebrations(from: snapshot)
        if currentCelebration == nil {
            batchStartXP = nil
        } else if !wasCelebrating {
            batchStartXP = previousTotalXP
        }
        latestTotalXP = snapshot.level.totalXP
        updateXPToast(total: snapshot.level.totalXP)
    }

    /// Compares the snapshot against the "already celebrated" record and
    /// rebuilds the queue. The record is written here only when the
    /// evaluation changed it (a first-run baseline, or rungs conquered below
    /// the placement floor), not on every evaluation.
    ///
    /// An unreadable record is skipped, not treated as "nothing celebrated":
    /// that would re-baseline silently and overwrite it.
    private func enqueueFreshCelebrations(from snapshot: ProgressSnapshot) {
        let celebrated: SkillProgress?
        do {
            celebrated = try store.load()
        } catch {
            logger.error("Skipping rewards, progress unreadable: \(String(describing: error), privacy: .public)")
            return
        }
        let evaluation = RewardEvaluator.evaluate(snapshot: snapshot, celebrated: celebrated)
        if evaluation.updatedProgress != celebrated {
            do {
                try store.save(evaluation.updatedProgress)
            } catch {
                // Safe to drop: the next evaluation computes the same record.
                logger.error("Cannot save reward progress: \(String(describing: error), privacy: .public)")
            }
        }
        replaceCelebrationQueue(with: evaluation.pendingEvents)
    }

    /// Makes `events` the queue. The overlay on screen stays put while it is
    /// still pending.
    private func replaceCelebrationQueue(with events: [CelebrationEvent]) {
        if let current = currentCelebration, events.contains(current) {
            pendingCelebrations = events.filter { $0 != current }
        } else {
            currentCelebration = events.first
            pendingCelebrations = Array(events.dropFirst())
        }
    }

    /// Sets the XP toast to a save's gain, unless this is the first evaluation
    /// (no baseline yet) or a celebration is already carrying the moment.
    private func updateXPToast(total: Int) {
        defer { previousTotalXP = total }
        guard let previous = previousTotalXP, total > previous else { return }
        xpToastAmount = currentCelebration == nil ? total - previous : nil
    }

    /// Starts over after an import replaced the data: drops the queue and the
    /// toast, then evaluates silently, as on launch. The imported history is
    /// not progress made since the last save, and the imported "celebrated"
    /// record decides what is still owed.
    func rebaseline() {
        currentCelebration = nil
        pendingCelebrations = []
        xpToastAmount = nil
        batchStartXP = nil
        previousTotalXP = nil
        evaluatedRevision = nil
        refresh()
    }

    // MARK: Output
    /// What the overlay shows now: the next skill celebration, else a met
    /// weekly goal; `nil` when the queue is empty.
    var current: RewardPresentation? {
        if let event = currentCelebration {
            var presentation = CelebrationPresentation.resolving(event)
            let isLastOfBatch = pendingCelebrations.isEmpty
            if isLastOfBatch, let total = batchXPGain {
                presentation = presentation.addingTotalXP(total)
            }
            return RewardPresentation(
                presentation: presentation,
                trigger: event.id,
                hasNext: !isLastOfBatch || goals?.pendingCelebration != nil
            )
        }
        if let goals, let met = goals.pendingCelebration, let snapshot = goals.snapshot {
            return RewardPresentation(
                presentation: .weeklyGoalMet(met, isPrimary: met.id == snapshot.week.primary.id, streak: snapshot.streak),
                trigger: "goal-\(met.id.uuidString)-\(snapshot.week.interval.start.timeIntervalSince1970)",
                hasNext: goals.hasQueuedCelebrations
            )
        }
        return nil
    }

    /// The XP the saves behind the current batch gained, or `nil` when unknown.
    var batchXPGain: Int? {
        guard let batchStartXP, latestTotalXP > batchStartXP else { return nil }
        return latestTotalXP - batchStartXP
    }

    // MARK: Intentions
    /// Whether more advances wait behind the one on screen.
    var hasQueuedCelebrations: Bool { !pendingCelebrations.isEmpty }

    /// Dismisses whatever the overlay shows and moves to the next one.
    func dismissCurrent() {
        if currentCelebration != nil {
            dismissCurrentCelebration()
        } else {
            goals?.dismissCelebration()
        }
    }

    /// Records the skill overlay on screen as celebrated and moves to the next
    /// one.
    func dismissCurrentCelebration() {
        if let shown = currentCelebration { markCelebrated(shown) }
        currentCelebration = pendingCelebrations.isEmpty ? nil : pendingCelebrations.removeFirst()
        if currentCelebration == nil { batchStartXP = nil }
    }

    /// Clears the XP toast for `amount` once it has been shown. A newer toast
    /// for a different amount stays up, so an older overlay timer can't hide
    /// it early (D-13).
    func clearXPToast(_ amount: Int) {
        guard xpToastAmount == amount else { return }
        xpToastAmount = nil
    }

    /// Adds a shown event to the persisted record, re-reading it first. A
    /// failed write only means the event may play once more.
    private func markCelebrated(_ event: CelebrationEvent) {
        do {
            // No record means the baseline was never saved; marking now would
            // turn that into a near-empty record and replay history.
            guard let record = try store.load() else { return }
            let marked = record.markingCelebrated(event)
            if marked != record { try store.save(marked) }
        } catch {
            logger.error("Cannot mark celebration as shown: \(String(describing: error), privacy: .public)")
        }
    }

    // MARK: Presenters
    /// Marks an overlay as on screen; the latest one presents.
    func register(presenter id: UUID) {
        presenters.removeAll { $0 == id }
        presenters.append(id)
    }

    func unregister(presenter id: UUID) {
        presenters.removeAll { $0 == id }
    }

    /// Whether the overlay `id` is the one that shows rewards now.
    func isPresenting(_ id: UUID) -> Bool {
        presenters.last == id
    }
}

// MARK: - RewardPresentation
/// One overlay ready to show: its copy, the value that replays the haptic and
/// the entrance pulse, and whether "Dalej" leads to another one.
nonisolated struct RewardPresentation: Equatable {
    let presentation: CelebrationPresentation
    let trigger: String
    let hasNext: Bool
}
