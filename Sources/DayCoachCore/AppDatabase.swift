import Foundation
import GRDB

/// The app's SQLite database (ADR 0002) and the operations on areas, pomodoros and settings.
/// The timer's rules live in `PomodoroTimer`.
public final class AppDatabase: Sendable {
    public let writer: any DatabaseWriter

    public init(_ writer: any DatabaseWriter) throws {
        self.writer = writer
        try Self.migrator.migrate(writer)
    }

    /// A fresh database in memory, for tests and previews.
    public static func inMemory() throws -> AppDatabase {
        try AppDatabase(DatabaseQueue())
    }

    /// The database file at `url`, created with its folder if needed.
    public static func onDisk(at url: URL) throws -> AppDatabase {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        return try AppDatabase(DatabasePool(path: url.path))
    }

    /// `~/Library/Application Support/DayCoach/daycoach.sqlite`
    public static var defaultURL: URL {
        URL.applicationSupportDirectory
            .appending(path: "DayCoach", directoryHint: .isDirectory)
            .appending(path: "daycoach.sqlite")
    }

    private static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try db.create(table: "area") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("color", .text).notNull()
                t.column("dailyBudgetMinutes", .integer).notNull().check { $0 >= 0 }
                t.column("position", .integer).notNull()
                t.column("archivedAt", .datetime)
                t.column("createdAt", .datetime).notNull()
            }
            try db.create(table: "pomodoro") { t in
                t.autoIncrementedPrimaryKey("id")
                t.belongsTo("area", onDelete: .restrict).notNull()
                t.column("startedAt", .datetime).notNull().indexed()
                t.column("endedAt", .datetime)
                t.column("plannedMinutes", .integer).notNull()
                t.column("status", .text).notNull()
                    .check(sql: "status IN ('running', 'completed', 'interrupted')")
                t.column("isManual", .boolean).notNull().defaults(to: false)
                t.column("note", .text).notNull().defaults(to: "")
            }
            try db.create(table: "settings") { t in
                t.primaryKey("id", .integer).check { $0 == 1 }
                t.column("workMinutes", .integer).notNull()
                t.column("shortBreakMinutes", .integer).notNull()
                t.column("longBreakMinutes", .integer).notNull()
                t.column("longBreakEvery", .integer).notNull()
                t.column("dayStartMinutes", .integer).notNull()
            }
            try db.create(table: "timerState") { t in
                t.primaryKey("id", .integer).check { $0 == 1 }
                t.column("phase", .text).notNull()
                t.belongsTo("pomodoro", onDelete: .setNull)
                t.belongsTo("lastArea", inTable: "area", onDelete: .setNull)
                t.column("breakKind", .text)
                t.column("breakStartedAt", .datetime)
                t.column("breakMinutes", .integer)
            }
        }
        return migrator
    }
}

// MARK: - Settings

extension AppDatabase {
    public func settings() throws -> AppSettings {
        try writer.read { try Self.settings($0) }
    }

    static func settings(_ db: Database) throws -> AppSettings {
        try AppSettings.fetchOne(db, key: 1) ?? AppSettings()
    }

    public func saveSettings(_ settings: AppSettings) throws {
        try writer.write { try settings.clamped.save($0) }
    }
}

// MARK: - Areas

extension AppDatabase {
    /// All areas, archived ones included, in display order.
    public func areas() throws -> [Area] {
        try writer.read { db in
            try Area.order(Column("position"), Column("id")).fetchAll(db)
        }
    }

    @discardableResult
    public func createArea(name: String, color: AreaColor, dailyBudgetMinutes: Int, now: Date = Date()) throws -> Area {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw DayCoachError.emptyAreaName }
        return try writer.write { db in
            let maxPosition = try Int.fetchOne(db, sql: "SELECT MAX(position) FROM area") ?? -1
            var area = Area(
                name: name,
                color: color,
                dailyBudgetMinutes: max(0, dailyBudgetMinutes),
                position: maxPosition + 1,
                createdAt: now
            )
            try area.insert(db)
            return area
        }
    }

    /// Saves the name, colour and budget of an existing area.
    public func updateArea(_ area: Area) throws {
        var area = area
        area.name = area.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !area.name.isEmpty else { throw DayCoachError.emptyAreaName }
        area.dailyBudgetMinutes = max(0, area.dailyBudgetMinutes)
        try writer.write { db in
            guard try Area.exists(db, key: area.id) else { throw DayCoachError.areaNotFound }
            // Only what the editor changes: archiving goes through `setArchived`, so a
            // screen holding an older copy can't undo it.
            try area.update(db, columns: ["name", "color", "dailyBudgetMinutes"])
        }
    }

    public func setArchived(areaId: Int64, _ archived: Bool, now: Date = Date()) throws {
        try writer.write { db in
            guard var area = try Area.fetchOne(db, key: areaId) else { throw DayCoachError.areaNotFound }
            area.archivedAt = archived ? (area.archivedAt ?? now) : nil
            try area.update(db)
        }
    }
}

// MARK: - Pomodoros

extension AppDatabase {
    /// The finished pomodoros (completed or interrupted) that started within `interval`, oldest first.
    public func pomodoros(in interval: DateInterval) throws -> [Pomodoro] {
        try writer.read { try Self.finishedPomodoros($0, in: interval) }
    }

    static func finishedPomodoros(_ db: Database, in interval: DateInterval) throws -> [Pomodoro] {
        try Pomodoro
            .filter(Pomodoro.Columns.startedAt >= interval.start && Pomodoro.Columns.startedAt < interval.end)
            .filter(Pomodoro.Columns.status != Pomodoro.Status.running)
            .order(Pomodoro.Columns.startedAt)
            .fetchAll(db)
    }

    /// Minutes worked per area on the pomodoros that started within `interval`.
    public func workedMinutesByArea(in interval: DateInterval) throws -> [Int64: Double] {
        try pomodoros(in: interval).reduce(into: [:]) { totals, pomodoro in
            totals[pomodoro.areaId, default: 0] += pomodoro.workedMinutes
        }
    }

    /// Records a forgotten pomodoro, marked as added by hand.
    @discardableResult
    public func addManualPomodoro(
        areaId: Int64,
        startedAt: Date,
        minutes: Int,
        note: String,
        now: Date = Date()
    ) throws -> Pomodoro {
        guard (1...600).contains(minutes) else { throw DayCoachError.invalidMinutes }
        guard startedAt <= now else { throw DayCoachError.startInFuture }
        return try writer.write { db in
            guard try Area.exists(db, key: areaId) else { throw DayCoachError.areaNotFound }
            var pomodoro = Pomodoro(
                areaId: areaId,
                startedAt: startedAt,
                endedAt: startedAt.addingTimeInterval(TimeInterval(minutes * 60)),
                plannedMinutes: minutes,
                status: .completed,
                isManual: true,
                note: note
            )
            try pomodoro.insert(db)
            return pomodoro
        }
    }

    /// Corrects the area or the note of a finished pomodoro.
    public func updatePomodoro(id: Int64, areaId: Int64, note: String) throws {
        try writer.write { db in
            guard var pomodoro = try Pomodoro.fetchOne(db, key: id) else { throw DayCoachError.pomodoroNotFound }
            guard pomodoro.status != .running else { throw DayCoachError.pomodoroRunning }
            guard try Area.exists(db, key: areaId) else { throw DayCoachError.areaNotFound }
            pomodoro.areaId = areaId
            pomodoro.note = note
            try pomodoro.update(db)
        }
    }

    /// Deletes a finished pomodoro, for example one added by hand by mistake.
    public func deletePomodoro(id: Int64) throws {
        try writer.write { db in
            guard let pomodoro = try Pomodoro.fetchOne(db, key: id) else { throw DayCoachError.pomodoroNotFound }
            guard pomodoro.status != .running else { throw DayCoachError.pomodoroRunning }
            if var state = try TimerState.fetchOne(db, key: 1), state.pomodoroId == id {
                // A pomodoro waiting for its note: drop the form and go back to idle.
                state = TimerState(phase: .idle, lastAreaId: state.lastAreaId)
                try state.save(db)
            }
            try Pomodoro.deleteOne(db, key: id)
        }
    }
}
