import Foundation
import os

// MARK: - DiagnosticsService
/// Keeps the crash and performance reports MetricKit delivers on the phone,
/// bounded by `DiagnosticRetention`. Nothing here sends anything: the user
/// sends reports themselves from Profile → "Pomoc i opinie" → "Diagnostyka".
///
/// An actor: MetricKit calls back on a background queue, and the file work
/// (one read-modify-write per delivery) stays off the main actor and runs one
/// at a time. Created once in `AppEnvironment.live()`, which also starts the
/// MetricKit subscription (`startReceivingMetricKit()`); tests and previews
/// get one over an in-memory store and never subscribe.
actor DiagnosticsService {
    private let store: any DiagnosticReportStoring
    private let retention: DiagnosticRetention
    private let now: @Sendable () -> Date
    private let makeID: @Sendable () -> UUID
    private let logger = AppLog.logger(category: "Diagnostics")
    /// The MetricKit subscriber, kept alive here once started.
    private var metricKitSource: MetricKitDiagnosticsSource?

    /// - Parameters:
    ///   - now: clock for arrival dates and retention; injectable for tests.
    ///   - makeID: report IDs; injectable for tests.
    init(
        store: any DiagnosticReportStoring,
        retention: DiagnosticRetention = .standard,
        now: @escaping @Sendable () -> Date = { .now },
        makeID: @escaping @Sendable () -> UUID = { UUID() }
    ) {
        self.store = store
        self.retention = retention
        self.now = now
        self.makeID = makeID
    }

    // MARK: Read
    /// The kept reports, newest first. Reports past retention are left out
    /// (and dropped from the file on the next write). Throws when the saved
    /// file cannot be read.
    func reports() throws -> [DiagnosticReport] {
        retention.apply(to: try store.load(), now: now())
    }

    // MARK: Record
    /// Adds what MetricKit delivered. A payload already stored is kept once.
    /// When the saved file cannot be read the new payloads are dropped and
    /// logged: the store refuses to write over a file it cannot read.
    func record(_ payloads: [MetricKitPayload]) {
        let receivedAt = Self.wholeSeconds(now())
        let incoming = payloads.compactMap {
            DiagnosticReportParser.report(from: $0, id: makeID(), receivedAt: receivedAt)
        }
        guard !incoming.isEmpty else { return }
        do {
            let kept = retention.merge(incoming, into: try store.load(), now: receivedAt)
            try store.replaceAll(with: kept)
            let kinds = incoming.flatMap(\.kinds).map(\.rawValue).joined(separator: ",")
            logger.info("Recorded \(incoming.count, privacy: .public) MetricKit payload(s): \(kinds, privacy: .public)")
        } catch {
            logger.error("Cannot record MetricKit payloads: \(String(describing: error), privacy: .public)")
        }
    }

    // MARK: Delete
    /// Removes the given reports and returns what is left, newest first.
    func delete(ids: Set<UUID>) throws -> [DiagnosticReport] {
        let kept = retention.apply(to: try store.load().filter { !ids.contains($0.id) }, now: now())
        try store.replaceAll(with: kept)
        return kept
    }

    /// "Usuń wszystko".
    func deleteAll() throws {
        try store.replaceAll(with: [])
    }

    // MARK: MetricKit
    /// Subscribes to MetricKit once. Payloads pending since the last launch
    /// arrive soon after; later ones about once a day.
    func startReceivingMetricKit() {
        guard metricKitSource == nil else { return }
        let source = MetricKitDiagnosticsSource(service: self)
        source.subscribe()
        metricKitSource = source
    }

    /// The file keeps whole seconds; rounding here keeps what is in memory
    /// equal to what is read back.
    private nonisolated static func wholeSeconds(_ date: Date) -> Date {
        Date(timeIntervalSince1970: date.timeIntervalSince1970.rounded(.down))
    }
}
