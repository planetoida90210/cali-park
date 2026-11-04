import Foundation
import Testing

/// The shared test helpers do what the other suites rely on.
@Suite("Test support", .temporaryDirectories)
struct TestSupportTests {
    @Test
    func theTraitOpensAScopePerTestCase() throws {
        let directory = try TemporaryDirectory.make("TestSupportTests")

        var isDirectory: ObjCBool = false
        #expect(FileManager.default.fileExists(atPath: directory.path(percentEncoded: false), isDirectory: &isDirectory))
        #expect(isDirectory.boolValue)
    }

    @Test(arguments: [1, 2])
    func parameterizedCasesEachGetAScope(_ argument: Int) throws {
        _ = argument
        #expect(TemporaryDirectory.scope != nil)
    }

    @Test
    func aScopeRemovesEveryDirectoryItMade() throws {
        let scope = TemporaryDirectory.Scope()
        let (made, unused) = try TemporaryDirectory.$scope.withValue(scope) {
            (try TemporaryDirectory.make("TestSupportTests"), try TemporaryDirectory.unusedURL("TestSupportTests"))
        }
        try Data("x".utf8).write(to: made.appending(path: "file.json"))
        try FileManager.default.createDirectory(at: unused, withIntermediateDirectories: true)

        scope.removeAll()

        #expect(FileManager.default.fileExists(atPath: made.path(percentEncoded: false)) == false)
        #expect(FileManager.default.fileExists(atPath: unused.path(percentEncoded: false)) == false)
    }

    @Test
    func theUTCCalendarIsFixed() {
        #expect(TestCalendar.utc.timeZone == TimeZone(identifier: "UTC"))
        #expect(TestCalendar.utc.firstWeekday == 1)
        #expect(TestCalendar.utc.component(.weekday, from: TestDate.epochDay(0)) == 5) // Thursday
        #expect(TestDate.at(2026, 11, 4) == TestDate.reference)
    }

    @Test
    func warsawHasBothClockChangesIn2026() {
        let warsaw = TestCalendar.warsaw
        let springDay = warsaw.dateInterval(of: .day, for: TestDate.at(2026, 3, 29, 12, in: warsaw))
        let autumnDay = warsaw.dateInterval(of: .day, for: TestDate.at(2026, 10, 25, 12, in: warsaw))
        #expect(springDay?.duration == TimeInterval(23 * 3_600))
        #expect(autumnDay?.duration == TimeInterval(25 * 3_600))
    }
}
