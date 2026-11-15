---
status: accepted
date: 2026-11-01
---

# Data in a local SQLite database, the AI goes through the app's tools

The user's data (areas, tasks, steps, days, pomodoros, notes) lives in an SQLite database in the app's data folder (`~/Library/Application Support/…`), never in the code repository, which is public. In Swift we use it through the GRDB library, with tables we design ourselves. From iteration 2, the AI reads and changes the data through tools exposed by the app (MCP, Model Context Protocol: operations such as "add task" or "split task" that the app validates), not by writing directly to the database. With the AI going through the tools, SQLite gives for free what files would need built by hand: all-or-nothing operations across several pieces of data, two processes (app and MCP server) writing without corrupting each other, queries for the history, type constraints.

## Considered options

- **Text files as the single source of truth** (JSON per entity plus a JSON Lines log, or YAML, or Markdown with front matter): this was the initial assumption in `IDEA.md`, proposed during the first analysis phase and never motivated by a concrete need. Its only real advantage was that the AI could edit the files directly, without the app; once we chose that the AI goes through the app's tools, that advantage disappears. Format comparison: [research on the data format](../research/2026-11-01-data-format.md).
- **SwiftData / Core Data** (Apple, also built on SQLite): they would give iCloud sync almost for free, but they lay out the tables their own way, hard for another program to read (for example an MCP server not written in Swift), and tie the data to Apple.
- **Server databases** (PostgreSQL, MySQL): they need a server process to install and manage; they make no sense for a personal app installed by each user on their own Mac.
- **Other embedded databases**: Realm was deprecated by MongoDB in 2024; DuckDB is designed for analytics on large data, not for an app's continuous writes; key-value databases (LMDB and similar) offer neither queries nor constraints.

## Consequences

- The data can't be fixed by hand in an editor; to read it outside the app there is the `sqlite3` command, and possibly a JSON export if it becomes necessary.
- The schema evolves through versioned migrations (GRDB handles them).
- Sync with a future iPhone app is not solved: an SQLite file must not be put on iCloud Drive; a dedicated mechanism (for example CloudKit) will be needed when the iPhone app arrives.
