import AppKit
import DayCoachCore

/// The menu bar item: only an icon when idle, the time remaining during a pomodoro,
/// the break time with a different symbol during a break. A click opens the main window.
@MainActor
final class StatusItemController: NSObject {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let onClick: () -> Void
    private var shown: (symbol: String, title: String)?

    init(onClick: @escaping () -> Void) {
        self.onClick = onClick
        super.init()
        item.button?.target = self
        item.button?.action = #selector(clicked)
        item.button?.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
    }

    func update(status: TimerStatus, now: Date) {
        let (symbol, title, description): (String, String, String) = switch status {
        case .idle:
            ("timer", "", "Day Coach")
        case .working(let pomodoro):
            ("timer", ClockText.remaining(pomodoro.plannedEnd.timeIntervalSince(now)), "Pomodoro running")
        case .awaitingNote:
            ("square.and.pencil", "", "Pomodoro done: write the note")
        case .onBreak(_, let endsAt, _):
            ("cup.and.saucer.fill", ClockText.remaining(endsAt.timeIntervalSince(now)), "Break")
        case .breakOver:
            ("bell", "", "Break over")
        }
        guard let button = item.button, shown?.symbol != symbol || shown?.title != title else { return }
        shown = (symbol, title)
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: description)
        image?.isTemplate = true
        button.image = image
        button.title = title.isEmpty ? "" : " \(title)"
        button.imagePosition = title.isEmpty ? .imageOnly : .imageLeading
        button.toolTip = description
    }

    @objc private func clicked() {
        onClick()
    }
}
