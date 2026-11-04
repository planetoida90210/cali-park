import Foundation

// MARK: - DiagnosticReportStoring
/// Persistence for the diagnostic reports MetricKit delivered. Only
/// `DiagnosticsService` talks to it. `Sendable`, because the service is an
/// actor that does its file work off the main actor.
nonisolated protocol DiagnosticReportStoring: Sendable {
    /// The saved reports; empty when nothing was saved. Throws when a saved
    /// file exists but cannot be read; callers must show an error, never
    /// treat it as "no reports".
    func load() throws -> [DiagnosticReport]

    /// Replaces the saved reports.
    func replaceAll(with reports: [DiagnosticReport]) throws
}

// MARK: - FileDiagnosticReportStore
/// Default `DiagnosticReportStoring`: one JSON file in the app's store
/// directory (`AppEnvironment.live()` passes it), through `JSONFileStore`
/// (versioned envelope, quarantine of unreadable files, writes refused while
/// the file is broken).
nonisolated struct FileDiagnosticReportStore: DiagnosticReportStoring {
    private let file: JSONFileStore<[DiagnosticReport]>

    init(directory: URL, fileName: String = StoreFile.diagnostics.fileName) {
        file = JSONFileStore(fileURL: directory.appending(path: fileName), logCategory: "DiagnosticReportStore")
    }

    func load() throws -> [DiagnosticReport] {
        try file.read() ?? []
    }

    func replaceAll(with reports: [DiagnosticReport]) throws {
        try file.write(reports)
    }
}
