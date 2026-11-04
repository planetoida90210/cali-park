import Foundation

// MARK: - DiagnosticReportParser
/// Turns MetricKit's JSON into a `DiagnosticReport`: the verbatim JSON plus a
/// summary (kinds, app build, OS, the key facts and the top stack frames).
///
/// Works on the JSON, not on MetricKit's objects, so tests can feed it fixed
/// fixtures. It reads leniently: a missing or unexpected field leaves that
/// part of the summary out, never the report. MetricKit's documented shape:
/// `MXDiagnosticPayload` has `timeStampBegin`/`timeStampEnd` and one array per
/// kind (`crashDiagnostics`, `hangDiagnostics`, `cpuExceptionDiagnostics`,
/// `diskWriteExceptionDiagnostics`, `appLaunchDiagnostics`), each item with
/// `diagnosticMetaData` and a `callStackTree`; `MXMetricPayload` has the same
/// time stamps, `appVersion`, `metaData` and one object per metric category.
nonisolated enum DiagnosticReportParser {
    /// How many frames of the top of the stack the summary keeps.
    static let topFrameLimit = 8

    /// The report for one payload; `nil` only when the data is not UTF-8 text.
    static func report(from payload: MetricKitPayload, id: UUID = UUID(), receivedAt: Date) -> DiagnosticReport? {
        switch payload {
        case .diagnostic(let data):
            diagnosticReport(from: data, id: id, receivedAt: receivedAt)
        case .metrics(let data):
            metricsReport(from: data, id: id, receivedAt: receivedAt)
        }
    }

    // MARK: Diagnostic payloads
    static func diagnosticReport(from data: Data, id: UUID = UUID(), receivedAt: Date) -> DiagnosticReport? {
        guard let text = String(data: data, encoding: .utf8) else { return nil }
        let root = object(from: data)
        let sections: [(key: String, kind: DiagnosticKind)] = [
            ("crashDiagnostics", .crash),
            ("hangDiagnostics", .hang),
            ("cpuExceptionDiagnostics", .cpuException),
            ("diskWriteExceptionDiagnostics", .diskWriteException),
            ("appLaunchDiagnostics", .appLaunch)
        ]
        var entries: [DiagnosticEntry] = []
        for section in sections {
            for item in root[section.key] as? [[String: Any]] ?? [] {
                entries.append(diagnosticEntry(item, kind: section.kind))
            }
        }
        return DiagnosticReport(
            id: id,
            receivedAt: receivedAt,
            periodStart: date(root["timeStampBegin"]),
            periodEnd: date(root["timeStampEnd"]),
            entries: entries,
            payload: text
        )
    }

    private static func diagnosticEntry(_ item: [String: Any], kind: DiagnosticKind) -> DiagnosticEntry {
        let meta = item["diagnosticMetaData"] as? [String: Any] ?? [:]
        var facts: [DiagnosticFact] = []
        func add(_ key: DiagnosticFact.Key, _ value: String?) {
            if let value, !value.isEmpty { facts.append(DiagnosticFact(key: key, value: value)) }
        }
        switch kind {
        case .crash:
            add(.signal, integer(meta["signal"]).map(signalName))
            add(.exceptionType, integer(meta["exceptionType"]).map(exceptionTypeName))
            add(.terminationReason, string(meta["terminationReason"]))
            add(.objectiveCException, objectiveCException(meta["objectiveCexceptionReason"]))
        case .hang:
            add(.hangDuration, string(meta["hangDuration"]))
        case .cpuException:
            add(.cpuTime, string(meta["totalCPUTime"]))
            add(.sampledTime, string(meta["totalSampledTime"]))
        case .diskWriteException:
            add(.writesCaused, string(meta["writesCaused"]))
        case .appLaunch:
            add(.launchDuration, string(meta["launchDuration"]))
        case .metrics:
            break
        }
        return DiagnosticEntry(
            kind: kind,
            appVersion: string(meta["appVersion"]),
            appBuild: string(meta["appBuildVersion"]),
            osVersion: string(meta["osVersion"]),
            deviceType: string(meta["deviceType"]),
            facts: facts,
            topFrames: topFrames(of: item["callStackTree"])
        )
    }

    // MARK: Metric payloads
    static func metricsReport(from data: Data, id: UUID = UUID(), receivedAt: Date) -> DiagnosticReport? {
        guard let text = String(data: data, encoding: .utf8) else { return nil }
        let root = object(from: data)
        // Not a JSON object: keep the text, summarize nothing.
        guard !root.isEmpty else {
            return DiagnosticReport(id: id, receivedAt: receivedAt, entries: [], payload: text)
        }
        let meta = root["metaData"] as? [String: Any] ?? [:]
        let time = root["applicationTimeMetrics"] as? [String: Any] ?? [:]
        let memory = root["memoryMetrics"] as? [String: Any] ?? [:]
        let disk = root["diskIOMetrics"] as? [String: Any] ?? [:]
        var facts: [DiagnosticFact] = []
        func add(_ key: DiagnosticFact.Key, _ value: String?) {
            if let value, !value.isEmpty { facts.append(DiagnosticFact(key: key, value: value)) }
        }
        add(.foregroundTime, string(time["cumulativeForegroundTime"]))
        add(.backgroundTime, string(time["cumulativeBackgroundTime"]))
        add(.peakMemory, string(memory["peakMemoryUsage"]))
        add(.diskWrites, string(disk["cumulativeLogicalWrites"]))
        add(.unexpectedExits, unexpectedExits(root["applicationExitMetrics"]).map(String.init))
        let entry = DiagnosticEntry(
            kind: .metrics,
            appVersion: string(root["appVersion"]),
            appBuild: string(meta["appBuildVersion"]),
            osVersion: string(meta["osVersion"]),
            deviceType: string(meta["deviceType"]),
            facts: facts
        )
        return DiagnosticReport(
            id: id,
            receivedAt: receivedAt,
            periodStart: date(root["timeStampBegin"]),
            periodEnd: date(root["timeStampEnd"]),
            entries: [entry],
            payload: text
        )
    }

    /// Exits other than normal ones and memory-pressure kills (the system
    /// reclaiming memory from a suspended app), foreground and background
    /// together. `nil` when the payload has no exit metrics.
    static func unexpectedExits(_ value: Any?) -> Int? {
        guard let exits = value as? [String: Any] else { return nil }
        let counted: Set<String> = [
            "cumulativeAbnormalExitCount",
            "cumulativeBadAccessExitCount",
            "cumulativeIllegalInstructionExitCount",
            "cumulativeAppWatchdogExitCount",
            "cumulativeMemoryResourceLimitExitCount",
            "cumulativeCPUResourceLimitExitCount",
            "cumulativeSuspendedWithLockedFileExitCount",
            "cumulativeBackgroundTaskAssertionTimeoutExitCount"
        ]
        var total = 0
        var found = false
        for group in ["foregroundExitData", "backgroundExitData"] {
            for (key, count) in exits[group] as? [String: Any] ?? [:] where counted.contains(key) {
                if let count = integer(count) {
                    total += count
                    found = true
                }
            }
        }
        return found ? total : nil
    }

    // MARK: Call stacks
    /// The top of the attributed thread's stack (the crashed or hung thread;
    /// the first stack when none is marked), most recent frame first. In
    /// MetricKit's tree a root frame is the top of a stack and each
    /// `subFrames` entry is its caller.
    static func topFrames(of value: Any?) -> [String] {
        guard let tree = value as? [String: Any],
            let stacks = tree["callStacks"] as? [[String: Any]],
            let stack = stacks.first(where: { ($0["threadAttributed"] as? Bool) == true }) ?? stacks.first
        else { return [] }
        var frames: [String] = []
        var frame = (stack["callStackRootFrames"] as? [[String: Any]])?.first
        while let current = frame, frames.count < topFrameLimit {
            frames.append(frameText(current))
            frame = (current["subFrames"] as? [[String: Any]])?.first
        }
        return frames
    }

    /// "CaliPark + 165304", the form symbolication tools take with the
    /// binary's UUID (which stays in the full JSON).
    private static func frameText(_ frame: [String: Any]) -> String {
        let binary = string(frame["binaryName"]) ?? "???"
        if let offset = integer(frame["offsetIntoBinaryTextSegment"]) {
            return "\(binary) + \(offset)"
        }
        if let address = integer(frame["address"]) {
            return "\(binary) 0x\(String(address, radix: 16))"
        }
        return binary
    }

    // MARK: Names
    /// "SIGSEGV (11)"; the number alone when it is not a common signal.
    static func signalName(_ signal: Int) -> String {
        let names = [
            4: "SIGILL", 5: "SIGTRAP", 6: "SIGABRT", 7: "SIGEMT", 8: "SIGFPE", 9: "SIGKILL",
            10: "SIGBUS", 11: "SIGSEGV", 12: "SIGSYS", 13: "SIGPIPE", 15: "SIGTERM"
        ]
        return names[signal].map { "\($0) (\(signal))" } ?? "\(signal)"
    }

    /// "EXC_BAD_ACCESS (1)"; the number alone when it is not a known Mach
    /// exception type.
    static func exceptionTypeName(_ type: Int) -> String {
        let names = [
            1: "EXC_BAD_ACCESS", 2: "EXC_BAD_INSTRUCTION", 3: "EXC_ARITHMETIC", 4: "EXC_EMULATION",
            5: "EXC_SOFTWARE", 6: "EXC_BREAKPOINT", 10: "EXC_CRASH", 11: "EXC_RESOURCE",
            12: "EXC_GUARD", 13: "EXC_CORPSE_NOTIFY"
        ]
        return names[type].map { "\($0) (\(type))" } ?? "\(type)"
    }

    /// "NSInvalidArgumentException: <composed message>".
    private static func objectiveCException(_ value: Any?) -> String? {
        guard let reason = value as? [String: Any] else { return nil }
        let name = string(reason["exceptionName"]) ?? string(reason["exceptionType"])
        let message = string(reason["composedMessage"])
        switch (name, message) {
        case (let name?, let message?): return "\(name): \(message)"
        case (let name?, nil): return name
        case (nil, let message?): return message
        case (nil, nil): return nil
        }
    }

    // MARK: Values
    private static func object(from data: Data) -> [String: Any] {
        (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
    }

    private static func string(_ value: Any?) -> String? {
        switch value {
        case let text as String: text
        case let number as NSNumber: number.stringValue
        default: nil
        }
    }

    private static func integer(_ value: Any?) -> Int? {
        switch value {
        case let number as NSNumber: number.intValue
        case let text as String: Int(text)
        default: nil
        }
    }

    /// MetricKit writes "2026-11-03 21:15:00 +0000"; some payloads leave the
    /// zone out, which then reads as UTC.
    static func date(_ value: Any?) -> Date? {
        guard let text = string(value) else { return nil }
        for format in ["yyyy-MM-dd HH:mm:ss Z", "yyyy-MM-dd HH:mm:ss"] {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = .gmt
            formatter.dateFormat = format
            if let date = formatter.date(from: text) { return date }
        }
        return nil
    }
}
