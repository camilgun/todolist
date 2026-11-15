---
status: accepted
date: 2026-11-15
---

# Time is stored in minutes; the pomodoro is only a display unit

Estimates, budgets and work done are stored in minutes, and work done comes from each pomodoro's real start and end times. The pomodoro is only how the app shows these numbers: minutes divided by the configured work length. The evidence for fixed 25-minute blocks is thin (see [the focus research](../research/2026-11-15-focus-and-motivation.md), section 3.6), and flexible blocks are a candidate for after iteration 1 (GitHub issue #9). With minutes in the data, a different block length or flexible blocks change only what is shown, with no data migration.

## Considered options

- **Whole pomodoros as the stored unit**: matches the language of the app, but changing the block length or moving to flexible blocks would make every stored estimate, budget and history entry ambiguous.

## Consequences

- Changing the pomodoro length changes the numbers shown everywhere: an estimate of 500 minutes reads "20 pomodoros" at 25 minutes and "10 pomodoros" at 50. The real amount of work is unchanged.
- Interrupted pomodoros count with the minutes actually worked, so work done can be a fraction of a pomodoro; the interruption itself stays recorded.
