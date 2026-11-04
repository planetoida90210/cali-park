import Foundation

// MARK: - DiagnosticRetention
/// How much diagnostic history stays on the phone: reports received in the
/// last `maxAge`, at most `maxCount` of them, newest first. MetricKit sends
/// about one metrics payload a day plus any diagnostics, so the defaults
/// (30 days, 50 reports) keep a month without letting the file grow.
nonisolated struct DiagnosticRetention: Equatable, Sendable {
    let maxAge: Duration
    let maxCount: Int

    static let standard = DiagnosticRetention(maxAge: .seconds(30 * 24 * 60 * 60), maxCount: 50)

    /// The reports to keep, newest first: younger than `maxAge` at `now`
    /// (a report from the future, after a clock change, is kept), and no more
    /// than `maxCount`.
    func apply(to reports: [DiagnosticReport], now: Date) -> [DiagnosticReport] {
        let cutoff = now.addingTimeInterval(-TimeInterval(maxAge.components.seconds))
        return Array(
            reports
                .filter { $0.receivedAt >= cutoff }
                .sorted { $0.receivedAt > $1.receivedAt }
                .prefix(max(maxCount, 0))
        )
    }

    /// Adds `incoming` to `existing` and applies the policy. A payload whose
    /// JSON is already stored is skipped, so a payload delivered twice is
    /// kept once.
    func merge(_ incoming: [DiagnosticReport], into existing: [DiagnosticReport], now: Date) -> [DiagnosticReport] {
        var seen = Set(existing.map(\.payload))
        var merged = existing
        for report in incoming where seen.insert(report.payload).inserted {
            merged.append(report)
        }
        return apply(to: merged, now: now)
    }
}
