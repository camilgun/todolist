import Foundation
import Testing
@testable import DayCoachCore

@Suite struct PomodoroTimerTests {
    @Test func aPomodoroRunsUntilItsPlannedEndThenWaitsForItsNote() throws {
        let (_, timer, area) = try makeFixture()
        let start = date(2026, 3, 2, 9)
        let pomodoro = try timer.start(areaId: area.id!, at: start)

        #expect(try timer.advance(to: start.adding(minutes: 24.9)) == [])
        #expect(try timer.status() == .working(pomodoro))

        let events = try timer.advance(to: start.adding(minutes: 25))
        guard case .pomodoroCompleted(let done) = events.first else {
            Issue.record("expected a completed pomodoro, got \(events)")
            return
        }
        #expect(done.status == .completed)
        #expect(done.endedAt == start.adding(minutes: 25))
        #expect(try timer.status() == .awaitingNote(done))
    }

    @Test func aPomodoroThatEndedWhileAsleepCountsAtItsPlannedEnd() throws {
        let (database, timer, area) = try makeFixture()
        let start = date(2026, 3, 2, 9)
        try timer.start(areaId: area.id!, at: start)

        // The Mac wakes up two hours later.
        let events = try timer.advance(to: start.adding(minutes: 120))

        #expect(events.count == 1)
        let recorded = try database.pomodoros(in: DateInterval(start: start, duration: 3600))
        #expect(recorded.map(\.workedMinutes) == [25])
    }

    @Test func theBreakStartsWhenTheNoteIsSavedNotWhenThePomodoroEnds() throws {
        let (database, timer, area) = try makeFixture()
        let start = date(2026, 3, 2, 9)
        try timer.start(areaId: area.id!, at: start)
        _ = try timer.advance(to: start.adding(minutes: 25))

        // Writing the note takes three minutes.
        let noteSaved = start.adding(minutes: 28)
        let brk = try timer.finishNote("Outline drafted", at: noteSaved)

        #expect(brk.kind == .short)
        #expect(brk.endsAt == noteSaved.adding(minutes: 5))
        #expect(try database.pomodoros(in: DateInterval(start: start, duration: 3600)).first?.note == "Outline drafted")
    }

    @Test func theEndOfTheBreakProposesTheNextPomodoroWithoutStartingIt() throws {
        let (_, timer, area) = try makeFixture()
        let start = date(2026, 3, 2, 9)
        try timer.start(areaId: area.id!, at: start)
        _ = try timer.advance(to: start.adding(minutes: 25))
        let brk = try timer.finishNote("", at: start.adding(minutes: 25))

        #expect(try timer.advance(to: brk.endsAt.addingTimeInterval(-1)) == [])
        #expect(try timer.advance(to: brk.endsAt) == [.breakEnded(nextAreaId: area.id)])
        #expect(try timer.status() == .breakOver(nextAreaId: area.id))
        #expect(try timer.advance(to: brk.endsAt.adding(minutes: 60)) == [])
    }

    @Test func everyFourthPomodoroOfTheDayIsFollowedByALongBreak() throws {
        let (_, timer, area) = try makeFixture()
        var now = date(2026, 3, 2, 9)
        var kinds: [BreakKind] = []
        for _ in 1...5 {
            try timer.start(areaId: area.id!, at: now)
            now = now.adding(minutes: 25)
            _ = try timer.advance(to: now)
            let brk = try timer.finishNote("", at: now)
            kinds.append(brk.kind)
            now = brk.endsAt
            _ = try timer.advance(to: now)
        }
        #expect(kinds == [.short, .short, .short, .long, .short])
    }

    @Test func interruptedPomodorosDontCountTowardsTheLongBreak() throws {
        let (_, timer, area) = try makeFixture()
        var now = date(2026, 3, 2, 9)
        try timer.start(areaId: area.id!, at: now)
        now = now.adding(minutes: 10)
        _ = try timer.interrupt(at: now)
        for _ in 1...3 {
            try timer.start(areaId: area.id!, at: now)
            now = now.adding(minutes: 25)
            _ = try timer.advance(to: now)
            #expect(try timer.finishNote("", at: now).kind == .short)
            try timer.endBreak()
        }
    }

    @Test func stoppingEarlyKeepsTheMinutesWorkedAsAnInterruptedPomodoro() throws {
        let (database, timer, area) = try makeFixture()
        let start = date(2026, 3, 2, 9)
        try timer.start(areaId: area.id!, at: start)

        let result = try timer.interrupt(at: start.adding(minutes: 19))

        guard case .interrupted(let pomodoro) = result else {
            Issue.record("expected an interrupted pomodoro, got \(result)")
            return
        }
        #expect(pomodoro.workedMinutes == 19)
        #expect(try timer.status() == .idle(nextAreaId: area.id))
        let day = DateInterval(start: start, duration: 3600)
        #expect(try database.workedMinutesByArea(in: day) == [area.id!: 19])
    }

    @Test func stoppingWithinTheFirstMinuteDiscardsTheMistakenStart() throws {
        let (database, timer, area) = try makeFixture()
        let start = date(2026, 3, 2, 9)
        try timer.start(areaId: area.id!, at: start)

        #expect(try timer.interrupt(at: start.addingTimeInterval(59)) == .discarded)
        #expect(try database.pomodoros(in: DateInterval(start: start, duration: 3600)).isEmpty)
        #expect(try timer.status() == .idle(nextAreaId: area.id))
    }

    @Test func stoppingAfterThePlannedEndCountsAsCompleted() throws {
        let (_, timer, area) = try makeFixture()
        let start = date(2026, 3, 2, 9)
        try timer.start(areaId: area.id!, at: start)

        let result = try timer.interrupt(at: start.adding(minutes: 30))

        guard case .completed(let pomodoro) = result else {
            Issue.record("expected a completed pomodoro, got \(result)")
            return
        }
        #expect(pomodoro.workedMinutes == 25)
        #expect(try timer.status() == .awaitingNote(pomodoro))
    }

    @Test func startingDuringABreakEndsTheBreak() throws {
        let (_, timer, area) = try makeFixture()
        let start = date(2026, 3, 2, 9)
        try timer.start(areaId: area.id!, at: start)
        _ = try timer.advance(to: start.adding(minutes: 25))
        try timer.finishNote("", at: start.adding(minutes: 25))

        let next = try timer.start(areaId: area.id!, at: start.adding(minutes: 27))

        #expect(try timer.status() == .working(next))
    }

    @Test func aSecondPomodoroCantStartWhileOneIsRunningOrWaitingForItsNote() throws {
        let (_, timer, area) = try makeFixture()
        let start = date(2026, 3, 2, 9)
        try timer.start(areaId: area.id!, at: start)
        #expect(throws: DayCoachError.timerBusy) { try timer.start(areaId: area.id!, at: start) }

        _ = try timer.advance(to: start.adding(minutes: 25))
        #expect(throws: DayCoachError.timerBusy) { try timer.start(areaId: area.id!, at: start.adding(minutes: 26)) }
    }

    @Test func archivedAreasCantStartPomodoros() throws {
        let (database, timer, area) = try makeFixture()
        try database.setArchived(areaId: area.id!, true)
        #expect(throws: DayCoachError.areaArchived) { try timer.start(areaId: area.id!, at: date(2026, 3, 2, 9)) }
    }

    @Test func thePomodoroLengthComesFromTheSettings() throws {
        let (database, timer, area) = try makeFixture()
        try database.saveSettings(AppSettings(workMinutes: 50, shortBreakMinutes: 10))
        let start = date(2026, 3, 2, 9)
        let pomodoro = try timer.start(areaId: area.id!, at: start)

        #expect(pomodoro.plannedMinutes == 50)
        #expect(try timer.advance(to: start.adding(minutes: 49)) == [])
        _ = try timer.advance(to: start.adding(minutes: 50))
        #expect(try timer.finishNote("", at: start.adding(minutes: 50)).endsAt == start.adding(minutes: 60))
    }

    @Test func theTimerStateSurvivesReopeningTheDatabase() throws {
        let (database, timer, area) = try makeFixture()
        let start = date(2026, 3, 2, 9)
        let pomodoro = try timer.start(areaId: area.id!, at: start)

        let reopened = PomodoroTimer(database: database, calendar: testCalendar)
        #expect(try reopened.status() == .working(pomodoro))
    }
}
