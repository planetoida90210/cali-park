import CoreTransferable
import Foundation
import UniformTypeIdentifiers

// MARK: - DiagnosticExport
/// The file the user sends from "Diagnostyka": the chosen reports with
/// MetricKit's JSON embedded as JSON (not as escaped text), so the file opens
/// readably and goes straight into symbolication tools.
nonisolated enum DiagnosticExport {
    /// "calipark-diagnostyka-2026-11-04.json", dated in the user's calendar.
    static func fileName(for date: Date, calendar: Calendar = .current) -> String {
        let day = CalendarDay(date, in: calendar)
        return "calipark-diagnostyka-\(day.key).json"
    }

    /// The export file's bytes:
    /// `{"app", "appVersion", "exportedAt", "reports": [{"receivedAt", "kinds", "payload"}]}`.
    /// A payload that is not valid JSON goes in as text, so nothing is lost.
    static func data(for reports: [DiagnosticReport], appVersion: String, exportedAt: Date) throws -> Data {
        let stamp = Date.ISO8601FormatStyle()
        let items: [[String: Any]] = reports.map { report in
            let payload: Any = (try? JSONSerialization.jsonObject(with: Data(report.payload.utf8))) ?? report.payload
            return [
                "receivedAt": report.receivedAt.formatted(stamp),
                "kinds": report.kinds.map(\.rawValue),
                "payload": payload
            ]
        }
        let root: [String: Any] = [
            "app": "CaliPark",
            "appVersion": appVersion,
            "exportedAt": exportedAt.formatted(stamp),
            "reports": items
        ]
        return try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys])
    }

    /// The support e-mail's subject; carries the app version like the
    /// "Napisz do nas" link does.
    static func mailSubject(version: AppVersion) -> String {
        String(localized: "CaliPark \(version.text): diagnostyka")
    }

    static var mailBody: String {
        String(localized: "W załączniku raport diagnostyczny z CaliPark. Opisz, co się działo, jeśli pamiętasz:\n\n")
    }
}

// MARK: - DiagnosticAttachment
/// The chosen reports, ready for the share sheet (`ShareLink`) or the mail
/// composer. The file is written only when the user actually shares.
nonisolated struct DiagnosticAttachment: Transferable, Equatable, Sendable {
    let reports: [DiagnosticReport]
    let appVersion: AppVersion
    let createdAt: Date
    let fileName: String

    init(reports: [DiagnosticReport], appVersion: AppVersion, createdAt: Date, calendar: Calendar = .current) {
        self.reports = reports
        self.appVersion = appVersion
        self.createdAt = createdAt
        self.fileName = DiagnosticExport.fileName(for: createdAt, calendar: calendar)
    }

    func data() throws -> Data {
        try DiagnosticExport.data(for: reports, appVersion: appVersion.text, exportedAt: createdAt)
    }

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { attachment in
            // A folder of its own per share, so the file keeps its readable
            // name without clashing with an earlier share.
            let folder = FileManager.default.temporaryDirectory
                .appending(path: "diagnostics-\(UUID().uuidString)", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let url = folder.appending(path: attachment.fileName)
            try attachment.data().write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }
}
