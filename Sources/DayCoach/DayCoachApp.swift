import AppKit
import DayCoachCore
import SwiftUI

@main
struct DayCoachApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // The windows are managed by AppDelegate, so the menu bar item can open them
        // from anywhere; this scene only provides the standard menus.
        Settings { EmptyView() }
            .commands {
                CommandGroup(replacing: .appSettings) {
                    Button("Settings…") { appDelegate.showSettings() }
                        .keyboardShortcut(",", modifiers: .command)
                }
                CommandGroup(replacing: .newItem) {
                    Button("Show Main Window") { appDelegate.showMainWindow() }
                        .keyboardShortcut("0", modifiers: .command)
                }
            }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: AppModel?
    private var statusItem: StatusItemController?
    private var mainWindow: NSWindow?
    private var settingsWindow: NSWindow?

    /// The database file; `DAYCOACH_DATABASE` points the app at another one, for trying it out
    /// without touching the real data.
    private static var databaseURL: URL {
        if let path = ProcessInfo.processInfo.environment["DAYCOACH_DATABASE"], !path.isEmpty {
            return URL(filePath: path)
        }
        return AppDatabase.defaultURL
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let model: AppModel
        do {
            let database = try AppDatabase.onDisk(at: Self.databaseURL)
            model = AppModel(database: database, notifier: Notifier.makeIfAvailable())
        } catch {
            let alert = NSAlert()
            alert.messageText = "Day Coach can't open its database"
            alert.informativeText = "\(Self.databaseURL.path)\n\n\(error.localizedDescription)"
            alert.runModal()
            NSApp.terminate(nil)
            return
        }
        self.model = model

        let statusItem = StatusItemController { [weak self] in self?.showMainWindow() }
        self.statusItem = statusItem
        model.onRefresh = { [weak model, weak statusItem] in
            guard let model else { return }
            statusItem?.update(status: model.status, now: model.now)
        }
        model.onAttentionNeeded = { [weak self] in self?.showMainWindow(evenOverOtherApps: true) }
        model.showSettings = { [weak self] in self?.showSettings() }

        // The timer counts from stored start times, so waking up only needs a refresh:
        // a pomodoro that ended during sleep is completed and its form opens.
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak model] _ in
            MainActor.assumeIsolated { model?.tick() }
        }

        model.start()
        showMainWindow()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return true
    }

    /// Shows the main window. With `evenOverOtherApps`, used when a pomodoro ends, the
    /// window comes in front even while another app is active: since macOS 14 an app
    /// can no longer take the focus by itself, so the window is raised without it.
    func showMainWindow(evenOverOtherApps: Bool = false) {
        guard let model else { return }
        if mainWindow == nil {
            mainWindow = makeWindow(
                title: "Day Coach",
                autosaveName: "MainWindow",
                size: NSSize(width: 520, height: 720),
                content: MainView().environment(model)
            )
        }
        present(mainWindow)
        if evenOverOtherApps {
            mainWindow?.orderFrontRegardless()
        }
    }

    func showSettings() {
        guard let model else { return }
        if settingsWindow == nil {
            settingsWindow = makeWindow(
                title: "Settings",
                autosaveName: "SettingsWindow",
                size: NSSize(width: 560, height: 520),
                content: SettingsView().environment(model)
            )
        }
        present(settingsWindow)
    }

    private func present(_ window: NSWindow?) {
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }

    private func makeWindow(title: String, autosaveName: String, size: NSSize, content: some View) -> NSWindow {
        let controller = NSHostingController(rootView: content)
        controller.sizingOptions = []
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.contentViewController = controller
        window.setContentSize(size)
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName(autosaveName)
        return window
    }
}
