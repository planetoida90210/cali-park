import Foundation
import Testing

@testable import cali_park

/// C-4: the schedule's on-disk shape is frozen, independent of case names.
struct WorkoutScheduleCodingTests {
    private static let day = CalendarDay(year: 2026, month: 11, day: 4)!

    private static func encoded(_ schedule: WorkoutSchedule) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return String(decoding: try encoder.encode(schedule), as: UTF8.self)
    }

    private static func decoded(_ json: String) throws -> WorkoutSchedule {
        try JSONFileFormat.decoder.decode(WorkoutSchedule.self, from: Data(json.utf8))
    }

    static let frozen: [(WorkoutSchedule, String)] = [
        (.once(day), #"{"once":{"_0":"2026-11-04"}}"#),
        (.once(nil), #"{"once":{}}"#),
        (.weekly([.friday, .monday]), #"{"weekly":{"_0":[2,6]}}"#),
        (.everyNDays(3, from: day), #"{"everyNDays":{"_0":3,"from":"2026-11-04"}}"#)
    ]

    @Test(arguments: 0..<frozen.count)
    func encodesTheFrozenShape(index: Int) throws {
        let (schedule, json) = Self.frozen[index]
        #expect(try Self.encoded(schedule) == json)
    }

    @Test(arguments: 0..<frozen.count)
    func decodesTheFrozenShape(index: Int) throws {
        let (schedule, json) = Self.frozen[index]
        #expect(try Self.decoded(json) == schedule)
    }

    @Test
    func aNullDayDecodesAsADraft() throws {
        #expect(try Self.decoded(#"{"once":{"_0":null}}"#) == .once(nil))
    }

    @Test(arguments: [#"{}"#, #"{"monthly":{"_0":1}}"#, #"{"once":{},"weekly":{"_0":[2]}}"#])
    func rejectsAnUnknownOrAmbiguousKind(json: String) {
        #expect(throws: DecodingError.self) { try Self.decoded(json) }
    }
}
