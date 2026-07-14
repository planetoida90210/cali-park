import Foundation

// MARK: - WorkoutStreak
/// Pure, testable streak math derived from workout log dates.
/// A streak is a run of consecutive calendar days with at least one logged
/// workout. Training yesterday (but not yet today) keeps the streak alive.
struct WorkoutStreak: Equatable {
    /// Length of the run that is still alive today (0 after a gap).
    let current: Int
    /// The longest run ever recorded.
    let longest: Int
    /// Start-of-day dates with at least one workout — for calendar rendering.
    let trainedDays: Set<Date>

    static func compute(from dates: [Date],
                        calendar: Calendar = .current,
                        today: Date = .now) -> WorkoutStreak {
        let days = Set(dates.map { calendar.startOfDay(for: $0) })
        return WorkoutStreak(
            current: currentRun(in: days, calendar: calendar, today: today),
            longest: longestRun(in: days, calendar: calendar),
            trainedDays: days
        )
    }

    // MARK: Private

    private static func currentRun(in days: Set<Date>, calendar: Calendar, today: Date) -> Int {
        var day = calendar.startOfDay(for: today)
        // Not trained today yet? The streak survives if yesterday was trained.
        if !days.contains(day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }

        var run = 0
        while days.contains(day) {
            run += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return run
    }

    private static func longestRun(in days: Set<Date>, calendar: Calendar) -> Int {
        var longest = 0
        for day in days {
            // Only walk forward from the first day of each run.
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day),
                  !days.contains(previous) else { continue }

            var run = 1
            var cursor = day
            while let next = calendar.date(byAdding: .day, value: 1, to: cursor),
                  days.contains(next) {
                run += 1
                cursor = next
            }
            longest = max(longest, run)
        }
        return longest
    }
}
