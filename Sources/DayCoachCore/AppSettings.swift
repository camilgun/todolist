import Foundation
import GRDB

/// Global settings, stored as the single row of the `settings` table.
public struct AppSettings: Codable, Hashable, Sendable {
    var id: Int = 1
    public var workMinutes: Int
    public var shortBreakMinutes: Int
    public var longBreakMinutes: Int
    /// A long break comes after every this many completed pomodoros in a day.
    public var longBreakEvery: Int
    /// When the day ends (and the next begins), in minutes after midnight. 240 is 4:00.
    public var dayStartMinutes: Int

    public init(
        workMinutes: Int = 25,
        shortBreakMinutes: Int = 5,
        longBreakMinutes: Int = 15,
        longBreakEvery: Int = 4,
        dayStartMinutes: Int = 4 * 60
    ) {
        self.workMinutes = workMinutes
        self.shortBreakMinutes = shortBreakMinutes
        self.longBreakMinutes = longBreakMinutes
        self.longBreakEvery = longBreakEvery
        self.dayStartMinutes = dayStartMinutes
    }

    public static let workMinutesRange = 1...180
    public static let breakMinutesRange = 1...120
    public static let longBreakEveryRange = 1...20
    public static let dayStartMinutesRange = 0...(24 * 60 - 1)

    /// The same settings with every value brought inside its allowed range.
    public var clamped: AppSettings {
        var s = self
        s.workMinutes = s.workMinutes.clamped(to: Self.workMinutesRange)
        s.shortBreakMinutes = s.shortBreakMinutes.clamped(to: Self.breakMinutesRange)
        s.longBreakMinutes = s.longBreakMinutes.clamped(to: Self.breakMinutesRange)
        s.longBreakEvery = s.longBreakEvery.clamped(to: Self.longBreakEveryRange)
        s.dayStartMinutes = s.dayStartMinutes.clamped(to: Self.dayStartMinutesRange)
        return s
    }
}

extension AppSettings: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "settings"
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
