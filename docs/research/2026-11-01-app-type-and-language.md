# Research: app type and language for iteration 1

> Date: 2026-11-01 · Backlog task: "Choose the app type and language" · Context: [IDEA.md](../../IDEA.md)
> Options compared: native Mac app (Swift + SwiftUI), Tauri v2 (Rust + web interface), Electron (Node + web interface), local web app (local server + browser tab, or PWA, i.e. an installable Progressive Web App).
> **Note (2026-11-01):** the recommendation was accepted, see [ADR 0001](../adr/0001-native-mac-app-swiftui.md). The research started from the assumption that the data would live in text files; that assumption was later dropped in favor of SQLite ([ADR 0002](../adr/0002-data-in-sqlite.md)) and the references to files below were made neutral. The conclusion does not change.

## Outcome in brief

The recommended choice for iteration 1 is a **native Mac app in Swift + SwiftUI**, with an icon in the menu bar (`MenuBarExtra`) and a main window. It is the only option in which the end-of-pomodoro notification can be handed to the operating system when the timer starts, so it arrives on time even if the app is in the background; and it is the only one with direct access to Apple Reminders (EventKit), to macOS Focus filters, and to a future iPhone app with shared code. The price to pay is that Windows and Linux would require rewriting the interface, and that distributing the already-built app to others requires the paid Apple Developer Program (building it from source remains free). The AI bridge does not weigh on the choice: the MCP server (Model Context Protocol, the protocol Claude Desktop uses to talk to local tools) is a separate process that accesses the same data, and it is best written with a tier-1 SDK (software development kit) such as TypeScript, because the Swift one is classified as experimental. If cross-platform support became a priority, the second choice is Tauri, bearing in mind however that Reminders and Focus would still require hand-written Swift code.

## Comparison table

| Criterion | Swift + SwiftUI | Tauri v2 | Electron | Local web app / PWA |
|---|---|---|---|---|
| Terminal workflow with Claude Code | Good with `xcodebuild` or SwiftPM plus a script for the bundle; requires Xcode | Excellent (`tauri dev`, `tauri build`); the Command Line Tools are enough | Excellent (npm) | Excellent (npm or similar) |
| End-of-pomodoro notification with the app in the background | Scheduled in advance by the system: reliable | Immediate only on desktop: depends on the internal timer | Immediate only; on Mac the app must be signed | Immediate only; tab timers throttled; nothing if the tab is closed |
| Menu bar icon | Yes (`MenuBarExtra`, macOS 13+) | Yes (tray) | Yes (Tray) | No |
| Apple Reminders (EventKit) | Direct | Swift plugin to be written | Native module to be written | No |
| Focus | Reacts via Focus filter; activation only through Shortcuts | Only through Shortcuts | Only through Shortcuts | No |
| Future iPhone app | Multiplatform SwiftUI | Supported by Tauri 2, experience still maturing | None | PWA with strong limits |
| Windows / Linux | Interface to be rewritten | Yes | Yes | Yes |
| Open source, build without a paid account | Yes for building; signed distribution is paid | Yes; same for distribution | Yes; same | Yes, no signing |
| AI bridge (MCP) | Tier-3 Swift SDK; better a separate server | Tier-1 Rust SDK | Tier-1 TypeScript SDK | Tier-1 TypeScript SDK |
| Footprint | The lightest | Light (system WebView) | Heavy (Chromium bundled) | Light, but depends on the open browser |

## 1. Ease of development with Claude Code

**Swift + SwiftUI.** Swift can be built from the terminal with the SwiftPM package manager (`swift build`), but SwiftPM produces an executable, not a `.app` app with its own `Info.plist` and its own identifier (bundle identifier). For a real app there are two routes: an Xcode project built from the terminal with `xcodebuild`, or a SwiftPM package plus a script that assembles and signs the bundle. The second route is widespread in the community but is not documented by Apple ([example script](https://github.com/send/macnotifier)). The identifier is not a detail: notifications (`UNUserNotificationCenter`) crash an executable that has no bundle, as several threads on the Apple forums report ([thread 724249](https://developer.apple.com/forums/thread/724249), [thread 54187](https://developer.apple.com/forums/thread/54187)). A new point in favor: since Xcode 26.3 (February 2026) Xcode exposes its functions through MCP, so an agent such as Claude Code can drive builds and previews ([Apple Newsroom](https://www.apple.com/newsroom/2026/02/xcode-26-point-3-unlocks-the-power-of-agentic-coding/)). The Xcode project file (`.pbxproj`) is, however, awkward to edit by hand or for an agent: this is a judgment, not a verified fact. The current version of Swift is 6.4.2 ([swift.org](https://www.swift.org/install/)).

**Tauri v2.** For desktop development on Mac, the Xcode Command Line Tools and Rust are enough; Node is needed only if you use a JavaScript framework for the interface ([Tauri prerequisites](https://v2.tauri.app/start/prerequisites/)). The whole cycle (`tauri dev`, `tauri build`) happens from the terminal. The latest version is 2.12.5, from 21 October 2026 ([releases on GitHub](https://github.com/tauri-apps/tauri/releases)). The drawback is that you work with two languages (Rust and TypeScript), and with a third (Swift) for Apple features.

**Electron.** Everything from the terminal with npm; a single language (JavaScript or TypeScript) for interface and logic. Latest stable version 45.2.1 (31 October 2026, [releases on GitHub](https://github.com/electron/electron/releases)).

**Local web app.** It is the simplest cycle of all: server and page are started and tested from the terminal.

**Signing and notarization.** Running the app on your own Mac does not require a paid account: a free Apple account is enough to use Xcode ([Apple membership comparison](https://developer.apple.com/support/compare-memberships/)), and Tauri supports "ad-hoc" signing without a certificate ([macOS signing, Tauri](https://v2.tauri.app/distribute/sign/macos/)). Distributing an already-built app without macOS blocking it requires Developer ID signing and notarization, which require the Apple Developer Program at 99 dollars a year; this applies equally to Swift, Tauri and Electron ([Tauri](https://v2.tauri.app/distribute/sign/macos/), [Electron](https://www.electronjs.org/docs/latest/tutorial/code-signing), [Gatekeeper, Apple](https://support.apple.com/guide/security/gatekeeper-and-runtime-protection-sec5599b66df/web)).

**Training data (judgment).** TypeScript and the web are in all likelihood the ground on which AI assistants make the fewest mistakes. SwiftUI is well represented, but it changes every year and assistants tend to mix old and new APIs; it is worth having the assistant consult Apple's documentation during development.

## 2. Reliable timers and notifications in the background

**App Nap.** macOS puts into "App Nap" apps that are not in the foreground, are not updating the visible part of their window and are not playing sound: it lowers their priority and **slows down their timers** ([Apple guide on App Nap](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/power_efficiency_guidelines_osx/AppNap.html)). An app can avoid it by declaring an ongoing activity with `ProcessInfo.beginActivity` ([documentation](https://developer.apple.com/documentation/foundation/processinfo/beginactivity(options:reason:))). Concrete example: a 25-minute pomodoro counted with an internal timer could end a few seconds late or more if the app is hidden. The practical rule, valid for all options, is to compute the remaining time from the end time and not to count "ticks".

**Swift.** With `UNTimeIntervalNotificationTrigger` the app asks the system to deliver a notification after a certain number of seconds; Apple recommends it precisely for implementing timers ([documentation](https://developer.apple.com/documentation/usernotifications/untimeintervalnotificationtrigger)). The end-of-pomodoro notification is therefore scheduled at start and arrives even if the app is in App Nap. It requires an app with a bundle identifier (see section 1).

**Tauri.** The official notification plugin accepts a `schedule` option, but the source code states clearly that scheduling works only on mobile and that on desktop notifications are always shown immediately ([plugin source](https://github.com/tauri-apps/plugins-workspace/blob/v2/plugins/notification/guest-js/index.ts)). On the Mac, therefore, the notification fires when the app's timer fires, and that timer is exposed to App Nap. In addition, in development mode notifications on macOS use the Terminal's identity ([source](https://github.com/tauri-apps/plugins-workspace/blob/v2/plugins/notification/src/desktop.rs)).

**Electron.** Notifications are shown on the spot, without scheduling. On macOS the app must be signed for notification events to work correctly; an unsigned binary receives a `failed` event ([Electron documentation](https://www.electronjs.org/docs/latest/tutorial/notifications)). Background pages have their timers throttled by default (`backgroundThrottling`, [documentation](https://www.electronjs.org/docs/latest/api/structures/web-preferences)), while `powerSaveBlocker` with `prevent-app-suspension` prevents the app from being suspended ([documentation](https://www.electronjs.org/docs/latest/api/power-save-blocker)).

**Web.** Web notifications require the user's permission and a secure context; `localhost` is considered secure ([MDN Notifications API](https://developer.mozilla.org/en-US/docs/Web/API/Notifications_API), [MDN Secure contexts](https://developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts)). There is no standard way to schedule them: Chrome's Notification Triggers API has been abandoned ([Chrome for Developers](https://developer.chrome.com/docs/web-platform/notification-triggers)). In a hidden tab Chrome checks timers once per second, and after 5 minutes once per minute for chained timers such as `setInterval` ([Chrome for Developers](https://developer.chrome.com/blog/timer-throttling-in-chrome-88)). A single 25-minute `setTimeout` would stay accurate to the second, but if the tab or the browser is closed the notification does not arrive.

## 3. Menu bar icon

SwiftUI offers `MenuBarExtra`, available since macOS 13, which can be a menu or a small panel and also allows apps that live only in the menu bar ([documentation](https://developer.apple.com/documentation/swiftui/menubarextra)). Tauri has the tray (by enabling the `tray-icon` feature), with some mouse events not supported on Linux ([documentation](https://v2.tauri.app/learn/system-tray/)). Electron has `Tray`, with features specific to the Mac menu bar such as a text title next to the icon, useful for showing the remaining minutes ([documentation](https://www.electronjs.org/docs/latest/api/tray)). A web app cannot put icons in the menu bar; Safari only allows adding a site to the Dock as a separate app ([WebKit, Safari 17](https://webkit.org/blog/14445/webkit-features-in-safari-17-0/)).

## 4. Apple Reminders, Focus and iPhone app

**Apple Reminders.** Access goes through EventKit, for example with `requestFullAccessToReminders` (macOS 14+, iOS 17+) ([documentation](https://developer.apple.com/documentation/eventkit/ekeventstore/requestfullaccesstoreminders(completion:))). In Swift it is a direct API. Tauri has no official plugins for Reminders, calendar or Focus ([plugin list](https://v2.tauri.app/plugin/)): one would have to be written with native code. Electron would require a native module. From the web it is not possible.

**Focus.** The public APIs allow an app to **react** to a Focus, not to activate it. `SetFocusFilterIntent` (App Intents, macOS 13+) lets the app change behavior when the user activates a Focus for which they have configured a filter ([documentation](https://developer.apple.com/documentation/appintents/setfocusfilterintent)); `INFocusStatusCenter` tells whether Focus is active ([documentation](https://developer.apple.com/documentation/intents/infocusstatuscenter)). To **activate** Focus when a pomodoro starts, the practical route is to have the app run one of the user's Shortcuts with the command `shortcuts run "Name"` ([Apple guide](https://support.apple.com/guide/shortcuts-mac/run-shortcuts-from-the-command-line-apd455c82f02/mac)), which contains the "Set Focus" action. This route works with any desktop option, because it is a system command. macOS also allows activating a Focus when a certain app is opened, but it deactivates it when you switch app, so it does not suit a timer that works in the background ([Apple guide on Focus](https://support.apple.com/guide/mac-help/set-up-a-focus-to-stay-on-task-mchl613dc43f/mac)).

**iPhone app.** SwiftUI is designed to share code between Mac and iPhone. Tauri 2 supports iOS and Android since the stable 2.0 release (October 2024), but at release time the team itself said it was not entirely satisfied with the mobile development experience and that not all plugins work on mobile ([Tauri 2.0 blog post](https://v2.tauri.app/blog/tauri-20/)); iOS requires full Xcode in any case. Electron has no mobile versions ([documentation](https://www.electronjs.org/docs/latest/)). A PWA on iPhone can receive notifications only as Web Push and only if added to the Home Screen ([WebKit](https://webkit.org/blog/13878/web-push-for-web-apps-on-ios-and-ipados/)): it would need a remote server to send the notifications, which goes against the idea of local data.

## 5. Cross-platform in the future

Swift runs on macOS, Linux and Windows ([swift.org](https://www.swift.org/install/)), but SwiftUI, EventKit and Apple notifications exist only on Apple platforms: for Windows and Linux the interface would have to be rewritten. The data and the MCP server can, however, be reused, if the latter is written in a portable language. Tauri and Electron cover Windows, macOS and Linux with the same code ([Tauri](https://v2.tauri.app/), [Electron](https://www.electronjs.org/docs/latest/)). The web app runs anywhere there is a browser.

## 6. Open source

All the foundations are open source with permissive licenses: Swift Apache-2.0 ([repository](https://github.com/swiftlang/swift)), Tauri MIT or Apache-2.0 ([repository](https://github.com/tauri-apps/tauri)), Electron MIT ([repository](https://github.com/electron/electron)). Anyone who wants to build the app from source does not need a paid account with any of the options. The difference is in distribution: an already-built Mac app without notarization is blocked or flagged by Gatekeeper, so offering a "clean" downloadable file requires the Apple Developer Program, whatever the technology. Swift requires Xcode, which runs only on Mac; for a Mac app this is not a real limitation.

## 7. AI bridge

**How Claude Desktop uses local servers.** Claude Desktop launches local MCP servers as processes on the user's computer, starting from a command written in `claude_desktop_config.json` (for example `npx …`), and reads their logs from the standard error stream, which is typical of "stdio" servers ([MCP guide](https://modelcontextprotocol.io/docs/develop/connect-local-servers)). Alternatively, the server can be packaged as an `.mcpb` extension, installable with one click; extensions support Node.js, Python and binary servers, and Claude Desktop already includes Node.js ([Claude support](https://support.claude.com/en/articles/10949351-get-started-with-local-mcp-servers-on-claude-desktop)).

**Official SDKs.** The MCP site classifies SDKs into three tiers: tier 1 complete and maintained with guaranteed response times, tier 3 experimental ([SDK tiers](https://modelcontextprotocol.io/community/sdk-tiers)). TypeScript, Python, C#, Go, Rust and Ruby are tier 1; Swift is tier 3 ([SDK list](https://modelcontextprotocol.io/docs/sdk)). The Swift SDK is at version 0.12.1 (May 2026), is pre-1.0 and may introduce breaking changes, although it supports stdio and is maintained in collaboration with Apple ([repository](https://github.com/modelcontextprotocol/swift-sdk)). The Rust SDK (`rmcp`) is at 3.8.0 and the TypeScript SDK at 2.4.0, both released at the end of October 2026 ([rust-sdk](https://github.com/modelcontextprotocol/rust-sdk/releases), [typescript-sdk](https://github.com/modelcontextprotocol/typescript-sdk/releases)).

**Consequence for the choice.** The MCP server does not have to live inside the app: it is a small separate program that Claude Desktop launches and that accesses the same data. It can therefore be written in TypeScript even if the app is in Swift. With Electron or a web app the language would be the same as the app's; with Tauri the server could reuse the Rust code: a real but small advantage. Alternatives without MCP also remain possible, for example a small command-line tool that the AI invokes. App Intents (the actions a Swift app exposes to Shortcuts) are not a channel to Claude Desktop: I found no evidence that Claude Desktop uses them.

## 8. Footprint

The Swift app is the lightest because it uses only system libraries. Tauri uses the system's web engine and claims apps starting from about 600 KB, without explaining how it measures this ([Tauri site](https://v2.tauri.app/)). Electron bundles Chromium and Node.js in every app ([documentation](https://www.electronjs.org/docs/latest/)), so it weighs tens or hundreds of MB (order of magnitude by judgment, not measured). The web app is light in itself but requires an open browser. For an app that is always on in the menu bar this matters somewhat, but it remains a secondary criterion.

## Fifth option (sketch)

A sensible variant is to separate the "core" from the shells: a core that reads and writes the data (in Swift as a SwiftPM package, or in TypeScript), a SwiftUI app for the Mac, and an MCP server or a command-line tool for the AI. In practice it is the main recommendation organized into modules, and it makes a future Windows or Linux shell easier.

## Risks and uncertainties

- **Bundle and notifications in Swift.** That `UNUserNotificationCenter` requires an app with a bundle identifier is confirmed by several reports and projects, but I did not find an explicit statement in Apple's documentation.
- **SwiftPM without Xcode.** I did not find an official procedure for producing a `.app` app with `swift build`; the script-based solutions come from the community. It should be tried in a prototype if we want to avoid the Xcode project.
- **Xcode and MCP.** I saw the characteristics of `xcrun mcpbridge` confirmed by Apple's announcement only in general terms; the details (exact command, requirements) come from secondary sources.
- **App Nap on Tauri and Electron.** I did not verify how much App Nap slows down a Rust or Node timer in practice, nor whether WKWebView throttles the timers of a hidden window.
- **Electron notifications in development.** I did not verify whether notifications work when the app is launched with `npm start` without signing it.
- **"Set Focus" action in Shortcuts.** I did not find the Apple page that describes it; its existence is confirmed only by secondary sources and should be tried on your own Mac.
- **Apple pages** loaded through their JSON format: availability by version verified, texts partly summarized.
- The judgments on training data and on Electron's footprint are not measured.

## Sources

- https://developer.apple.com/documentation/swiftui/menubarextra
- https://developer.apple.com/documentation/usernotifications/untimeintervalnotificationtrigger
- https://developer.apple.com/documentation/usernotifications/unusernotificationcenter
- https://developer.apple.com/documentation/foundation/processinfo/beginactivity(options:reason:)
- https://developer.apple.com/library/archive/documentation/Performance/Conceptual/power_efficiency_guidelines_osx/AppNap.html
- https://developer.apple.com/documentation/eventkit/ekeventstore/requestfullaccesstoreminders(completion:)
- https://developer.apple.com/documentation/appintents/setfocusfilterintent
- https://developer.apple.com/documentation/intents/infocusstatuscenter
- https://developer.apple.com/support/compare-memberships/
- https://developer.apple.com/forums/thread/724249
- https://developer.apple.com/forums/thread/54187
- https://www.apple.com/newsroom/2026/02/xcode-26-point-3-unlocks-the-power-of-agentic-coding/
- https://support.apple.com/guide/shortcuts-mac/run-shortcuts-from-the-command-line-apd455c82f02/mac
- https://support.apple.com/guide/mac-help/set-up-a-focus-to-stay-on-task-mchl613dc43f/mac
- https://support.apple.com/guide/security/gatekeeper-and-runtime-protection-sec5599b66df/web
- https://www.swift.org/install/
- https://github.com/swiftlang/swift
- https://github.com/send/macnotifier
- https://v2.tauri.app/
- https://v2.tauri.app/start/prerequisites/
- https://v2.tauri.app/distribute/sign/macos/
- https://v2.tauri.app/plugin/
- https://v2.tauri.app/plugin/notification/
- https://v2.tauri.app/learn/system-tray/
- https://v2.tauri.app/blog/tauri-20/
- https://github.com/tauri-apps/tauri/releases
- https://github.com/tauri-apps/plugins-workspace/blob/v2/plugins/notification/guest-js/index.ts
- https://github.com/tauri-apps/plugins-workspace/blob/v2/plugins/notification/src/desktop.rs
- https://www.electronjs.org/docs/latest/
- https://www.electronjs.org/docs/latest/tutorial/notifications
- https://www.electronjs.org/docs/latest/tutorial/code-signing
- https://www.electronjs.org/docs/latest/api/tray
- https://www.electronjs.org/docs/latest/api/structures/web-preferences
- https://www.electronjs.org/docs/latest/api/power-save-blocker
- https://github.com/electron/electron/releases
- https://developer.mozilla.org/en-US/docs/Web/API/Notifications_API
- https://developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts
- https://developer.chrome.com/blog/timer-throttling-in-chrome-88
- https://developer.chrome.com/docs/web-platform/notification-triggers
- https://webkit.org/blog/14445/webkit-features-in-safari-17-0/
- https://webkit.org/blog/13878/web-push-for-web-apps-on-ios-and-ipados/
- https://modelcontextprotocol.io/docs/sdk
- https://modelcontextprotocol.io/community/sdk-tiers
- https://modelcontextprotocol.io/docs/develop/connect-local-servers
- https://github.com/modelcontextprotocol/swift-sdk
- https://github.com/modelcontextprotocol/rust-sdk/releases
- https://github.com/modelcontextprotocol/typescript-sdk/releases
- https://support.claude.com/en/articles/10949351-get-started-with-local-mcp-servers-on-claude-desktop
