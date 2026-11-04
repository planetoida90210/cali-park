import Foundation
import Observation

// MARK: - DiagnosticsViewModel
/// Drives "Diagnostyka": the kept MetricKit reports, the selection to send,
/// and deleting. Reads through `DiagnosticsService`, which does the file work
/// off the main actor.
@Observable
final class DiagnosticsViewModel {
    // MARK: State
    /// Newest first.
    private(set) var reports: [DiagnosticReport] = []
    /// `true` once the first load finished, so the empty state doesn't flash.
    private(set) var hasLoaded = false
    /// The saved reports could not be read; the list stays empty.
    private(set) var loadFailed = false
    /// Reports ticked in selection mode, to send together.
    var selection: Set<UUID> = []
    /// A failure, for the error alert.
    var errorMessage: String?

    // MARK: Dependencies
    private let service: DiagnosticsService
    private let appVersion: AppVersion
    private let calendar: Calendar
    private let clock: () -> Date

    init(
        service: DiagnosticsService,
        appVersion: AppVersion = .current,
        calendar: Calendar = .current,
        clock: @escaping () -> Date = { .now }
    ) {
        self.service = service
        self.appVersion = appVersion
        self.calendar = calendar
        self.clock = clock
    }

    // MARK: Load
    func load() async {
        do {
            reports = try await service.reports()
            loadFailed = false
        } catch {
            reports = []
            loadFailed = true
            errorMessage = DiagnosticsFormat.loadFailureMessage
        }
        selection.formIntersection(reports.map(\.id))
        hasLoaded = true
    }

    func report(id: UUID) -> DiagnosticReport? {
        reports.first { $0.id == id }
    }

    /// Ticks or unticks one report in selection mode.
    func toggleSelection(_ id: UUID) {
        if selection.contains(id) {
            selection.remove(id)
        } else {
            selection.insert(id)
        }
    }

    // MARK: Send
    /// The selected reports, newest first, as one attachment; `nil` when
    /// nothing is selected.
    var selectionAttachment: DiagnosticAttachment? {
        attachment(for: reports.filter { selection.contains($0.id) })
    }

    /// One report or several as one attachment; `nil` for none.
    func attachment(for reports: [DiagnosticReport]) -> DiagnosticAttachment? {
        guard !reports.isEmpty else { return nil }
        return DiagnosticAttachment(reports: reports, appVersion: appVersion, createdAt: clock(), calendar: calendar)
    }

    var mailSubject: String { DiagnosticExport.mailSubject(version: appVersion) }

    // MARK: Delete
    func delete(ids: Set<UUID>) async {
        do {
            reports = try await service.delete(ids: ids)
            selection.subtract(ids)
        } catch {
            errorMessage = DiagnosticsFormat.deleteFailureMessage
        }
    }

    /// "Usuń wszystko".
    func deleteAll() async {
        do {
            try await service.deleteAll()
            reports = []
            selection = []
        } catch {
            errorMessage = DiagnosticsFormat.deleteFailureMessage
        }
    }
}
