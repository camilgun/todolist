# CLAUDE.md

## Public repository

This repository and its GitHub issues are public. Everything written to them is public and permanent: code, comments, docs, commit messages, issues, pull requests.

- Write all of it in English.
- Never include personal details: real names of people, employers, clients or colleagues, email addresses, private habits, or real task and work data. Use invented examples instead ("Draft offer sent to the client").
- The user's app data lives in SQLite outside the repository (see `docs/adr/0002-data-in-sqlite.md`); never commit a database, export, or sample made from real data.
- If something you are about to publish might be personal, ask first.

## Agent skills

### Issue tracker

Issues and specs live as GitHub issues in `camilgun/todolist` (via the `gh` CLI). See `docs/agents/issue-tracker.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
