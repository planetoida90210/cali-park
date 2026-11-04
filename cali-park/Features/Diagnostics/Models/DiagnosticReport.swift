import Foundation

// MARK: - DiagnosticKind
/// What a MetricKit diagnostic is about. Raw values are stored on disk; never
/// rename them. Declared from the most to the least severe, so a report's
/// title names the worst thing in it.
nonisolated enum DiagnosticKind: String, Codable, CaseIterable, Comparable, Sendable {
    /// The app crashed (`MXCrashDiagnostic`).
    case crash
    /// The main thread stopped responding (`MXHangDiagnostic`).
    case hang
    /// The app used too much CPU (`MXCPUExceptionDiagnostic`).
    case cpuException
    /// The app wrote too much to disk (`MXDiskWriteExceptionDiagnostic`).
    case diskWriteException
    /// A slow launch (`MXAppLaunchDiagnostic`).
    case appLaunch
    /// A day of performance metrics (`MXMetricPayload`).
    case metrics

    /// Lower is more severe.
    var severity: Int {
        Self.allCases.firstIndex(of: self) ?? Self.allCases.count
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.severity < rhs.severity
    }
}

// MARK: - DiagnosticFact
/// One labelled detail of a diagnostic, e.g. the crash signal or the hang
/// duration. The key is stored; the screen turns it into a Polish label. The
/// value is MetricKit's own text ("SIGSEGV (11)", "2.4 sec"), not localized.
nonisolated struct DiagnosticFact: Codable, Hashable, Sendable {
    /// Raw values are stored on disk; never rename them.
    enum Key: String, Codable, Sendable {
        case signal
        case exceptionType
        case terminationReason
        case objectiveCException
        case hangDuration
        case cpuTime
        case sampledTime
        case writesCaused
        case launchDuration
        case foregroundTime
        case backgroundTime
        case peakMemory
        case diskWrites
        case unexpectedExits
    }

    let key: Key
    let value: String
}

// MARK: - DiagnosticEntry
/// One diagnostic inside a payload (a payload can hold several crashes and
/// hangs), or the one entry of a metrics payload.
nonisolated struct DiagnosticEntry: Codable, Hashable, Sendable {
    let kind: DiagnosticKind
    /// `CFBundleShortVersionString` of the build it happened in.
    let appVersion: String?
    /// `CFBundleVersion` of the build it happened in.
    let appBuild: String?
    /// E.g. "iPhone OS 26.1 (23B85)".
    let osVersion: String?
    /// The model identifier, e.g. "iPhone17,1".
    let deviceType: String?
    let facts: [DiagnosticFact]
    /// The top of the attributed thread's stack, unsymbolicated:
    /// "CaliPark + 165304" (binary + offset into its text segment).
    let topFrames: [String]

    init(
        kind: DiagnosticKind,
        appVersion: String? = nil,
        appBuild: String? = nil,
        osVersion: String? = nil,
        deviceType: String? = nil,
        facts: [DiagnosticFact] = [],
        topFrames: [String] = []
    ) {
        self.kind = kind
        self.appVersion = appVersion
        self.appBuild = appBuild
        self.osVersion = osVersion
        self.deviceType = deviceType
        self.facts = facts
        self.topFrames = topFrames
    }

    func fact(_ key: DiagnosticFact.Key) -> String? {
        facts.first { $0.key == key }?.value
    }
}

// MARK: - DiagnosticReport
/// One MetricKit payload kept on the phone: MetricKit's full JSON
/// (`jsonRepresentation()`), which is what gets sent, plus a summary parsed
/// from it for the list and the detail screen.
nonisolated struct DiagnosticReport: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    /// When MetricKit handed the payload to the app. Retention counts from it.
    let receivedAt: Date
    /// The start of the period the payload covers, when MetricKit gave one.
    let periodStart: Date?
    /// The end of that period: for a diagnostic, about when it happened.
    let periodEnd: Date?
    let entries: [DiagnosticEntry]
    /// MetricKit's JSON, verbatim.
    let payload: String

    init(
        id: UUID = UUID(),
        receivedAt: Date,
        periodStart: Date? = nil,
        periodEnd: Date? = nil,
        entries: [DiagnosticEntry],
        payload: String
    ) {
        self.id = id
        self.receivedAt = receivedAt
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.entries = entries
        self.payload = payload
    }

    /// The date shown for the report: the end of its period, or when it
    /// arrived when MetricKit gave no period.
    var date: Date { periodEnd ?? receivedAt }

    /// The kinds in this report, most severe first, each once.
    var kinds: [DiagnosticKind] {
        Array(Set(entries.map(\.kind))).sorted()
    }

    /// The most severe kind, which titles the report; `nil` when MetricKit's
    /// JSON held nothing this build recognizes.
    var primaryKind: DiagnosticKind? { kinds.first }

    /// The first entry that names the app build.
    var appVersion: AppVersion? {
        guard let entry = entries.first(where: { $0.appVersion != nil || $0.appBuild != nil }) else { return nil }
        return AppVersion(version: entry.appVersion ?? "?", build: entry.appBuild ?? "?")
    }

    var osVersion: String? { entries.lazy.compactMap(\.osVersion).first }
    var deviceType: String? { entries.lazy.compactMap(\.deviceType).first }
}

// MARK: - MetricKitPayload
/// A payload as MetricKit delivered it, already turned into its JSON (MetricKit's
/// payload objects are not `Sendable`, their JSON is).
nonisolated enum MetricKitPayload: Equatable, Sendable {
    /// `MXDiagnosticPayload.jsonRepresentation()`.
    case diagnostic(Data)
    /// `MXMetricPayload.jsonRepresentation()`.
    case metrics(Data)
}
