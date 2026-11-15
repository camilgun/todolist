# Day coach

A desktop app that guides the day in pomodoros, turning goals into outcomes small enough to finish, with AI helping where judgement is needed.

## Language

### Work

Key task and quick task are working hypotheses, not settled categories: research and real use will decide which distinctions are actually useful.

**Task**:
An outcome to achieve, belonging to one area, usually with an estimate in pomodoros.
_Avoid_: To-do, activity, item

**Outcome**:
The concrete, checkable result a task or step is written as ("Draft offer sent to the client"), as opposed to effort or time spent ("work on the offer").
_Avoid_: Goal, input, effort

**Step**:
A small outcome inside a task, in an ordered checklist, with no estimate of its own; a pomodoro usually completes one or more steps.
_Avoid_: Subtask, action, item

**Key task**:
A task that really moves things forward but pays off slowly, so it tends to be avoided; it is broken into steps until each step is as small as a quick task.
_Avoid_: Big task, important task

**Quick task**:
A task of a few minutes that gives a fast sense of progress and fills the gaps between other commitments.
_Avoid_: Small task, filler

**Estimate**:
The number of pomodoros a task is expected to take in total; it changes as work progresses, and every change is kept, the first one being the initial estimate.
_Avoid_: Duration, effort

**Remaining work**:
The current estimate of a task minus the pomodoros already done on it.
_Avoid_: Time left, backlog

**Details**:
Free text on a task that gives its context; not to be confused with a note.
_Avoid_: Task notes, description

**Dropped task**:
A task whose outcome is no longer wanted; it is closed without being done, and its pomodoros stay in the history.
_Avoid_: Deleted task, cancelled task

**Current step**:
The first step of a task not yet ticked off; what you see while a pomodoro runs on that task.
_Avoid_: Next action, active step

**AI session**:
A task whose work is done together with the AI, such as breaking key tasks into steps or tidying the list.
_Avoid_: Chat, AI task

### Time

**Pomodoro**:
A fixed block of focused work followed by a break; the unit of estimates and budgets. It always belongs to an area and optionally to one task.
_Avoid_: Session, slot, sprint

**Interrupted pomodoro**:
A pomodoro stopped before its end; the time actually worked counts towards budgets and estimates, and it stays marked as interrupted in the history. One stopped within the first minute is treated as a mistaken start and discarded.
_Avoid_: Cancelled pomodoro, paused pomodoro

**Day**:
A working day; it ends at 4:00 in the morning, not at midnight, so late work still counts for the day it started.
_Avoid_: Date, calendar day

**Area**:
A container for one kind of work (e.g. work, personal) with a default daily budget; tasks inside it are optional.
_Avoid_: Category, project, context

**Budget**:
The number of pomodoros an area gets on a given day; it starts from the area's default and may be exceeded.
_Avoid_: Capacity, quota

**Day plan**:
The morning choice of how many pomodoros each area gets and which open tasks to do, in order.
_Avoid_: Schedule, agenda

### Direction

**Summit**:
Where you want to be in a few years, in life and in work; the direction that tells which key tasks deserve the pomodoros.
_Avoid_: Life goal, north star, vision

### Record

**Note**:
The short free text written at the end of a pomodoro.
_Avoid_: Log, comment

**History**:
The record of pomodoros done, task by task, against their estimates.
_Avoid_: Log, timesheet

**Day recap**:
The always up-to-date view of the current day for the user: pomodoros per area against budget, tasks done, pomodoros against estimates, notes.
_Avoid_: Summary, daily report, review

**Summary**:
The compact digest of history, notes and open tasks that the app prepares for the AI.
_Avoid_: Context dump, report
