# Day coach

A Mac app that guides the day in pomodoros. What it is and why: [IDEA.md](IDEA.md). Terms: [GLOSSARY.md](GLOSSARY.md). Decisions: [docs/adr/](docs/adr/).

## Build and run

Needs macOS 14 or later and Swift 6 (the Xcode Command Line Tools are enough).

```sh
scripts/build-app.sh          # builds build/DayCoach.app
open build/DayCoach.app
```

The app needs to run as a `.app` bundle for notifications; `swift run` works too, without them.

Your data lives in `~/Library/Application Support/DayCoach/daycoach.sqlite`, never in this repository. To try the app without touching it, point it at another file:

```sh
open --env DAYCOACH_DATABASE=/tmp/daycoach-try.sqlite build/DayCoach.app
```

## Tests

```sh
scripts/test.sh
```

The script adds the paths the Command Line Tools need to find the Swift Testing framework; with Xcode installed it just runs `swift test`.

## Layout

- `Sources/DayCoachCore`: data and rules, no user interface: the SQLite database (GRDB), the timer, days, counters.
- `Sources/DayCoach`: the macOS app: menu bar item, main window, settings, notifications.
- `Tests/DayCoachCoreTests`: tests for the core.
