import Foundation
import Observation
import os

// MARK: - TrainingBackupViewModel
/// Drives "Eksport i import treningów" in Profile.
///
/// - Export: `prepareExport()` writes everything saved now to a dated file in
///   a temporary folder, which the screen hands to `ShareLink` (Files, AirDrop,
///   Mail). Run it on every appear, so the file never lags the journal.
/// - Import: `review(fileAt:)`/`review(_:)` decode and validate the whole file
///   first and only then ask, through `pendingImport`, whether to replace the
///   current data. `confirmImport(_:)` replaces it all or nothing.
@MainActor
@Observable
final class TrainingBackupViewModel {
    // MARK: PendingImport
    /// A validated backup waiting for "Zastąp" or "Anuluj".
    struct PendingImport: Identifiable, Equatable {
        let id = UUID()
        let backup: TrainingBackup
        /// What the file holds.
        let incoming: TrainingBackupSummary
        /// What it would replace.
        let current: TrainingBackupSummary
    }

    // MARK: State
    /// What is saved now; `nil` while it cannot be read.
    private(set) var currentSummary: TrainingBackupSummary?
    /// The export file, ready to share; `nil` until prepared or after a failure.
    private(set) var exportFile: URL?
    /// The import waiting for confirmation.
    var pendingImport: PendingImport?
    private(set) var isImporting = false
    /// A finished import, for the success alert.
    var resultMessage: String?
    /// A failure, for the error alert.
    var errorMessage: String?

    // MARK: Dependencies
    private let service: TrainingBackupService
    private let exportDirectory: URL
    private let appVersion: String
    private let calendar: Calendar
    private let clock: () -> Date
    private let logger = AppLog.logger(category: "TrainingBackupScreen")

    /// - Parameters:
    ///   - exportDirectory: where export files are written (a temporary
    ///     folder in the app; a test directory in tests).
    ///   - appVersion: stamped into the file, e.g. "1.0 (5)".
    init(
        service: TrainingBackupService,
        exportDirectory: URL = FileManager.default.temporaryDirectory,
        appVersion: String = AppVersion.current.text,
        calendar: Calendar = .current,
        clock: @escaping () -> Date = { .now }
    ) {
        self.service = service
        self.exportDirectory = exportDirectory
        self.appVersion = appVersion
        self.calendar = calendar
        self.clock = clock
    }

    // MARK: Export
    /// Writes the current data to `calipark-backup-YYYY-MM-DD.json` and
    /// publishes it as `exportFile`. On failure the screen shows why and
    /// offers no file, so a partial export can never be shared.
    func prepareExport() {
        exportFile = nil
        let backup: TrainingBackup
        do {
            backup = try service.currentBackup()
        } catch {
            currentSummary = nil
            errorMessage = StoreLoadFailure.message
            return
        }
        currentSummary = backup.summary
        do {
            let now = clock()
            let data = try TrainingBackupCodec.encode(backup, exportedAt: now, appVersion: appVersion)
            let url = exportDirectory.appending(path: TrainingBackupCodec.fileName(for: now, calendar: calendar))
            try data.write(to: url, options: .atomic)
            exportFile = url
        } catch {
            logger.error("Cannot write export file: \(String(describing: error), privacy: .public)")
            errorMessage = String(localized: "Nie udało się przygotować pliku z kopią.")
        }
    }

    // MARK: Import
    /// Reads a file picked in `fileImporter` (a security-scoped URL outside
    /// the app's sandbox) and reviews it.
    func review(fileAt url: URL) {
        let isScoped = url.startAccessingSecurityScopedResource()
        defer { if isScoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            guard size <= TrainingBackupCodec.maximumFileSize else {
                errorMessage = TrainingBackupError.tooLarge.message
                return
            }
            review(try Data(contentsOf: url))
        } catch {
            logger.error("Cannot read import file: \(String(describing: error), privacy: .public)")
            errorMessage = TrainingBackupError.unreadableFile.message
        }
    }

    /// Validates the whole file, then asks for confirmation. Nothing is
    /// written here.
    func review(_ data: Data) {
        let backup: TrainingBackup
        do throws(TrainingBackupError) {
            backup = try TrainingBackupCodec.decode(data)
        } catch {
            errorMessage = error.message
            return
        }
        let current: TrainingBackup
        do {
            current = try service.currentBackup()
        } catch {
            errorMessage = TrainingBackupRestoreError.currentDataUnreadable.message
            return
        }
        pendingImport = PendingImport(backup: backup, incoming: backup.summary, current: current.summary)
    }

    /// "Zastąp": replaces every store with the reviewed backup. Takes the
    /// pending import as an argument because the dialog clears
    /// `pendingImport` as it closes, before this task runs.
    func confirmImport(_ pending: PendingImport) async {
        guard !isImporting else { return }
        pendingImport = nil
        isImporting = true
        defer { isImporting = false }
        do throws(TrainingBackupRestoreError) {
            try await service.restore(pending.backup)
            resultMessage = String(localized: "Zaimportowano: \(pending.incoming.text).")
        } catch {
            errorMessage = error.message
        }
        prepareExport()
    }

    /// "Anuluj": drops the pending backup; nothing was written.
    func cancelImport() {
        pendingImport = nil
    }
}
