import DayCoachCore
import Foundation
import UserNotifications

/// System notifications for the end of a pomodoro and the end of a break. Both are
/// handed to macOS when the pomodoro or break starts, so they arrive on time even if
/// the app is slowed down in the background (ADR 0001).
@MainActor
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    private static let pomodoroEndId = "pomodoro-end"
    private static let breakEndId = "break-end"
    private static let breakOverCategory = "BREAK_OVER"
    private static let startNextAction = "START_NEXT"

    /// The user chose "Start pomodoro" on the end-of-break notification.
    var onStartNext: () -> Void = {}
    /// The user clicked a notification.
    var onOpen: () -> Void = {}

    private let center: UNUserNotificationCenter

    /// Nil when the app runs outside a `.app` bundle (for example with `swift run`):
    /// the notification center needs a bundle identifier and crashes without one.
    static func makeIfAvailable() -> Notifier? {
        Bundle.main.bundleIdentifier == nil ? nil : Notifier()
    }

    private override init() {
        center = UNUserNotificationCenter.current()
        super.init()
        center.delegate = self
        let startNext = UNNotificationAction(identifier: Self.startNextAction, title: "Start pomodoro")
        center.setNotificationCategories([
            UNNotificationCategory(identifier: Self.breakOverCategory, actions: [startNext], intentIdentifiers: []),
        ])
    }

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func schedulePomodoroEnd(at date: Date, areaName: String) {
        schedule(
            id: Self.pomodoroEndId,
            title: "Pomodoro done",
            body: "\(areaName): write a note, then take your break.",
            at: date
        )
    }

    func scheduleBreakEnd(at date: Date, kind: BreakKind, nextAreaName: String?) {
        let body = nextAreaName.map { "Start the next pomodoro on \($0)?" } ?? "Start the next pomodoro?"
        schedule(
            id: Self.breakEndId,
            title: kind == .long ? "Long break over" : "Break over",
            body: body,
            at: date,
            category: Self.breakOverCategory
        )
    }

    func cancelPomodoroEnd() { cancel(Self.pomodoroEndId) }
    func cancelBreakEnd() { cancel(Self.breakEndId) }

    private func schedule(id: String, title: String, body: String, at date: Date, category: String? = nil) {
        let interval = date.timeIntervalSinceNow
        guard interval > 0.5 else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if let category { content.categoryIdentifier = category }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger)) { _ in }
    }

    private func cancel(_ id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.removeDeliveredNotifications(withIdentifiers: [id])
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Show notifications even while the app is in front.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let action = response.actionIdentifier
        await MainActor.run {
            if action == Self.startNextAction {
                onStartNext()
            } else if action == UNNotificationDefaultActionIdentifier {
                onOpen()
            }
        }
    }
}
