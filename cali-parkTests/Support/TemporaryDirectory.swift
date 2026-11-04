import Foundation
import Synchronization
import Testing

// MARK: - TemporaryDirectory
/// Scratch directories that are removed when the test that made them ends.
///
/// Give the test or its suite the `.temporaryDirectories` trait, then call
/// `TemporaryDirectory.make()` anywhere the test runs, helpers and suite
/// initializers included. Each test case gets its own scope, so parallel
/// tests never share or delete each other's directories.
enum TemporaryDirectory {
    /// The directories made by the running test case.
    @TaskLocal static var scope: Scope?

    /// Creates an empty directory and registers it for removal at the end of
    /// the running test. Records an issue when the test lacks the trait.
    static func make(_ prefix: String = "CaliParkTests") throws -> URL {
        guard let scope else {
            Issue.record("TemporaryDirectory.make() needs the .temporaryDirectories trait on the test or its suite.")
            throw MissingTrait()
        }
        let url = FileManager.default.temporaryDirectory
            .appending(path: "\(prefix)-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        scope.register(url)
        return url
    }

    /// A path inside the temporary folder that does not exist yet, removed at
    /// the end of the test if something creates it.
    static func unusedURL(_ prefix: String = "CaliParkTests") throws -> URL {
        guard let scope else {
            Issue.record("TemporaryDirectory.unusedURL() needs the .temporaryDirectories trait on the test or its suite.")
            throw MissingTrait()
        }
        let url = FileManager.default.temporaryDirectory
            .appending(path: "\(prefix)-\(UUID().uuidString)", directoryHint: .isDirectory)
        scope.register(url)
        return url
    }

    struct MissingTrait: Error {}

    /// Directories registered by one test case.
    final class Scope: Sendable {
        private let urls = Mutex<[URL]>([])

        func register(_ url: URL) {
            urls.withLock { $0.append(url) }
        }

        func removeAll() {
            let registered = urls.withLock { urls in
                defer { urls.removeAll() }
                return urls
            }
            for url in registered {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}

// MARK: - Trait
/// Opens a `TemporaryDirectory` scope around every test case it applies to.
struct TemporaryDirectoryTrait: TestTrait, SuiteTrait, TestScoping {
    var isRecursive: Bool { true }

    /// One scope per test case; none around a whole suite or test function.
    func scopeProvider(for test: Test, testCase: Test.Case?) -> Self? {
        testCase == nil || test.isSuite ? nil : self
    }

    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @concurrent @Sendable () async throws -> Void
    ) async throws {
        let scope = TemporaryDirectory.Scope()
        defer { scope.removeAll() }
        try await TemporaryDirectory.$scope.withValue(scope) {
            try await function()
        }
    }
}

extension Trait where Self == TemporaryDirectoryTrait {
    /// Directories from `TemporaryDirectory.make()` are removed after each test case.
    static var temporaryDirectories: Self { Self() }
}
