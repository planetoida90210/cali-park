import Foundation
import Synchronization

// MARK: - InMemoryDiagnosticReportStore
/// Non-persistent store for previews and unit tests. `failure` makes every
/// call throw, like a broken file. A `Mutex` keeps it `Sendable`, because the
/// service that owns it is an actor while tests read it from outside.
nonisolated final class InMemoryDiagnosticReportStore: DiagnosticReportStoring {
    struct Failure: Error, Equatable {}

    private struct State {
        var reports: [DiagnosticReport]
        var failure: Failure?
        var saveCount = 0
    }

    private let state: Mutex<State>

    init(initial: [DiagnosticReport] = [], failure: Failure? = nil) {
        state = Mutex(State(reports: initial, failure: failure))
    }

    /// What is saved now, for assertions.
    var reports: [DiagnosticReport] { state.withLock { $0.reports } }

    /// How many times `replaceAll` succeeded, so tests can assert writes.
    var saveCount: Int { state.withLock { $0.saveCount } }

    func setFailure(_ failure: Failure?) {
        state.withLock { $0.failure = failure }
    }

    func load() throws -> [DiagnosticReport] {
        try state.withLock { state in
            if let failure = state.failure { throw failure }
            return state.reports
        }
    }

    func replaceAll(with reports: [DiagnosticReport]) throws {
        try state.withLock { state in
            if let failure = state.failure { throw failure }
            state.reports = reports
            state.saveCount += 1
        }
    }
}
