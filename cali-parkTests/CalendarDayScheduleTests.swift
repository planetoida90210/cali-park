import Foundation
import Testing

@testable import cali_park

// MARK: - Fixtures

private enum Zones {
    static let warsaw = TestCalendar.warsaw
    static let london = TestCalendar.gregorian(in: "Europe/London")
    static let newYork = TestCalendar.gregorian(in: "America/New_York")

    /// 10 Nov 2026.
    static let november10 = CalendarDay(year: 2026, month: 11, day: 10)!

    /// `hour`:00 on `day` November 2026 in `calendar`.
    static func date(_ day: Int, hour: Int = 0, in calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour))!
    }

    static func directory() throws -> URL {
        let url = try TemporaryDirectory.make("CalendarDayScheduleTests")
        return url
    }

    /// A version 1 plans file (bare array): a one-off plan saved in Warsaw for
    /// 10 Nov, which the old format stored as Warsaw midnight, 23:00 UTC the
    /// day before, and an every-3-days plan anchored on 2 Nov the same way.
    static let legacyPlansJSON = """
        [{"id":"C0000000-0000-4000-8000-000000000010","name":"Wyjazd","isActive":true,\
        "createdAt":"2026-11-01T10:00:00Z","exercises":[],\
        "schedule":{"once":{"_0":"2026-11-09T23:00:00Z"}}},\
        {"id":"C0000000-0000-4000-8000-000000000011","name":"Co 3 dni","isActive":true,\
        "createdAt":"2026-11-01T10:00:00Z","exercises":[],\
        "schedule":{"everyNDays":{"_0":3,"from":"2026-11-01T23:00:00Z"}}}]
        """
}

// MARK: - CalendarDay

@Suite("CalendarDay")
struct CalendarDayTests {
    @Test
    func theDayComesFromTheCalendarsTimeZone() {
        // 23:30 UTC on 9 Nov is already 10 Nov in Warsaw, still 9 Nov in New York.
        let instant = Zones.date(9, hour: 23, in: Zones.london).addingTimeInterval(30 * 60)
        #expect(CalendarDay(instant, in: Zones.warsaw) == Zones.november10)
        #expect(CalendarDay(instant, in: Zones.newYork) == CalendarDay(year: 2026, month: 11, day: 9))
    }

    @Test
    func startDateIsLocalMidnightInEachZone() {
        #expect(Zones.november10.startDate(in: Zones.warsaw) == Zones.date(10, in: Zones.warsaw))
        #expect(Zones.november10.startDate(in: Zones.london) == Zones.date(10, in: Zones.london))
        #expect(Zones.november10.startDate(in: Zones.newYork) == Zones.date(10, in: Zones.newYork))
    }

    @Test
    func encodesAsAPlainDay() throws {
        let data = try JSONFileFormat.encoder.encode([Zones.november10])
        #expect(String(decoding: data, as: UTF8.self) == #"["2026-11-10"]"#)
        #expect(try JSONFileFormat.decoder.decode([CalendarDay].self, from: data) == [Zones.november10])
    }

    @Test
    func aLegacyInstantDecodesAsItsDayInTheGivenCalendar() throws {
        let data = Data(#"["2026-11-09T23:00:00Z"]"#.utf8)
        let warsaw = JSONFileFormat.decoder(forSchemaVersion: 1, userInfo: [CalendarDay.legacyCalendarKey: Zones.warsaw])
        let london = JSONFileFormat.decoder(forSchemaVersion: 1, userInfo: [CalendarDay.legacyCalendarKey: Zones.london])

        #expect(try warsaw.decode([CalendarDay].self, from: data) == [Zones.november10])
        #expect(try london.decode([CalendarDay].self, from: data) == [CalendarDay(year: 2026, month: 11, day: 9)!])
    }

    @Test(arguments: ["2026-02-30", "2026-13-01", "26-11-10", "2026-11-10x", "", "tomorrow"])
    func invalidDaysAreRejected(_ text: String) {
        let data = Data("[\"\(text)\"]".utf8)
        #expect(throws: DecodingError.self) { try JSONFileFormat.decoder.decode([CalendarDay].self, from: data) }
    }

    @Test
    func daysOrderByDate() {
        let days = [
            CalendarDay(year: 2027, month: 1, day: 1)!, Zones.november10,
            CalendarDay(year: 2026, month: 12, day: 9)!
        ]
        #expect(
            days.sorted() == [
                Zones.november10, CalendarDay(year: 2026, month: 12, day: 9)!,
                CalendarDay(year: 2027, month: 1, day: 1)!
            ])
    }
}

// MARK: - B-9: schedules across time zones

@Suite("Day-only schedules keep their day after a time-zone change (B-9)", .temporaryDirectories)
struct ScheduleTimeZoneTests {
    @Test
    func aOneOffPlanStaysOnItsDayAfterTravellingWest() {
        // Picked in Warsaw: the editor's date is Warsaw midnight of 10 Nov.
        let schedule = WorkoutSchedule.once(CalendarDay(Zones.date(10, in: Zones.warsaw), in: Zones.warsaw))

        for calendar in [Zones.warsaw, Zones.london, Zones.newYork] {
            let morningOf9th = Zones.date(9, hour: 8, in: calendar)
            #expect(
                schedule.nextOccurrence(onOrAfter: morningOf9th, calendar: calendar)
                    == Zones.date(10, in: calendar))
            let morningOf10th = Zones.date(10, hour: 8, in: calendar)
            #expect(
                schedule.nextOccurrence(onOrAfter: morningOf10th, calendar: calendar)
                    == Zones.date(10, in: calendar))
        }
    }

    @Test
    func anIntervalKeepsItsAnchorDayAfterTravellingWest() {
        let schedule = WorkoutSchedule.everyNDays(3, from: CalendarDay(year: 2026, month: 11, day: 2)!)

        for calendar in [Zones.warsaw, Zones.london, Zones.newYork] {
            // 2, 5, 8, 11 Nov.
            #expect(
                schedule.nextOccurrence(onOrAfter: Zones.date(6, hour: 9, in: calendar), calendar: calendar)
                    == Zones.date(8, in: calendar))
        }
    }

    @Test
    func theListShowsTheSameDateInEveryZone() {
        let schedule = WorkoutSchedule.once(Zones.november10)
        let warsaw = WorkoutScheduleFormatter.summary(schedule, calendar: Zones.warsaw)
        #expect(WorkoutScheduleFormatter.summary(schedule, calendar: Zones.newYork) == warsaw)
        #expect(WorkoutScheduleFormatter.summary(schedule, calendar: Zones.london) == warsaw)
    }

    @Test
    func aLegacyPlansFileMigratesToDaysAndRewritesInVersion2() throws {
        let directory = try Zones.directory()
        let url = directory.appending(path: "workout-plans.json")
        try Data(Zones.legacyPlansJSON.utf8).write(to: url)

        // The plans were saved in Warsaw and the app reads them there.
        let store = FileWorkoutPlanStore(directory: directory, calendar: Zones.warsaw)
        let plans = try store.load()
        #expect(
            plans.map(\.schedule) == [
                .once(Zones.november10),
                .everyNDays(3, from: CalendarDay(year: 2026, month: 11, day: 2)!)
            ])

        // Saving rewrites the file as version 2 with plain days.
        try store.save(plans[0])
        let text = try String(decoding: Data(contentsOf: url), as: UTF8.self)
        #expect(text.contains(#""schemaVersion":2"#))
        #expect(text.contains(#""2026-11-10""#))
        #expect(text.contains("T23:00:00Z") == false)

        // Read later in London, the day doesn't move.
        let afterTravel = try FileWorkoutPlanStore(directory: directory, calendar: Zones.london).load()
        #expect(
            afterTravel[0].nextOccurrence(
                onOrAfter: Zones.date(9, hour: 8, in: Zones.london),
                calendar: Zones.london) == Zones.date(10, in: Zones.london))
    }

    @Test
    func aVersion1BackupWithInstantSchedulesStillImports() throws {
        let json = """
            {"format":"calipark-backup","schemaVersion":1,"exportedAt":"2026-11-04T18:30:00Z",\
            "appVersion":"1.0 (1)","payload":{"workoutLog":[],"workoutPlans":\(Zones.legacyPlansJSON),\
            "placement":null,"skillProgress":null,"weeklyGoal":null}}
            """
        let backup = try TrainingBackupCodec.decode(Data(json.utf8))

        try #require(backup.workoutPlans.count == 2)
        guard case .once(let day?) = backup.workoutPlans[0].schedule else {
            Issue.record("Expected a dated one-off plan")
            return
        }
        // Read in the current calendar, which lands on 9 or 10 Nov depending on
        // the machine's zone; either way it is a day, not an instant.
        #expect(day.year == 2026 && day.month == 11 && (9...10).contains(day.day))
    }

    @Test
    func aBackupRoundTripKeepsDays() throws {
        let plan = WorkoutPlan(name: "Wyjazd", schedule: .once(Zones.november10), createdAt: Zones.date(1, in: Zones.warsaw))
        let data = try TrainingBackupCodec.encode(
            TrainingBackup(workoutPlans: [plan]),
            exportedAt: Zones.date(4, in: Zones.warsaw), appVersion: "1.0 (1)")
        #expect(String(decoding: data, as: UTF8.self).contains(#""2026-11-10""#))
        #expect(try TrainingBackupCodec.decode(data).workoutPlans == [plan])
    }
}

// MARK: - B-8: one-off plans in the past

@MainActor
@Suite("One-off plans can't be saved in the past (B-8)", .temporaryDirectories, .timeLimit(.minutes(1)))
struct PastOneOffPlanTests {
    private let calendar = Zones.warsaw
    /// 4 Nov 2026, 15:00 in Warsaw.
    private var now: Date { Zones.date(4, hour: 15, in: calendar) }

    private func editor(_ plan: WorkoutPlan? = nil) -> PlanEditorViewModel {
        let editor = PlanEditorViewModel(
            plan: plan, service: .testing(InMemoryWorkoutPlanStore()),
            calendar: calendar, now: now)
        if plan == nil {
            editor.name = "Wyjazd"
            editor.addExercise(ExerciseCatalog.all[0])
        }
        editor.scheduleMode = .once
        return editor
    }

    @Test
    func yesterdayCannotBeSavedAndSaysWhy() {
        let editor = editor()
        editor.onceDate = Zones.date(3, in: calendar)

        #expect(editor.isOnceDateInPast)
        #expect(editor.canSave == false)
        #expect(editor.scheduleProblem?.contains("minęła") == true)
    }

    @Test
    func todayAndLaterCanBeSaved() {
        let editor = editor()
        #expect(editor.onceDate == Zones.date(4, in: calendar))
        #expect(editor.canSave)
        #expect(editor.scheduleProblem == nil)

        editor.onceDate = Zones.date(20, in: calendar)
        #expect(editor.canSave)
        #expect(editor.earliestOnceDate == Zones.date(4, in: calendar))
    }

    @Test
    func thePastOnlyMattersInOneOffMode() {
        let editor = editor()
        editor.onceDate = Zones.date(3, in: calendar)
        editor.scheduleMode = .weekly
        editor.toggle(.monday)

        #expect(editor.canSave)
        #expect(editor.scheduleProblem == nil)
    }

    @Test
    func savingAPastDateDoesNothing() async {
        let store = InMemoryWorkoutPlanStore()
        let editor = PlanEditorViewModel(plan: nil, service: .testing(store), calendar: calendar, now: now)
        editor.name = "Wyjazd"
        editor.addExercise(ExerciseCatalog.all[0])
        editor.scheduleMode = .once
        editor.onceDate = Zones.date(1, in: calendar)

        await editor.save()

        #expect(editor.didSave == false)
        #expect(store.load().isEmpty)
    }

    @Test
    func anExpiredPlanOpensOnItsOwnDateAndAsksForANewOne() {
        let expired = WorkoutPlan(
            name: "Stary", exercises: [PlannedExercise(exerciseID: ExerciseCatalog.all[0].id)],
            schedule: .once(CalendarDay(year: 2026, month: 10, day: 20)!),
            createdAt: Zones.date(1, in: calendar))
        let editor = editor(expired)

        #expect(editor.onceDate == CalendarDay(year: 2026, month: 10, day: 20)!.startDate(in: calendar))
        #expect(editor.earliestOnceDate == editor.onceDate)
        #expect(editor.canSave == false)
        #expect(editor.hasUnsavedChanges == false)

        editor.onceDate = Zones.date(6, in: calendar)
        #expect(editor.canSave)
    }

    @Test
    func anExpiredPlanStillLoadsAndNeverOccurs() throws {
        let directory = try Zones.directory()
        let expired = WorkoutPlan(
            name: "Stary", schedule: .once(CalendarDay(year: 2026, month: 10, day: 20)!),
            createdAt: Zones.date(1, in: calendar))
        try FileWorkoutPlanStore(directory: directory, calendar: calendar).save(expired)

        let plans = try FileWorkoutPlanStore(directory: directory, calendar: calendar).load()

        #expect(plans == [expired])
        #expect(plans[0].nextOccurrence(onOrAfter: now, calendar: calendar) == nil)
    }
}
