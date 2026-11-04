import Foundation
import Synchronization
import Testing

@testable import cali_park

// MARK: - Fixtures
/// The MetricKit fixtures in `Fixtures/` are hand-written in Apple's
/// documented `jsonRepresentation()` shape (the Simulator delivers no
/// payloads), with every diagnostic kind and the metric categories we read.
private enum DiagnosticFixtures {
    /// 2026-11-03T21:15:00Z
    static let now = Date(timeIntervalSince1970: 1_793_740_500)
    static let day: TimeInterval = 86_400

    static func data(_ name: String) throws -> Data {
        let url = try #require(Bundle(for: DiagnosticsBundleToken.self).url(forResource: name, withExtension: "json"))
        return try Data(contentsOf: url)
    }

    static func diagnosticPayload() throws -> Data { try data("metrickit-diagnostic-payload") }
    static func metricPayload() throws -> Data { try data("metrickit-metric-payload") }

    static func id(_ n: Int) -> UUID {
        let digits = String(n)
        return UUID(uuidString: "D0000000-0000-4000-8000-" + String(repeating: "0", count: 12 - digits.count) + digits)!
    }

    /// A minimal report received `daysAgo` before `now`.
    static func report(_ n: Int, daysAgo: Double, payload: String? = nil) -> DiagnosticReport {
        DiagnosticReport(
            id: id(n),
            receivedAt: now.addingTimeInterval(-daysAgo * day),
            entries: [DiagnosticEntry(kind: .metrics, appVersion: "1.0", appBuild: "7")],
            payload: payload ?? "{\"n\":\(n)}"
        )
    }

    static var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    static func makeDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "DiagnosticsTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

private final class DiagnosticsBundleToken {}

/// Hands out the given IDs in order, then fresh ones.
private final class IDSequence: Sendable {
    private let ids: [UUID]
    private let next = Counter()

    init(_ ids: [UUID]) { self.ids = ids }

    func make() -> UUID {
        let index = next.increment()
        return index < ids.count ? ids[index] : UUID()
    }
}

private final class Counter: Sendable {
    private let value = Mutex(0)
    /// Returns the value before incrementing.
    func increment() -> Int {
        value.withLock { current in
            defer { current += 1 }
            return current
        }
    }
}

// MARK: - Parser
@Suite("MetricKit payload parsing")
struct DiagnosticReportParserTests {
    @Test("A diagnostic payload yields one entry per diagnostic, most severe kind first")
    func diagnosticPayloadEntries() throws {
        let data = try DiagnosticFixtures.diagnosticPayload()
        let report = try #require(
            DiagnosticReportParser.report(
                from: .diagnostic(data), id: DiagnosticFixtures.id(1),
                receivedAt: DiagnosticFixtures.now))

        #expect(report.entries.map(\.kind) == [.crash, .hang, .cpuException, .diskWriteException, .appLaunch])
        #expect(report.primaryKind == .crash)
        #expect(report.payload == String(decoding: data, as: UTF8.self))
        #expect(report.id == DiagnosticFixtures.id(1))
        #expect(report.receivedAt == DiagnosticFixtures.now)
    }

    @Test("The period comes from MetricKit's time stamps")
    func diagnosticPeriod() throws {
        let report = try #require(
            DiagnosticReportParser.diagnosticReport(
                from: try DiagnosticFixtures.diagnosticPayload(), receivedAt: DiagnosticFixtures.now))
        // 2026-11-03 18:42:00 +0000
        let expected = Date(timeIntervalSince1970: 1_793_731_320)
        #expect(report.periodStart == expected)
        #expect(report.periodEnd == expected)
        #expect(report.date == expected)
    }

    @Test("A crash keeps the build, OS, device, signal, exception and the top frames")
    func crashSummary() throws {
        let report = try #require(
            DiagnosticReportParser.diagnosticReport(
                from: try DiagnosticFixtures.diagnosticPayload(), receivedAt: DiagnosticFixtures.now))
        let crash = try #require(report.entries.first)

        #expect(crash.appVersion == "1.0")
        #expect(crash.appBuild == "7")
        #expect(crash.osVersion == "iPhone OS 26.1 (23B85)")
        #expect(crash.deviceType == "iPhone17,1")
        #expect(crash.fact(.signal) == "SIGTRAP (5)")
        #expect(crash.fact(.exceptionType) == "EXC_BREAKPOINT (6)")
        #expect(crash.fact(.terminationReason) == "Namespace SIGNAL, Code 5 Trace/BPT trap: 5")
        // The attributed (crashed) thread, not the first one listed.
        #expect(
            crash.topFrames == [
                "libswiftCore.dylib + 1210384",
                "CaliPark + 165304",
                "CaliPark + 158220",
                "SwiftUI + 23488812",
                "dyld + 18732"
            ])
        #expect(report.appVersion == AppVersion(version: "1.0", build: "7"))
    }

    @Test("Hangs, CPU and disk-write exceptions and slow launches keep their key facts")
    func otherKindsFacts() throws {
        let report = try #require(
            DiagnosticReportParser.diagnosticReport(
                from: try DiagnosticFixtures.diagnosticPayload(), receivedAt: DiagnosticFixtures.now))
        let byKind = Dictionary(uniqueKeysWithValues: report.entries.map { ($0.kind, $0) })

        #expect(byKind[.hang]?.fact(.hangDuration) == "2.4 sec")
        #expect(byKind[.hang]?.topFrames == ["Foundation + 98304", "CaliPark + 201776"])
        #expect(byKind[.cpuException]?.fact(.cpuTime) == "92 sec")
        #expect(byKind[.cpuException]?.fact(.sampledTime) == "180 sec")
        // No attributed thread: the first stack is used.
        #expect(byKind[.cpuException]?.topFrames == ["CaliPark + 312004"])
        #expect(byKind[.diskWriteException]?.fact(.writesCaused) == "1,073,741,824 bytes")
        #expect(byKind[.diskWriteException]?.topFrames == [])
        #expect(byKind[.appLaunch]?.fact(.launchDuration) == "4.1 sec")
    }

    @Test("A metric payload becomes one metrics entry with the highlights")
    func metricPayload() throws {
        let report = try #require(
            DiagnosticReportParser.report(
                from: .metrics(try DiagnosticFixtures.metricPayload()), receivedAt: DiagnosticFixtures.now))
        let entry = try #require(report.entries.first)

        #expect(report.entries.count == 1)
        #expect(entry.kind == .metrics)
        #expect(entry.appVersion == "1.0")
        #expect(entry.appBuild == "7")
        #expect(entry.osVersion == "iPhone OS 26.1 (23B85)")
        #expect(
            entry.facts == [
                DiagnosticFact(key: .foregroundTime, value: "1,260 sec"),
                DiagnosticFact(key: .backgroundTime, value: "40 sec"),
                DiagnosticFact(key: .peakMemory, value: "182,000 kB"),
                DiagnosticFact(key: .diskWrites, value: "2,400 kB"),
                // Watchdog + illegal instruction in the foreground, memory limit
                // in the background; normal exits and memory pressure don't count.
                DiagnosticFact(key: .unexpectedExits, value: "3")
            ])
        // 2026-11-02 00:00:00 +0000 … 23:59:00 +0000
        #expect(report.periodStart == Date(timeIntervalSince1970: 1_793_577_600))
        #expect(report.periodEnd == Date(timeIntervalSince1970: 1_793_663_940))
    }

    @Test("An Objective-C exception reads as name and message")
    func objectiveCException() throws {
        let json = """
            {"crashDiagnostics": [{"diagnosticMetaData": {"signal": 6, "exceptionType": 10,
              "objectiveCexceptionReason": {"exceptionName": "NSInvalidArgumentException",
                "composedMessage": "unrecognized selector sent to instance"}}}]}
            """
        let report = try #require(DiagnosticReportParser.diagnosticReport(from: Data(json.utf8), receivedAt: DiagnosticFixtures.now))
        let crash = try #require(report.entries.first)

        #expect(crash.fact(.signal) == "SIGABRT (6)")
        #expect(crash.fact(.exceptionType) == "EXC_CRASH (10)")
        #expect(crash.fact(.objectiveCException) == "NSInvalidArgumentException: unrecognized selector sent to instance")
        #expect(crash.appVersion == nil)
        #expect(report.appVersion == nil)
    }

    @Test("Unknown or broken JSON keeps the text and summarizes nothing")
    func lenientParsing() throws {
        let unknown = try #require(
            DiagnosticReportParser.diagnosticReport(
                from: Data(#"{"futureDiagnostics": [{}], "timeStampEnd": "soon"}"#.utf8), receivedAt: DiagnosticFixtures.now))
        #expect(unknown.entries.isEmpty)
        #expect(unknown.primaryKind == nil)
        #expect(unknown.periodEnd == nil)
        #expect(unknown.date == DiagnosticFixtures.now)

        let broken = try #require(DiagnosticReportParser.metricsReport(from: Data("not json".utf8), receivedAt: DiagnosticFixtures.now))
        #expect(broken.entries.isEmpty)
        #expect(broken.payload == "not json")

        #expect(DiagnosticReportParser.diagnosticReport(from: Data([0xFF, 0xFE, 0x00]), receivedAt: DiagnosticFixtures.now) == nil)
    }

    @Test("The top of the stack stops at the frame limit")
    func frameLimit() {
        var frame: [String: Any] = ["binaryName": "CaliPark", "offsetIntoBinaryTextSegment": 0]
        for depth in 1...20 {
            frame = ["binaryName": "CaliPark", "offsetIntoBinaryTextSegment": depth, "subFrames": [frame]]
        }
        let tree: [String: Any] = ["callStacks": [["threadAttributed": true, "callStackRootFrames": [frame]]]]
        let frames = DiagnosticReportParser.topFrames(of: tree)

        #expect(frames.count == DiagnosticReportParser.topFrameLimit)
        #expect(frames.first == "CaliPark + 20")
    }

    @Test(
        "Time stamps with and without a zone read as UTC",
        arguments: [
            "2026-11-03 21:15:00 +0000",
            "2026-11-03 21:15:00"
        ])
    func timeStamps(text: String) {
        #expect(DiagnosticReportParser.date(text) == DiagnosticFixtures.now)
    }

    @Test("Signals and exception types get their names; unknown ones stay numbers")
    func names() {
        #expect(DiagnosticReportParser.signalName(11) == "SIGSEGV (11)")
        #expect(DiagnosticReportParser.signalName(99) == "99")
        #expect(DiagnosticReportParser.exceptionTypeName(1) == "EXC_BAD_ACCESS (1)")
        #expect(DiagnosticReportParser.exceptionTypeName(42) == "42")
    }
}

// MARK: - Retention
@Suite("Diagnostic retention")
struct DiagnosticRetentionTests {
    private let policy = DiagnosticRetention(maxAge: .seconds(30 * 86_400), maxCount: 3)

    @Test("Reports older than the maximum age are dropped; the boundary is kept")
    func dropsOldReports() {
        let reports = [
            DiagnosticFixtures.report(1, daysAgo: 31),
            DiagnosticFixtures.report(2, daysAgo: 30),
            DiagnosticFixtures.report(3, daysAgo: 2)
        ]
        let kept = policy.apply(to: reports, now: DiagnosticFixtures.now)
        #expect(kept.map(\.id) == [DiagnosticFixtures.id(3), DiagnosticFixtures.id(2)])
    }

    @Test("At most maxCount reports are kept, the newest ones, newest first")
    func keepsNewest() {
        let reports = (1...5).map { DiagnosticFixtures.report($0, daysAgo: Double($0)) }
        let kept = policy.apply(to: reports.shuffled(), now: DiagnosticFixtures.now)
        #expect(kept.map(\.id) == [1, 2, 3].map(DiagnosticFixtures.id))
    }

    @Test("A report from the future (clock moved back) is kept")
    func keepsFutureReports() {
        let kept = policy.apply(to: [DiagnosticFixtures.report(1, daysAgo: -1)], now: DiagnosticFixtures.now)
        #expect(kept.count == 1)
    }

    @Test("Merging skips a payload already stored and applies the policy")
    func mergeDeduplicates() {
        let existing = [
            DiagnosticFixtures.report(1, daysAgo: 1, payload: "same"),
            DiagnosticFixtures.report(2, daysAgo: 40)
        ]
        let incoming = [
            DiagnosticFixtures.report(3, daysAgo: 0, payload: "same"),
            DiagnosticFixtures.report(4, daysAgo: 0),
            DiagnosticFixtures.report(5, daysAgo: 0, payload: "{\"n\":4}")
        ]
        let merged = policy.merge(incoming, into: existing, now: DiagnosticFixtures.now)
        #expect(merged.map(\.id) == [DiagnosticFixtures.id(4), DiagnosticFixtures.id(1)])
    }

    @Test("The standard policy keeps 30 days and 50 reports")
    func standardPolicy() {
        #expect(DiagnosticRetention.standard.maxCount == 50)
        #expect(DiagnosticRetention.standard.maxAge == .seconds(30 * 86_400))
        let reports = (0..<60).map { DiagnosticFixtures.report($0, daysAgo: Double($0) * 0.1) }
        #expect(DiagnosticRetention.standard.apply(to: reports, now: DiagnosticFixtures.now).count == 50)
    }
}

// MARK: - Store
@Suite("Diagnostic report store")
struct DiagnosticReportStoreTests {
    @Test("Reports roundtrip through the file store in the envelope format")
    func fileRoundtrip() throws {
        let directory = try DiagnosticFixtures.makeDirectory()
        let store = FileDiagnosticReportStore(directory: directory)
        #expect(try store.load().isEmpty)

        let reports = DiagnosticPreviewData.payloads.enumerated().compactMap { index, payload in
            DiagnosticReportParser.report(
                from: payload, id: DiagnosticFixtures.id(index),
                receivedAt: DiagnosticFixtures.now)
        }
        try store.replaceAll(with: reports)

        #expect(try store.load() == reports)
        let url = directory.appending(path: "diagnostics.json")
        let root = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        #expect(root["schemaVersion"] as? Int == 1)
        #expect(root["payload"] is [Any])
    }

    @Test("An unreadable file throws and is never overwritten")
    func corruptFileBlocksWrites() throws {
        let directory = try DiagnosticFixtures.makeDirectory()
        let url = directory.appending(path: "diagnostics.json")
        try Data("{broken".utf8).write(to: url)
        let store = FileDiagnosticReportStore(directory: directory)

        #expect(throws: (any Error).self) { try store.load() }
        #expect(throws: (any Error).self) { try store.replaceAll(with: []) }
        #expect(try Data(contentsOf: url) == Data("{broken".utf8))
    }
}

// MARK: - Service
@Suite("Diagnostics service")
struct DiagnosticsServiceTests {
    private func makeService(
        store: InMemoryDiagnosticReportStore,
        now: Date = DiagnosticFixtures.now,
        ids: [UUID] = []
    ) -> DiagnosticsService {
        let sequence = IDSequence(ids)
        return DiagnosticsService(store: store, now: { now }, makeID: { sequence.make() })
    }

    @Test("Recorded payloads are parsed, stored and listed newest first")
    func recordStoresReports() async throws {
        let store = InMemoryDiagnosticReportStore()
        let service = makeService(store: store, ids: [DiagnosticFixtures.id(1), DiagnosticFixtures.id(2)])

        await service.record([
            .diagnostic(try DiagnosticFixtures.diagnosticPayload()),
            .metrics(try DiagnosticFixtures.metricPayload())
        ])

        let reports = try await service.reports()
        #expect(reports.count == 2)
        #expect(Set(reports.map(\.id)) == [DiagnosticFixtures.id(1), DiagnosticFixtures.id(2)])
        #expect(Set(reports.compactMap(\.primaryKind)) == [.crash, .metrics])
        #expect(reports.allSatisfy { $0.receivedAt == DiagnosticFixtures.now })
        #expect(store.saveCount == 1)
    }

    @Test("The same payload delivered twice is kept once")
    func recordDeduplicates() async throws {
        let store = InMemoryDiagnosticReportStore()
        let service = makeService(store: store)
        let payload = MetricKitPayload.metrics(try DiagnosticFixtures.metricPayload())

        await service.record([payload])
        await service.record([payload])

        #expect(try await service.reports().count == 1)
    }

    @Test("Recording applies retention to what was stored")
    func recordAppliesRetention() async throws {
        let store = InMemoryDiagnosticReportStore(initial: [
            DiagnosticFixtures.report(1, daysAgo: 45),
            DiagnosticFixtures.report(2, daysAgo: 3)
        ])
        let service = makeService(store: store, ids: [DiagnosticFixtures.id(3)])

        await service.record([.metrics(try DiagnosticFixtures.metricPayload())])

        #expect(store.reports.map(\.id) == [DiagnosticFixtures.id(3), DiagnosticFixtures.id(2)])
    }

    @Test("Arrival dates are whole seconds, like the file keeps them")
    func wholeSecondArrival() async throws {
        let store = InMemoryDiagnosticReportStore()
        let service = makeService(store: store, now: DiagnosticFixtures.now.addingTimeInterval(0.75))

        await service.record([.metrics(try DiagnosticFixtures.metricPayload())])

        #expect(store.reports.first?.receivedAt == DiagnosticFixtures.now)
    }

    @Test("When the saved reports can't be read, nothing is written and reading throws")
    func unreadableStore() async throws {
        let store = InMemoryDiagnosticReportStore(failure: .init())
        let service = makeService(store: store)

        await service.record([.metrics(try DiagnosticFixtures.metricPayload())])

        #expect(store.saveCount == 0)
        await #expect(throws: InMemoryDiagnosticReportStore.Failure.self) { try await service.reports() }
    }

    @Test("Deleting some reports keeps the rest; deleting all empties the store")
    func deleting() async throws {
        let store = InMemoryDiagnosticReportStore(initial: (1...3).map { DiagnosticFixtures.report($0, daysAgo: Double($0)) })
        let service = makeService(store: store)

        let left = try await service.delete(ids: [DiagnosticFixtures.id(2)])
        #expect(left.map(\.id) == [DiagnosticFixtures.id(1), DiagnosticFixtures.id(3)])
        #expect(store.reports.map(\.id) == [DiagnosticFixtures.id(1), DiagnosticFixtures.id(3)])

        try await service.deleteAll()
        #expect(store.reports.isEmpty)
    }

    @Test("Reports past retention are left out of the list")
    func readingAppliesRetention() async throws {
        let store = InMemoryDiagnosticReportStore(initial: [DiagnosticFixtures.report(1, daysAgo: 31)])
        let service = makeService(store: store)
        #expect(try await service.reports().isEmpty)
    }
}

// MARK: - Export
@Suite("Diagnostic export")
struct DiagnosticExportTests {
    @Test("The export embeds MetricKit's JSON as JSON with the app version")
    func exportFormat() throws {
        let report = try #require(
            DiagnosticReportParser.report(
                from: .metrics(try DiagnosticFixtures.metricPayload()), receivedAt: DiagnosticFixtures.now))
        let data = try DiagnosticExport.data(for: [report], appVersion: "1.0 (7)", exportedAt: DiagnosticFixtures.now)
        let root = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(root["app"] as? String == "CaliPark")
        #expect(root["appVersion"] as? String == "1.0 (7)")
        #expect(root["exportedAt"] as? String == "2026-11-03T21:15:00Z")
        let reports = try #require(root["reports"] as? [[String: Any]])
        #expect(reports.count == 1)
        #expect(reports[0]["receivedAt"] as? String == "2026-11-03T21:15:00Z")
        #expect(reports[0]["kinds"] as? [String] == ["metrics"])
        let payload = try #require(reports[0]["payload"] as? [String: Any])
        #expect(payload["appVersion"] as? String == "1.0")
    }

    @Test("A payload that isn't JSON goes in as text")
    func textPayload() throws {
        let report = DiagnosticFixtures.report(1, daysAgo: 0, payload: "not json")
        let data = try DiagnosticExport.data(for: [report], appVersion: "1.0 (7)", exportedAt: DiagnosticFixtures.now)
        let root = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let reports = try #require(root["reports"] as? [[String: Any]])
        #expect(reports[0]["payload"] as? String == "not json")
    }

    @Test("The file name carries the day in the user's calendar")
    func fileName() {
        #expect(
            DiagnosticExport.fileName(for: DiagnosticFixtures.now, calendar: DiagnosticFixtures.utc)
                == "calipark-diagnostyka-2026-11-03.json")
        var warsaw = DiagnosticFixtures.utc
        warsaw.timeZone = TimeZone(identifier: "Europe/Warsaw")!
        // 21:15 UTC is 22:15 in Warsaw: same day. 23:30 UTC is the next day there.
        #expect(
            DiagnosticExport.fileName(for: DiagnosticFixtures.now.addingTimeInterval(8_100), calendar: warsaw)
                == "calipark-diagnostyka-2026-11-04.json")
    }

    @Test("The mail subject carries the app version")
    func mailSubject() {
        #expect(
            DiagnosticExport.mailSubject(version: AppVersion(version: "1.0", build: "7"))
                == "CaliPark 1.0 (7): diagnostyka")
    }
}

// MARK: - Format
@Suite("Diagnostics texts")
struct DiagnosticsFormatTests {
    @Test("The row subtitle has the date, the version and the number of events")
    func subtitle() throws {
        let report = try #require(
            DiagnosticReportParser.diagnosticReport(
                from: try DiagnosticFixtures.diagnosticPayload(), receivedAt: DiagnosticFixtures.now))
        let text = DiagnosticsFormat.subtitle(for: report, locale: Locale(identifier: "pl_PL"), timeZone: .gmt)
        #expect(text.hasSuffix(" · wersja 1.0 (7) · 5 zdarzeń"))
        #expect(text.contains("2026"))
    }

    @Test("A single-event report has no event count")
    func singleEvent() throws {
        let report = DiagnosticFixtures.report(1, daysAgo: 0)
        let text = DiagnosticsFormat.subtitle(for: report, locale: Locale(identifier: "pl_PL"), timeZone: .gmt)
        #expect(text.hasSuffix(" · wersja 1.0 (7)"))
    }

    @Test("Every kind has its own title, and an unknown report a generic one")
    func titles() {
        let titles = DiagnosticKind.allCases.map { DiagnosticsFormat.title(for: $0) }
        #expect(Set(titles).count == DiagnosticKind.allCases.count)
        #expect(DiagnosticsFormat.title(for: nil) == "Raport diagnostyczny")
        #expect(DiagnosticsFormat.events(1) == "1 zdarzenie")
        #expect(DiagnosticsFormat.events(3) == "3 zdarzenia")
        #expect(DiagnosticsFormat.events(12) == "12 zdarzeń")
    }

    @Test("Kinds order from the most to the least severe")
    func severity() {
        #expect(DiagnosticKind.allCases.sorted() == [.crash, .hang, .cpuException, .diskWriteException, .appLaunch, .metrics])
        let report = DiagnosticReport(
            receivedAt: DiagnosticFixtures.now,
            entries: [
                DiagnosticEntry(kind: .metrics), DiagnosticEntry(kind: .hang),
                DiagnosticEntry(kind: .hang)
            ],
            payload: "{}")
        #expect(report.kinds == [.hang, .metrics])
    }
}

// MARK: - View model
@MainActor
@Suite("Diagnostics screen")
struct DiagnosticsViewModelTests {
    private func makeViewModel(store: InMemoryDiagnosticReportStore) -> DiagnosticsViewModel {
        DiagnosticsViewModel(
            service: DiagnosticsService(store: store, now: { DiagnosticFixtures.now }),
            appVersion: AppVersion(version: "1.0", build: "7"),
            calendar: DiagnosticFixtures.utc,
            clock: { DiagnosticFixtures.now }
        )
    }

    @Test("Loading lists the reports and sending attaches only the selected ones")
    func loadAndSelect() async throws {
        let store = InMemoryDiagnosticReportStore(initial: (1...3).map { DiagnosticFixtures.report($0, daysAgo: Double($0)) })
        let viewModel = makeViewModel(store: store)
        #expect(viewModel.selectionAttachment == nil)

        await viewModel.load()
        #expect(viewModel.hasLoaded)
        #expect(viewModel.reports.map(\.id) == [1, 2, 3].map(DiagnosticFixtures.id))

        viewModel.toggleSelection(DiagnosticFixtures.id(3))
        viewModel.toggleSelection(DiagnosticFixtures.id(2))
        viewModel.toggleSelection(DiagnosticFixtures.id(1))
        viewModel.toggleSelection(DiagnosticFixtures.id(2))
        #expect(viewModel.selection == [DiagnosticFixtures.id(1), DiagnosticFixtures.id(3)])
        let attachment = try #require(viewModel.selectionAttachment)
        #expect(attachment.reports.map(\.id) == [DiagnosticFixtures.id(1), DiagnosticFixtures.id(3)])
        #expect(attachment.fileName == "calipark-diagnostyka-2026-11-03.json")
        #expect(viewModel.mailSubject == "CaliPark 1.0 (7): diagnostyka")
    }

    @Test("An unreadable store shows an error, not an empty history")
    func loadFailure() async {
        let viewModel = makeViewModel(store: InMemoryDiagnosticReportStore(failure: .init()))
        await viewModel.load()
        #expect(viewModel.loadFailed)
        #expect(viewModel.errorMessage == DiagnosticsFormat.loadFailureMessage)
    }

    @Test("Deleting one report drops it from the list and the selection")
    func deleteOne() async {
        let store = InMemoryDiagnosticReportStore(initial: (1...2).map { DiagnosticFixtures.report($0, daysAgo: Double($0)) })
        let viewModel = makeViewModel(store: store)
        await viewModel.load()
        viewModel.selection = [DiagnosticFixtures.id(1), DiagnosticFixtures.id(2)]

        await viewModel.delete(ids: [DiagnosticFixtures.id(1)])

        #expect(viewModel.reports.map(\.id) == [DiagnosticFixtures.id(2)])
        #expect(viewModel.selection == [DiagnosticFixtures.id(2)])
    }

    @Test("\"Usuń wszystko\" empties the list and the store; a failure shows an error")
    func deleteAll() async {
        let store = InMemoryDiagnosticReportStore(initial: [DiagnosticFixtures.report(1, daysAgo: 1)])
        let viewModel = makeViewModel(store: store)
        await viewModel.load()

        await viewModel.deleteAll()
        #expect(viewModel.reports.isEmpty)
        #expect(store.reports.isEmpty)

        store.setFailure(.init())
        await viewModel.deleteAll()
        #expect(viewModel.errorMessage == DiagnosticsFormat.deleteFailureMessage)
    }
}
