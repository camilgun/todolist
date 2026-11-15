import Foundation

/// Works out which day a moment belongs to. A day ends at a configurable time
/// in the morning (4:00 by default), not at midnight, so late work still counts
/// for the day it started.
public struct DayClock: Sendable {
    public var dayStartMinutes: Int
    public var calendar: Calendar

    public init(dayStartMinutes: Int, calendar: Calendar = .current) {
        self.dayStartMinutes = dayStartMinutes
        self.calendar = calendar
    }

    /// The day containing `date`, from its start to the start of the next day.
    public func day(containing date: Date) -> DateInterval {
        let todayStart = start(ofCalendarDayContaining: date)
        let dayStart: Date
        if date < todayStart {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: date)!
            dayStart = start(ofCalendarDayContaining: yesterday)
        } else {
            dayStart = todayStart
        }
        let nextCalendarDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: dayStart))!
        let dayEnd = start(ofCalendarDayContaining: nextCalendarDay)
        return DateInterval(start: dayStart, end: dayEnd)
    }

    /// The day just before or after `day`.
    public func day(_ day: DateInterval, offsetBy days: Int) -> DateInterval {
        let middle = day.start.addingTimeInterval(day.duration / 2)
        let shifted = calendar.date(byAdding: .day, value: days, to: middle)!
        return self.day(containing: shifted)
    }

    /// The configured start time on the calendar date of `date`.
    private func start(ofCalendarDayContaining date: Date) -> Date {
        let midnight = calendar.startOfDay(for: date)
        return calendar.date(
            bySettingHour: dayStartMinutes / 60,
            minute: dayStartMinutes % 60,
            second: 0,
            of: midnight
        ) ?? midnight.addingTimeInterval(TimeInterval(dayStartMinutes * 60))
    }
}
