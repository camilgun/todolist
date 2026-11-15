# Idea: the day coach (working title)

> Living document: it describes **what** we want to build and **why**. Project terms are defined in [GLOSSARY.md](GLOSSARY.md); reasoned technical decisions live in [docs/adr/](docs/adr/); work to do lives in the GitHub issues.
> Status: **v4**: app type and data storage decided (2026-11-01); focus principles and the summit added (2026-11-01).

## The essence

A desktop app that guides the day in pomodoros. Every task is written as an outcome to achieve, has an estimate in pomodoros and, if it is large, is broken down into small steps. In the morning you decide how many pomodoros you have and what to do; during the day the app starts the pomodoros one after another and always shows you the next step. AI comes in where judgement is needed (understanding, estimating, breaking down, finding what really matters), and the app hands it only the information it needs, already organised.

## Principles

- **The app does the mechanical work, the AI does the judgement.** Counting, ordering, summarising the history: the app, deterministically. Recognising that a task is too big, estimating it, proposing how to break it down, connecting ideas: the AI. The app prepares a compact, clear context for the AI, so few tokens are spent and the AI makes fewer mistakes.
- **AI is not mandatory.** Every flow must be doable in the app alone, morning planning included. Where AI really helps has to be proven in practice.
- **A task is an outcome, not time spent.** "Draft offer sent to the client", not "work on the offer for 30 minutes". Finishing something concrete is satisfying; staying abstract is frustrating.
- **The next step is always known.** Finishing a piece of work without knowing what comes next is where focus gets lost, so the rules of the game are set before playing: the steps are decided before the pomodoro starts, not during it.
- **Key tasks are broken down until every step is as small as a quick task.** Key tasks move things forward but pay off slowly, so they tend to be avoided; small steps turn them into visible progress every pomodoro. The best working days are the ones where you feel you moved forward a little.
- **Quick tasks are not waste.** They give a quick sense of progress and fill the gaps between other commitments; they can be batched into a single pomodoro.
- **Estimates change along the way.** If a task needs more or fewer pomodoros than expected, you adjust it while you work.
- **Ideas about focus are tested, not taken on faith.** Outcomes, breaking work down, key and quick tasks, morning planning: research checks whether they hold and what else the evidence suggests.
- **It works for its author first**, on a Mac, then everything else. Open source project.

## The elements

**Task.** A title written as an outcome, an area (e.g. work or personal), an estimate in pomodoros, optional steps with their own estimates, notes. A task is either a key task (important, large, slow to pay off: it gets broken into steps) or a quick task (a few minutes, fills the gaps).

**AI sessions.** Not all work is a concrete task: defining, tidying up and consolidating take time too. This also becomes a task, for example "tidy-up with the AI, 1 pomodoro", ideally with an expected outcome ("this week's key tasks broken into steps"). When it starts, the app could open the AI tool directly on the right project.

**The day.** In the morning you declare the pomodoros available (e.g. 8 for work + 4 personal) and choose, among the ready tasks, what to do today and in what order. The guiding question: which one, two, at most three things would make today a success, the ones your future self will thank you for? Without AI by default; with AI if it proves useful.

**Execution.** You start a pomodoro on a task: the timer starts and you see the current step. At the end you write a short note, tick off the steps done, and adjust the estimate.

**History and notes.** The app records the pomodoros done, task by task, against the estimate. When an AI session starts, the app hands it a summary. Example: "10 pomodoros done; 4 on task X out of 5 planned, but the note says it is finished, so task Y can be unblocked".

**The summit** (with the AI). When it isn't clear which tasks really matter, step back: where do you want to be in a few years, in life and in work? A guiding exercise: imagine the end of your life and ask what you need to have lived to leave it at peace. The answer is the summit, the direction that tells which key tasks deserve the pomodoros. Finding it takes dedicated reflection sessions with the AI, perhaps at first launch; afterwards the AI uses it to suggest what matters.

**Sources** (later). Apple Reminders, voice memos, calendars: they all feed the task list.

## Decisions made

- **Desktop (Mac) first**: that's where the work happens and where you want to control the pomodoros. iPhone later.
- **Areas are containers with a daily pomodoro budget.** Example: "Work: 8 pomodoros, Personal: 4". Tasks inside an area are optional: work can stay a block of generic pomodoros (with the end-of-pomodoro note) or be detailed into tasks and steps on the day it's needed.
- **We proceed in iterations**, like sprints: each one adds a usable piece (see the roadmap below).
- **Native Mac app in Swift + SwiftUI**, with a menu bar icon ([ADR 0001](docs/adr/0001-native-mac-app-swiftui.md)).
- **Data in an SQLite database on the user's Mac**, never in the code repository (which is public). The AI reads and changes the data through tools exposed by the app, not by writing to the data directly ([ADR 0002](docs/adr/0002-data-in-sqlite.md)).
- **Available time declared by hand** every morning, in pomodoros. No integration with external calendars in the first version, and no calendar blocks for the team.
- **Apple Reminders are not needed in the first version.** They will be the first external source; later both read and write.
- **Audio is out of the first version**: for now audio files are imported by hand. The audio flow will be designed from scratch.

## Roadmap (confirmed 2026-11-01)

Like sprints: each iteration adds a usable piece.

### Iteration 1: the pomodoro app
No AI and no external sources. Goal: actually use it every day for work.

- Task list: create, edit, change area. Title written as an outcome, optional steps.
- Estimate in pomodoros per task (and per step), editable along the way.
- Areas (work, personal) as containers with a daily pomodoro budget; tasks inside an area are optional.
- The day: declare the pomodoros available per area, choose the ready tasks and their order.
- Execution: start a pomodoro on a task or a step, work and break timer, current step in view.
- End of pomodoro: free-form note, steps completed, estimate updated.
- History: pomodoros done per task, against the estimate; automatic summary of the day.
- Data in a local SQLite database; the schema is designed from the start so the app can prepare a compact summary for the AI.

### Iteration 2: the AI bridge
- The AI receives a compact summary prepared by the app (history, notes, ready tasks) and writes changes in a controlled way.
- AI sessions: spot tasks that are too large, estimate them, break them down together, tidy up the list.
- Morning planning with the AI, as an option to try.
- AI session as a task type: when the pomodoro starts, the app opens the AI tool on the right project (if feasible).
- Finding the summit: reflection sessions with the AI that define it and keep it up to date.
- Focus techniques backed by research (for example pairing an unrewarding hard task with a rewarding one), in whatever form the research suggests: AI skills, MCP tools, or app features.

### Iteration 3: sources and context
- Internal calendar: meetings entered by hand, warnings like "you have a call in 10 minutes, the pomodoro won't fit".
- Apple Reminders, read-only.
- Manual import of audio files → transcription → actions and ideas in the list.

## Open questions (to reason through together, not to research)

- [ ] End of the day: are end-of-pomodoro notes plus an automatic summary enough, or is a closing moment needed too? We start with notes and summary (iteration 1) and decide by using the app.

Questions that need research (AI bridge, focus science, …) are GitHub issues.
