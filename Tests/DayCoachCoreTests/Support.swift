import Foundation
@testable import DayCoachCore

/// A calendar in a fixed time zone, so tests don't depend on the machine's settings.
let testCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/New_York")!
    return calendar
}()

/// A moment in the test calendar's time zone.
func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0, _ second: Int = 0) -> Date {
    testCalendar.date(from: DateComponents(
        year: year, month: month, day: day, hour: hour, minute: minute, second: second
    ))!
}

extension Date {
    func adding(minutes: Double) -> Date { addingTimeInterval(minutes * 60) }
}

/// A database in memory with one area, "Work", budget 8 pomodoros.
func makeFixture() throws -> (AppDatabase, PomodoroTimer, Area) {
    let database = try AppDatabase.inMemory()
    let area = try database.createArea(
        name: "Work", color: .blue, dailyBudgetMinutes: 8 * 25, now: date(2026, 1, 1, 9)
    )
    return (database, PomodoroTimer(database: database, calendar: testCalendar), area)
}
