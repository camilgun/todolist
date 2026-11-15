import Foundation
import GRDB

/// The colours an area can take. The app maps each one to a system colour.
public enum AreaColor: String, Codable, CaseIterable, Sendable, DatabaseValueConvertible {
    case red, orange, yellow, green, teal, blue, purple, pink
}

/// A container for one kind of work (e.g. work, personal) with a default daily budget.
public struct Area: Codable, Hashable, Identifiable, Sendable {
    public var id: Int64?
    public var name: String
    public var color: AreaColor
    /// The default budget for a day, in minutes (ADR 0003); shown in pomodoros.
    public var dailyBudgetMinutes: Int
    /// Display order among the areas.
    public var position: Int
    /// Set when the area is archived; archived areas can't start new pomodoros.
    public var archivedAt: Date?
    public var createdAt: Date

    public init(
        id: Int64? = nil,
        name: String,
        color: AreaColor,
        dailyBudgetMinutes: Int,
        position: Int = 0,
        archivedAt: Date? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.dailyBudgetMinutes = dailyBudgetMinutes
        self.position = position
        self.archivedAt = archivedAt
        self.createdAt = createdAt
    }

    public var isArchived: Bool { archivedAt != nil }
}

extension Area: FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "area"

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
