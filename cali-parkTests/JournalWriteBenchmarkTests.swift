import Foundation
import Testing
@testable import cali_park

// MARK: - Journal write benchmark (C-8, D-7)
/// Times the journal file at a size a heavy athlete reaches after years:
/// 10,000 entries (about 6 years of 4 sessions a week, 8 exercises each).
///
/// Off in the normal test run, because it writes a few MB several times and
/// its numbers only mean something on a quiet machine. Run it with:
///
///     TEST_RUNNER_CALIPARK_BENCHMARK=1 xcodebuild … \
///       -only-testing:cali-parkTests/JournalWriteBenchmarkTests test
///
/// The medians are printed to the test log (`[benchmark] …`). The results and
/// the accepted limit are recorded in `docs/audit/STATUS.md` under C-8/D-7.
@MainActor
@Suite(.enabled(if: JournalBenchmark.isEnabled, "Set CALIPARK_BENCHMARK=1 to run"), .serialized, .temporaryDirectories)
struct JournalWriteBenchmarkTests {
    @Test("Load, log and delete on a 10,000-entry journal file")
    func journalFileAtTenThousandEntries() async throws {
        let directory = try TemporaryDirectory.make("JournalBenchmark")

        let entries = JournalBenchmark.entries(count: 10_000)
        let store = FileWorkoutLogStore(directory: directory)
        try await store.replaceAll(with: entries)
        let fileURL = directory.appending(path: StoreFile.workoutLog.fileName)
        let bytes = try FileManager.default.attributesOfItem(atPath: fileURL.path())[.size] as? Int ?? 0

        let load = try await JournalBenchmark.median(runs: 7) {
            _ = try store.load()
        }

        let journal = TrainingJournal(store: store)
        #expect(journal.entries.count == 10_000)

        var logged: [WorkoutLogEntry] = []
        let log = try await JournalBenchmark.median(runs: 7) {
            let entry = WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID,
                                        date: JournalBenchmark.start,
                                        sets: [LoggedSet(reps: 8)])
            logged.append(entry)
            try await journal.log(entry)
        }

        var remaining = logged
        let delete = try await JournalBenchmark.median(runs: 7) {
            let entry = remaining.removeLast()
            try await journal.delete(ids: [entry.id])
        }

        // The journal's own in-memory work per change (sorting, comparing),
        // without the file, to tell the two costs apart.
        let memoryJournal = TrainingJournal(store: InMemoryWorkoutLogStore(initial: entries))
        let inMemoryLog = try await JournalBenchmark.median(runs: 7) {
            try await memoryJournal.log(WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID,
                                                  date: JournalBenchmark.start,
                                                  sets: [LoggedSet(reps: 8)]))
        }

        // The longest the main actor stayed busy while a save went through
        // the file: what the user feels as a hitch.
        let stall = try await JournalBenchmark.longestMainActorStall {
            try await journal.log(WorkoutLogEntry(exerciseID: ExerciseCatalog.pullUpsID,
                                                  date: JournalBenchmark.start,
                                                  sets: [LoggedSet(reps: 8)]))
        }

        print("""
            [benchmark] journal file: \(entries.count) entries, \(bytes / 1024) KB
            [benchmark] store.load(): \(JournalBenchmark.format(load))
            [benchmark] journal.log(_:) through the file: \(JournalBenchmark.format(log))
            [benchmark] journal.delete(ids:) through the file: \(JournalBenchmark.format(delete))
            [benchmark] journal.log(_:) in memory only: \(JournalBenchmark.format(inMemoryLog))
            [benchmark] longest main-actor stall during a save: \(JournalBenchmark.format(stall))
            """)
        #expect(journal.entries.count == 10_001)
    }
}

// MARK: - Support
nonisolated enum JournalBenchmark {
    static var isEnabled: Bool {
        ProcessInfo.processInfo.environment["CALIPARK_BENCHMARK"] != nil
    }

    /// 2026-11-04T08:00:00Z, the newest workout.
    static let start = Date(timeIntervalSince1970: 1_793_779_200)

    /// `count` entries in sessions of 8 exercises, 4 sessions a week going back
    /// from `start`, with 3–5 sets each, a few timed holds and some plans.
    static func entries(count: Int) -> [WorkoutLogEntry] {
        let exercises = ExerciseCatalog.all.prefix(24).map(\.id)
        let plans = (0..<3).map { _ in UUID() }
        var result: [WorkoutLogEntry] = []
        result.reserveCapacity(count)
        var session = 0
        while result.count < count {
            let sessionID = UUID()
            let planID: UUID? = session.isMultiple(of: 2) ? plans[session % plans.count] : nil
            // 4 sessions a week: one every 42 hours on average.
            let date = start.addingTimeInterval(-Double(session) * 42 * 3600)
            for slot in 0..<8 where result.count < count {
                let exercise = exercises[(session * 3 + slot) % exercises.count]
                let isHold = slot == 7
                let sets = (0..<(3 + slot % 3)).map { set in
                    isHold ? LoggedSet(reps: 1, durationSeconds: 20 + set * 5) : LoggedSet(reps: 6 + (set + slot) % 7)
                }
                result.append(WorkoutLogEntry(exerciseID: exercise,
                                              date: date.addingTimeInterval(Double(slot) * 300),
                                              sets: sets,
                                              sessionID: sessionID,
                                              planID: planID))
            }
            session += 1
        }
        // Saved order is oldest first, as the app appends.
        return result.reversed()
    }

    /// The median of `runs` timings of `body`.
    static func median(runs: Int, _ body: () async throws -> Void) async rethrows -> Duration {
        let clock = ContinuousClock()
        var timings: [Duration] = []
        for _ in 0..<runs {
            let start = clock.now
            try await body()
            timings.append(clock.now - start)
        }
        return timings.sorted()[runs / 2]
    }

    /// Runs `body` on the main actor while a main-actor ticker yields in a
    /// loop, and returns the longest gap between two ticks.
    @MainActor
    static func longestMainActorStall(_ body: () async throws -> Void) async rethrows -> Duration {
        let clock = ContinuousClock()
        let state = StallState()
        let ticker = Task { @MainActor in
            var last = clock.now
            while state.isRunning {
                await Task.yield()
                let now = clock.now
                state.longest = max(state.longest, now - last)
                last = now
            }
        }
        try await body()
        state.isRunning = false
        await ticker.value
        return state.longest
    }

    @MainActor
    private final class StallState {
        var isRunning = true
        var longest = Duration.zero
    }

    static func format(_ duration: Duration) -> String {
        let milliseconds = Double(duration.components.attoseconds) / 1e15 + Double(duration.components.seconds) * 1000
        return "\(milliseconds.formatted(.number.precision(.fractionLength(1)).locale(Locale(identifier: "en_US_POSIX")))) ms"
    }
}
