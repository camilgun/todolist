import Foundation
import Testing
@testable import DayCoachCore

@Suite struct DayClockTests {
    let clock = DayClock(dayStartMinutes: 4 * 60, calendar: testCalendar)

    @Test func theDayEndsAtFourInTheMorningNotAtMidnight() {
        let day = clock.day(containing: date(2026, 3, 2, 23, 30))
        #expect(day.start == date(2026, 3, 2, 4))
        #expect(day.end == date(2026, 3, 3, 4))
    }

    @Test func workAfterMidnightCountsForThePreviousDay() {
        let day = clock.day(containing: date(2026, 3, 3, 1, 15))
        #expect(day.start == date(2026, 3, 2, 4))
    }

    @Test func theNewDayStartsExactlyAtTheConfiguredTime() {
        #expect(clock.day(containing: date(2026, 3, 3, 4)).start == date(2026, 3, 3, 4))
        #expect(clock.day(containing: date(2026, 3, 3, 3, 59, 59)).start == date(2026, 3, 2, 4))
    }

    @Test func theDayStartIsConfigurable() {
        let clock = DayClock(dayStartMinutes: 5 * 60 + 30, calendar: testCalendar)
        #expect(clock.day(containing: date(2026, 3, 3, 5)).start == date(2026, 3, 2, 5, 30))
    }

    @Test func aDayAcrossADaylightSavingChangeStillEndsAtFour() {
        // Clocks in New York move forward on 8 March 2026 at 2:00.
        let day = clock.day(containing: date(2026, 3, 7, 12))
        #expect(day.end == date(2026, 3, 8, 4))
        #expect(day.duration == 23 * 3600)
    }

    @Test func theDaysBeforeAndAfter() {
        let day = clock.day(containing: date(2026, 3, 2, 12))
        #expect(clock.day(day, offsetBy: -1).start == date(2026, 3, 1, 4))
        #expect(clock.day(day, offsetBy: 1).start == date(2026, 3, 3, 4))
    }
}

@Suite struct PomodoroCountTests {
    @Test(arguments: [
        (200.0, "8"),
        (190.0, "7.6"),
        (225.0, "9"),
        (0.0, "0"),
        (12.5, "0.5"),
        (199.0, "8"),   // 7.96 rounds to 8.0, shown whole
    ])
    func wholeNumbersAreShownWholeAndFractionsWithOneDecimal(minutes: Double, expected: String) {
        #expect(PomodoroCount.text(minutes: minutes, workMinutes: 25) == expected)
    }

    @Test func counters() {
        #expect(PomodoroCount.counter(name: "Work", workedMinutes: 75, budgetMinutes: 200, workMinutes: 25) == "Work 3 / 8")
        #expect(PomodoroCount.counter(name: "Work", workedMinutes: 225, budgetMinutes: 200, workMinutes: 25) == "Work 9 / 8")
        #expect(PomodoroCount.counter(name: "Work", workedMinutes: 190, budgetMinutes: 200, workMinutes: 25) == "Work 7.6 / 8")
    }

    @Test func theSameMinutesReadDifferentlyWithAnotherWorkLength() {
        #expect(PomodoroCount.text(minutes: 500, workMinutes: 25) == "20")
        #expect(PomodoroCount.text(minutes: 500, workMinutes: 50) == "10")
    }

    @Test func remainingTime() {
        #expect(ClockText.remaining(25 * 60) == "25:00")
        #expect(ClockText.remaining(245.2) == "4:06")
        #expect(ClockText.remaining(0) == "0:00")
        #expect(ClockText.remaining(-3) == "0:00")
    }
}

@Suite struct AreaTests {
    @Test func areasKeepTheOrderTheyWereCreatedIn() throws {
        let database = try AppDatabase.inMemory()
        try database.createArea(name: "Work", color: .blue, dailyBudgetMinutes: 200)
        try database.createArea(name: "Personal", color: .green, dailyBudgetMinutes: 100)
        #expect(try database.areas().map(\.name) == ["Work", "Personal"])
    }

    @Test func anAreaNeedsAName() throws {
        let database = try AppDatabase.inMemory()
        #expect(throws: DayCoachError.emptyAreaName) {
            try database.createArea(name: "  ", color: .blue, dailyBudgetMinutes: 200)
        }
    }

    @Test func areasCanBeEditedArchivedAndRestored() throws {
        let database = try AppDatabase.inMemory()
        var area = try database.createArea(name: "Work", color: .blue, dailyBudgetMinutes: 200)
        area.name = "Client work"
        area.color = .orange
        area.dailyBudgetMinutes = 150
        try database.updateArea(area)
        try database.setArchived(areaId: area.id!, true, now: date(2026, 3, 2, 9))

        var stored = try #require(try database.areas().first)
        #expect(stored.name == "Client work")
        #expect(stored.color == .orange)
        #expect(stored.dailyBudgetMinutes == 150)
        #expect(stored.isArchived)

        try database.setArchived(areaId: area.id!, false)
        stored = try #require(try database.areas().first)
        #expect(!stored.isArchived)
    }

    @Test func editingAnAreaLeavesItsArchivingAlone() throws {
        let database = try AppDatabase.inMemory()
        var copy = try database.createArea(name: "New area", color: .blue, dailyBudgetMinutes: 200)
        try database.setArchived(areaId: copy.id!, true, now: date(2026, 3, 2, 9))

        // A screen still holding the copy from before archiving renames the area.
        copy.name = "Work"
        try database.updateArea(copy)

        let stored = try #require(try database.areas().first)
        #expect(stored.name == "Work")
        #expect(stored.isArchived)
    }
}

@Suite struct ManualFixTests {
    @Test func aForgottenPomodoroCanBeAddedByHand() throws {
        let (database, _, area) = try makeFixture()
        let start = date(2026, 3, 2, 14)

        let added = try database.addManualPomodoro(
            areaId: area.id!, startedAt: start, minutes: 25, note: "Call with the supplier", now: date(2026, 3, 2, 16)
        )

        #expect(added.isManual)
        #expect(added.status == .completed)
        #expect(added.endedAt == start.adding(minutes: 25))
        let day = DayClock(dayStartMinutes: 240, calendar: testCalendar).day(containing: start)
        #expect(try database.pomodoros(in: day) == [added])
        #expect(try database.workedMinutesByArea(in: day) == [area.id!: 25])
    }

    @Test func aPomodoroAddedByHandCantStartInTheFuture() throws {
        let (database, _, area) = try makeFixture()
        #expect(throws: DayCoachError.startInFuture) {
            try database.addManualPomodoro(
                areaId: area.id!, startedAt: date(2026, 3, 2, 17), minutes: 25, note: "", now: date(2026, 3, 2, 16)
            )
        }
    }

    @Test func aPomodoroInTheWrongAreaCanBeMoved() throws {
        let (database, timer, work) = try makeFixture()
        let personal = try database.createArea(name: "Personal", color: .green, dailyBudgetMinutes: 100)
        let start = date(2026, 3, 2, 9)
        try timer.start(areaId: work.id!, at: start)
        _ = try timer.advance(to: start.adding(minutes: 25))
        try timer.finishNote("Gym booking", at: start.adding(minutes: 25))
        let pomodoro = try #require(try database.pomodoros(in: DateInterval(start: start, duration: 3600)).first)

        try database.updatePomodoro(id: pomodoro.id!, areaId: personal.id!, note: "Gym booked")

        let day = DateInterval(start: start, duration: 3600)
        #expect(try database.workedMinutesByArea(in: day) == [personal.id!: 25])
        #expect(try database.pomodoros(in: day).first?.note == "Gym booked")
    }

    @Test func theRunningPomodoroCantBeEditedOrDeleted() throws {
        let (database, timer, area) = try makeFixture()
        let pomodoro = try timer.start(areaId: area.id!, at: date(2026, 3, 2, 9))
        #expect(throws: DayCoachError.pomodoroRunning) { try database.deletePomodoro(id: pomodoro.id!) }
        #expect(throws: DayCoachError.pomodoroRunning) {
            try database.updatePomodoro(id: pomodoro.id!, areaId: area.id!, note: "")
        }
    }

    @Test func theRunningPomodoroIsNotCountedUntilItEnds() throws {
        let (database, timer, area) = try makeFixture()
        let start = date(2026, 3, 2, 9)
        try timer.start(areaId: area.id!, at: start)
        #expect(try database.workedMinutesByArea(in: DateInterval(start: start, duration: 3600)).isEmpty)
    }

    @Test func pomodorosCountForTheDayTheyStarted() throws {
        let (database, timer, area) = try makeFixture()
        let clock = DayClock(dayStartMinutes: 240, calendar: testCalendar)
        let lateStart = date(2026, 3, 2, 23, 50)
        try timer.start(areaId: area.id!, at: lateStart)
        _ = try timer.advance(to: lateStart.adding(minutes: 25))

        #expect(try database.pomodoros(in: clock.day(containing: date(2026, 3, 2, 12))).count == 1)
        #expect(try database.pomodoros(in: clock.day(containing: date(2026, 3, 3, 12))).isEmpty)
    }
}

@Suite struct SettingsTests {
    @Test func defaults() throws {
        let settings = try AppDatabase.inMemory().settings()
        #expect(settings.workMinutes == 25)
        #expect(settings.shortBreakMinutes == 5)
        #expect(settings.longBreakMinutes == 15)
        #expect(settings.longBreakEvery == 4)
        #expect(settings.dayStartMinutes == 240)
    }

    @Test func savedSettingsAreKeptInsideTheirRanges() throws {
        let database = try AppDatabase.inMemory()
        try database.saveSettings(AppSettings(workMinutes: 0, longBreakEvery: 0, dayStartMinutes: 6 * 60))
        let settings = try database.settings()
        #expect(settings.workMinutes == 1)
        #expect(settings.longBreakEvery == 1)
        #expect(settings.dayStartMinutes == 360)
    }
}
