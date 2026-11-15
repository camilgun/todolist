import Foundation
import GRDB

/// The rules of the work and break timer. Every method takes the current time,
/// and all times come from stored start times, never from counting ticks: a
/// pomodoro that ended while the Mac was asleep is completed on the next `advance`.
///
/// The cycle: idle → working → awaitingNote (end-of-pomodoro form) → onBreak → breakOver → working …
/// There is no pause: stopping early makes an interrupted pomodoro.
public struct PomodoroTimer: Sendable {
    public let database: AppDatabase
    public var calendar: Calendar

    /// Pomodoros stopped before this many seconds are discarded as mistaken starts.
    public static let mistakenStartSeconds: TimeInterval = 60

    public init(database: AppDatabase, calendar: Calendar = .current) {
        self.database = database
        self.calendar = calendar
    }

    public func status() throws -> TimerStatus {
        try database.writer.read { db in try Self.status(db) }
    }

    /// Starts a pomodoro in `areaId`. Allowed when idle, after a break, or during a
    /// break (which then ends early).
    @discardableResult
    public func start(areaId: Int64, at now: Date) throws -> Pomodoro {
        try database.writer.write { db in
            var state = try Self.state(db)
            switch state.phase {
            case .idle, .onBreak, .breakOver: break
            case .working, .awaitingNote: throw DayCoachError.timerBusy
            }
            guard let area = try Area.fetchOne(db, key: areaId) else { throw DayCoachError.areaNotFound }
            guard !area.isArchived else { throw DayCoachError.areaArchived }
            let settings = try AppDatabase.settings(db)
            var pomodoro = Pomodoro(
                areaId: areaId,
                startedAt: now,
                plannedMinutes: settings.workMinutes,
                status: .running
            )
            try pomodoro.insert(db)
            state = TimerState(phase: .working, pomodoroId: pomodoro.id, lastAreaId: areaId)
            try state.save(db)
            return pomodoro
        }
    }

    /// Stops the running pomodoro early.
    public func interrupt(at now: Date) throws -> InterruptResult {
        try database.writer.write { db in
            let state = try Self.state(db)
            guard state.phase == .working,
                  let id = state.pomodoroId,
                  var pomodoro = try Pomodoro.fetchOne(db, key: id)
            else { throw DayCoachError.notWorking }

            if now >= pomodoro.plannedEnd {
                return .completed(try Self.complete(db, &pomodoro))
            }
            if now.timeIntervalSince(pomodoro.startedAt) < Self.mistakenStartSeconds {
                try Pomodoro.deleteOne(db, key: id)
                try TimerState(phase: .idle, lastAreaId: state.lastAreaId).save(db)
                return .discarded
            }
            pomodoro.endedAt = now
            pomodoro.status = .interrupted
            try pomodoro.update(db)
            try TimerState(phase: .idle, lastAreaId: state.lastAreaId).save(db)
            return .interrupted(pomodoro)
        }
    }

    /// Moves the timer forward to `now`: completes a pomodoro or ends a break whose time is up.
    public func advance(to now: Date) throws -> [TimerEvent] {
        try database.writer.write { db in
            let state = try Self.state(db)
            switch state.phase {
            case .working:
                guard let id = state.pomodoroId, var pomodoro = try Pomodoro.fetchOne(db, key: id) else {
                    try TimerState(phase: .idle, lastAreaId: state.lastAreaId).save(db)
                    return []
                }
                guard now >= pomodoro.plannedEnd else { return [] }
                return [.pomodoroCompleted(try Self.complete(db, &pomodoro))]
            case .onBreak:
                guard let end = state.breakEnd, now >= end else { return [] }
                try TimerState(phase: .breakOver, lastAreaId: state.lastAreaId).save(db)
                return [.breakEnded(nextAreaId: state.lastAreaId)]
            case .idle, .awaitingNote, .breakOver:
                return []
            }
        }
    }

    /// Saves the note of the pomodoro that just ended and starts the break: closing the
    /// form starts the break, so writing the note doesn't eat into it.
    @discardableResult
    public func finishNote(_ note: String, at now: Date) throws -> (kind: BreakKind, endsAt: Date) {
        try database.writer.write { db in
            let state = try Self.state(db)
            guard state.phase == .awaitingNote,
                  let id = state.pomodoroId,
                  var pomodoro = try Pomodoro.fetchOne(db, key: id)
            else { throw DayCoachError.notAwaitingNote }
            pomodoro.note = note
            try pomodoro.update(db)

            let settings = try AppDatabase.settings(db)
            let kind = try breakKind(db, after: pomodoro, settings: settings)
            let minutes = kind == .long ? settings.longBreakMinutes : settings.shortBreakMinutes
            let newState = TimerState(
                phase: .onBreak,
                lastAreaId: state.lastAreaId,
                breakKind: kind,
                breakStartedAt: now,
                breakMinutes: minutes
            )
            try newState.save(db)
            return (kind, newState.breakEnd!)
        }
    }

    /// Ends the running break early, without starting a pomodoro.
    public func endBreak() throws {
        try database.writer.write { db in
            let state = try Self.state(db)
            guard state.phase == .onBreak || state.phase == .breakOver else { throw DayCoachError.notOnBreak }
            try TimerState(phase: .idle, lastAreaId: state.lastAreaId).save(db)
        }
    }

    // MARK: - Helpers

    private static func state(_ db: Database) throws -> TimerState {
        try TimerState.fetchOne(db, key: 1) ?? TimerState()
    }

    private static func status(_ db: Database) throws -> TimerStatus {
        let state = try state(db)
        switch state.phase {
        case .idle:
            return .idle(nextAreaId: state.lastAreaId)
        case .working, .awaitingNote:
            guard let id = state.pomodoroId, let pomodoro = try Pomodoro.fetchOne(db, key: id) else {
                return .idle(nextAreaId: state.lastAreaId)
            }
            return state.phase == .working ? .working(pomodoro) : .awaitingNote(pomodoro)
        case .onBreak:
            guard let kind = state.breakKind, let end = state.breakEnd else {
                return .idle(nextAreaId: state.lastAreaId)
            }
            return .onBreak(kind: kind, endsAt: end, nextAreaId: state.lastAreaId)
        case .breakOver:
            return .breakOver(nextAreaId: state.lastAreaId)
        }
    }

    /// Marks a running pomodoro as completed at its planned end and opens the note form.
    private static func complete(_ db: Database, _ pomodoro: inout Pomodoro) throws -> Pomodoro {
        pomodoro.endedAt = pomodoro.plannedEnd
        pomodoro.status = .completed
        try pomodoro.update(db)
        try TimerState(phase: .awaitingNote, pomodoroId: pomodoro.id, lastAreaId: pomodoro.areaId).save(db)
        return pomodoro
    }

    /// A long break after every `longBreakEvery` pomodoros completed with the timer in the same day.
    private func breakKind(_ db: Database, after pomodoro: Pomodoro, settings: AppSettings) throws -> BreakKind {
        let day = DayClock(dayStartMinutes: settings.dayStartMinutes, calendar: calendar)
            .day(containing: pomodoro.startedAt)
        let completedSoFar = try Pomodoro
            .filter(Pomodoro.Columns.status == Pomodoro.Status.completed)
            .filter(Pomodoro.Columns.isManual == false)
            .filter(Pomodoro.Columns.startedAt >= day.start && Pomodoro.Columns.startedAt <= pomodoro.startedAt)
            .fetchCount(db)
        return completedSoFar % settings.longBreakEvery == 0 ? .long : .short
    }
}
