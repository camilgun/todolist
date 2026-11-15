import AppKit
import DayCoachCore
import Observation

/// The state the views show, and the actions they trigger. Every change goes through
/// the database and is then reloaded, so the views always show what is stored.
@MainActor @Observable
final class AppModel {
    let database: AppDatabase
    private let timer: PomodoroTimer

    private(set) var settings = AppSettings()
    /// All areas, archived ones included, in display order.
    private(set) var areas: [Area] = []
    private(set) var status: TimerStatus = .idle(nextAreaId: nil)
    /// The current time, refreshed every second while the app runs.
    private(set) var now = Date()
    private(set) var today: DateInterval
    /// Minutes worked today per area id.
    private(set) var todayWorked: [Int64: Double] = [:]
    /// The day shown in the history list.
    private(set) var shownDay: DateInterval
    private(set) var shownDayPomodoros: [Pomodoro] = []
    /// The area the next pomodoro will start in.
    var selectedAreaId: Int64?
    var errorMessage: String?

    /// Called when the end-of-pomodoro form needs the user's attention.
    @ObservationIgnored var onAttentionNeeded: () -> Void = {}
    /// Called after every refresh, to update the menu bar item.
    @ObservationIgnored var onRefresh: () -> Void = {}
    @ObservationIgnored var showSettings: () -> Void = {}

    @ObservationIgnored private let notifier: Notifier?
    @ObservationIgnored private var ticker: Timer?
    @ObservationIgnored private var activity: NSObjectProtocol?

    init(database: AppDatabase, notifier: Notifier?) {
        self.database = database
        self.timer = PomodoroTimer(database: database)
        self.notifier = notifier
        let day = DayClock(dayStartMinutes: AppSettings().dayStartMinutes).day(containing: Date())
        self.today = day
        self.shownDay = day
        notifier?.onStartNext = { [weak self] in self?.startNext() }
        notifier?.onOpen = { [weak self] in self?.onAttentionNeeded() }
    }

    // MARK: - Derived values

    var clock: DayClock { DayClock(dayStartMinutes: settings.dayStartMinutes) }
    var activeAreas: [Area] { areas.filter { !$0.isArchived } }
    var isShowingToday: Bool { shownDay == today }

    func area(_ id: Int64?) -> Area? {
        guard let id else { return nil }
        return areas.first { $0.id == id }
    }

    /// Areas shown in the today counters: active ones, plus archived ones worked on today.
    var counterAreas: [Area] {
        areas.filter { !$0.isArchived || (todayWorked[$0.id ?? -1] ?? 0) > 0 }
    }

    // MARK: - Lifecycle

    func start() {
        notifier?.requestAuthorization()
        reload()
        tick()
        let ticker = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(ticker, forMode: .common)
        self.ticker = ticker
    }

    /// Moves time forward: ends a pomodoro or a break whose time is up, and rolls over the day.
    func tick() {
        now = Date()
        let due: Bool = switch status {
        case .working(let pomodoro): now >= pomodoro.plannedEnd
        case .onBreak(_, let endsAt, _): now >= endsAt
        default: false
        }
        if due {
            perform {
                let events = try timer.advance(to: now)
                if events.contains(where: { if case .pomodoroCompleted = $0 { true } else { false } }) {
                    onAttentionNeeded()
                }
            }
        } else if !today.contains(now) {
            reload()
        } else {
            onRefresh()
        }
    }

    func reload() {
        do {
            settings = try database.settings()
            areas = try database.areas()
            status = try timer.status()
            let newToday = clock.day(containing: now)
            if shownDay == today || shownDay.start > newToday.start {
                shownDay = newToday
            } else {
                shownDay = clock.day(containing: shownDay.start)
            }
            today = newToday
            todayWorked = try database.workedMinutesByArea(in: today)
            shownDayPomodoros = try database.pomodoros(in: shownDay)
        } catch {
            errorMessage = error.localizedDescription
        }
        if area(selectedAreaId)?.isArchived ?? true {
            let proposed = area(status.nextAreaId)
            selectedAreaId = (proposed?.isArchived == false ? proposed?.id : nil) ?? activeAreas.first?.id
        }
        updateActivity()
        onRefresh()
    }

    /// Runs a change, shows its error if it fails, then reloads.
    private func perform(_ change: () throws -> Void) {
        do {
            try change()
        } catch {
            errorMessage = error.localizedDescription
        }
        reload()
    }

    /// Keeps macOS from slowing the app's timer down (App Nap) while a pomodoro or break runs.
    private func updateActivity() {
        let running = switch status {
        case .working, .onBreak: true
        default: false
        }
        if running, activity == nil {
            activity = ProcessInfo.processInfo.beginActivity(
                options: .userInitiatedAllowingIdleSystemSleep,
                reason: "A pomodoro or break is running"
            )
        } else if !running, let activity {
            ProcessInfo.processInfo.endActivity(activity)
            self.activity = nil
        }
    }

    // MARK: - Timer actions

    func startPomodoro() {
        guard let areaId = selectedAreaId else { return }
        startPomodoro(areaId: areaId)
    }

    func startPomodoro(areaId: Int64) {
        now = Date()
        perform {
            let pomodoro = try timer.start(areaId: areaId, at: now)
            selectedAreaId = areaId
            notifier?.cancelBreakEnd()
            notifier?.schedulePomodoroEnd(at: pomodoro.plannedEnd, areaName: area(areaId)?.name ?? "")
        }
    }

    /// Starts the next pomodoro in the proposed area, as from the end-of-break notification.
    func startNext() {
        switch status {
        case .idle, .onBreak, .breakOver:
            guard let areaId = selectedAreaId ?? status.nextAreaId else { return }
            startPomodoro(areaId: areaId)
        case .working, .awaitingNote:
            break
        }
    }

    func interrupt() {
        now = Date()
        perform {
            let result = try timer.interrupt(at: now)
            notifier?.cancelPomodoroEnd()
            if case .completed = result { onAttentionNeeded() }
        }
    }

    func saveNoteAndStartBreak(_ note: String) {
        now = Date()
        perform {
            let pause = try timer.finishNote(note.trimmingCharacters(in: .whitespacesAndNewlines), at: now)
            notifier?.scheduleBreakEnd(at: pause.endsAt, kind: pause.kind, nextAreaName: area(selectedAreaId)?.name)
        }
    }

    func endBreak() {
        perform {
            try timer.endBreak()
            notifier?.cancelBreakEnd()
        }
    }

    // MARK: - History

    func showDay(offsetBy days: Int) {
        shownDay = clock.day(shownDay, offsetBy: days)
        reload()
    }

    func showToday() {
        shownDay = today
        reload()
    }

    func addManualPomodoro(areaId: Int64, startedAt: Date, minutes: Int, note: String) {
        perform {
            try database.addManualPomodoro(
                areaId: areaId,
                startedAt: startedAt,
                minutes: minutes,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
    }

    func updatePomodoro(_ pomodoro: Pomodoro, areaId: Int64, note: String) {
        guard let id = pomodoro.id else { return }
        perform { try database.updatePomodoro(id: id, areaId: areaId, note: note) }
    }

    func deletePomodoro(_ pomodoro: Pomodoro) {
        guard let id = pomodoro.id else { return }
        perform { try database.deletePomodoro(id: id) }
    }

    // MARK: - Settings

    func addArea() {
        let usedColors = Set(areas.map(\.color))
        let color = AreaColor.allCases.first { !usedColors.contains($0) } ?? .blue
        perform {
            let area = try database.createArea(
                name: "New area",
                color: color,
                dailyBudgetMinutes: 4 * settings.workMinutes
            )
            if selectedAreaId == nil { selectedAreaId = area.id }
        }
    }

    func updateArea(_ area: Area) {
        perform { try database.updateArea(area) }
    }

    func setArchived(_ area: Area, _ archived: Bool) {
        guard let id = area.id else { return }
        perform { try database.setArchived(areaId: id, archived) }
    }

    func updateSettings(_ change: (inout AppSettings) -> Void) {
        var newSettings = settings
        change(&newSettings)
        perform { try database.saveSettings(newSettings) }
    }
}
