import Foundation
import GRDB

/// A block of focused work. It always belongs to an area and keeps its real start and end times.
public struct Pomodoro: Codable, Hashable, Identifiable, Sendable {
    public enum Status: String, Codable, Sendable, DatabaseValueConvertible {
        /// The timer is running; `endedAt` is nil.
        case running
        /// It reached its planned length (or was added by hand).
        case completed
        /// It was stopped before its planned length; the minutes worked still count.
        case interrupted
    }

    public var id: Int64?
    public var areaId: Int64
    public var startedAt: Date
    public var endedAt: Date?
    /// The work length configured when the pomodoro started, in minutes.
    public var plannedMinutes: Int
    public var status: Status
    /// True when the pomodoro was added by hand after the fact.
    public var isManual: Bool
    public var note: String

    public init(
        id: Int64? = nil,
        areaId: Int64,
        startedAt: Date,
        endedAt: Date? = nil,
        plannedMinutes: Int,
        status: Status,
        isManual: Bool = false,
        note: String = ""
    ) {
        self.id = id
        self.areaId = areaId
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.plannedMinutes = plannedMinutes
        self.status = status
        self.isManual = isManual
        self.note = note
    }

    /// When a running pomodoro reaches its planned length.
    public var plannedEnd: Date {
        startedAt.addingTimeInterval(TimeInterval(plannedMinutes * 60))
    }

    /// The minutes actually worked, from the real start and end times; 0 while running.
    public var workedMinutes: Double {
        guard let endedAt else { return 0 }
        return max(0, endedAt.timeIntervalSince(startedAt)) / 60
    }
}

extension Pomodoro: FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "pomodoro"

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    public enum Columns {
        public static let areaId = Column("areaId")
        public static let startedAt = Column("startedAt")
        public static let status = Column("status")
        public static let isManual = Column("isManual")
    }
}
