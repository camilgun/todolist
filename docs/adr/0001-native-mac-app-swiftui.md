---
status: accepted
date: 2026-11-01
---

# Native Mac app in Swift + SwiftUI

The app is a native macOS app written in Swift with SwiftUI, with a menu bar icon (`MenuBarExtra`) and a main window. It is the only option where the end-of-pomodoro notification is scheduled with the system as soon as the timer starts (`UNTimeIntervalNotificationTrigger`), so it arrives on time even if macOS slows the app down in the background; and it is the only one with direct access to Apple Reminders (EventKit), to Focus filters, and to a future iPhone app with shared code. Details and sources: [research on the app type](../research/2026-11-01-app-type-and-language.md).

## Considered options

- **Tauri v2** (second choice): cross-platform and lightweight, but on the desktop notifications can't be scheduled in advance, and Reminders and Focus would need hand-written Swift plugins anyway. Worth reconsidering only if Windows/Linux became a priority.
- **Electron**: the same notification limits as Tauri, heavier, no path to the iPhone.
- **Local web app**: no menu bar icon, timers slowed down in hidden tabs, no notification once the tab is closed.

## Consequences

- Windows and Linux would require rewriting the interface; the data and the AI bridge remain reusable.
- It builds from the terminal with SwiftPM (`swift build`, verified with the Command Line Tools alone, without Xcode); a script is needed to package the executable into a `.app` with a bundle identifier, because notifications require it.
- Building from source is free; distributing a prebuilt, notarized app requires the paid Apple Developer Program (true for any technology).
- The official MCP SDK (software development kit) for Swift is still experimental: where and in which language to write the MCP server is decided in iteration 2.
