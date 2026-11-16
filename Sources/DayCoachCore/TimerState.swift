import Foundation
import GRDB

public enum BreakKind: String, Codable, Hashable, Sendable, DatabaseValueConvertible {
    case short, long
}

/// Where the timer is, stored as the single row of the `timerState` table so that
/// a running pomodoro or break survives a restart of the app.
struct TimerState: Codable, Sendable {
    enum Phase: String, Codable, Sendable, DatabaseValueConvertible {
        case idle
        case working
        /// The pomodoro ended; the end-of-pomodoro form is open and the break hasn't started.
        case awaitingNote
        case onBreak
        /// The break ended; the next pomodoro is proposed but never started automatically.
        case breakOver
    }

    var id: Int = 1
    var phase: Phase = .idle
    /// The pomodoro running or waiting for its note.
    var pomodoroId: Int64?
    /// The area of the last pomodoro, proposed for the next one.
    var lastAreaId: Int64?
    var breakKind: BreakKind?
    var breakStartedAt: Date?
    var breakMinutes: Int?

    var breakEnd: Date? {
        guard let breakStartedAt, let breakMinutes else { return nil }
        return breakStartedAt.addingTimeInterval(TimeInterval(breakMinutes * 60))
    }
}

extension TimerState: FetchableRecord, PersistableRecord {
    static let databaseTableName = "timerState"
}

/// What the timer is doing, as the app shows it.
public enum TimerStatus: Hashable, Sendable {
    case idle(nextAreaId: Int64?)
    case working(Pomodoro)
    case awaitingNote(Pomodoro)
    case onBreak(kind: BreakKind, endsAt: Date, nextAreaId: Int64?)
    case breakOver(nextAreaId: Int64?)

    /// The area proposed for the next pomodoro, if any.
    public var nextAreaId: Int64? {
        switch self {
        case .idle(let id), .breakOver(let id), .onBreak(_, _, let id): id
        case .working(let p), .awaitingNote(let p): p.areaId
        }
    }
}

/// Something that happened as time passed.
public enum TimerEvent: Hashable, Sendable {
    /// A pomodoro reached its planned length; the end-of-pomodoro form should open.
    case pomodoroCompleted(Pomodoro)
    /// A break reached its end; the next pomodoro should be proposed.
    case breakEnded(nextAreaId: Int64?)
}

/// The outcome of stopping a pomodoro early.
public enum InterruptResult: Hashable, Sendable {
    /// Stopped within the first minute: treated as a mistaken start and deleted.
    case discarded
    /// Kept as interrupted; the minutes worked count.
    case interrupted(Pomodoro)
    /// It had already reached its planned length, so it counts as completed.
    case completed(Pomodoro)
}

public enum DayCoachError: Error, Equatable, LocalizedError {
    case timerBusy
    case notWorking
    case notAwaitingNote
    case notOnBreak
    case areaNotFound
    case areaArchived
    case pomodoroNotFound
    case pomodoroRunning
    case emptyAreaName
    case invalidMinutes
    case startInFuture

    public var errorDescription: String? {
        switch self {
        case .timerBusy: "A pomodoro is already running or waiting for its note."
        case .notWorking: "No pomodoro is running."
        case .notAwaitingNote: "No pomodoro is waiting for its note."
        case .notOnBreak: "No break is running."
        case .areaNotFound: "The area no longer exists."
        case .areaArchived: "The area is archived."
        case .pomodoroNotFound: "The pomodoro no longer exists."
        case .pomodoroRunning: "A running pomodoro can't be changed this way."
        case .emptyAreaName: "An area needs a name."
        case .invalidMinutes: "The length must be between 1 and 600 minutes."
        case .startInFuture: "A pomodoro added by hand can't start in the future."
        }
    }
}
