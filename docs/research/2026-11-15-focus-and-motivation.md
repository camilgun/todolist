# Research: the science of focus and motivation

> Date: 2026-11-15 · GitHub issue #1: "Research: the science of focus and motivation".
> Primary sources cited for every claim. Next to each source in section 6 I say how much of it I read: **[full text]**, **[abstract only]**, or **[not verified]**. Claims that rest on a source I could not open are marked **[not verified]** in the text.
> Scope: shapes the design of iteration 1, does not block it.

## 1. Outcome in brief

The ideas the app is built on hold up unevenly. The best-supported ones are not the pomodoro itself but what the app does around it: **writing a specific outcome** (goal-setting research, decades of meta-analyses), **recording progress against it** (a meta-analysis of 138 experiments), **breaking a key task into near-term steps** (experiments, no dedicated meta-analysis), and **deciding in advance what happens at a given moment** ("if-then" plans, 642 tests, but with a real effect that is probably small once publication bias is corrected).

The **pomodoro** as a fixed 25/5 rhythm has thin evidence: two small student experiments that disagree with each other, and a meta-analysis of short breaks that finds a small benefit for energy and none proven for performance. It is a reasonable unit for estimates and history, not a proven productivity technique, so the lengths should be configurable and the app should not claim more.

**Estimates** are biased in a known direction (people remember past tasks as shorter than they were), and the fix with the best support is exactly what the history provides: showing the real duration of similar past work. **Morning planning** has one good field study behind it, with an important condition: on days with many interruptions a task list alone stops helping, while planning for interruptions keeps helping. **Alternating heavy and light work** has no direct support; the theory usually quoted for it (willpower as a tank that empties) failed two large preregistered replications, and a large field study shows that drifting towards easy tasks under load hurts. **Temptation bundling** works modestly in one domain (exercise) and has never been tested on desk work. The **progress principle** is plausible and consistent with the rest, but its own source is a book and a magazine article I could not read in full.

## 2. Summary table

Strength of evidence: **strong** = several meta-analyses or large preregistered studies agreeing; **moderate** = one meta-analysis with caveats, or several consistent experiments; **weak** = a few small or single-domain studies; **mixed** = studies disagree; **failed** = did not replicate.

| Technique | Evidence | In one line | Fit with the app |
|---|---|---|---|
| Task written as a specific outcome | Strong (with one caveat) | Specific, challenging goals beat "do your best"; outcomes outside your control do not help | Planning rule + writing hint |
| Recording progress every pomodoro | Strong | Monitoring progress raises goal attainment, more so when physically recorded | Feature (already in iteration 1) |
| Breaking a key task into steps | Moderate | Near-term sub-goals raise performance and confidence; near the end, the whole task motivates more | Planning rule; later an AI suggestion |
| If-then plans (implementation intentions) | Moderate, effect small | Robust but inflated by publication bias; best in if-then form | Feature: "next step" prompt at end of pomodoro |
| Estimates corrected by history | Moderate | Bias comes from misremembered durations; showing real durations improves accuracy | Feature (history next to the estimate) |
| Morning planning | Moderate (one field study + correlational meta-analysis) | Helps on calm days; add a plan for interruptions | Day plan + slack rule |
| Pomodoro (fixed work/break blocks) | Weak, mixed | No proven performance gain over self-chosen breaks; breaks help energy a little | Keep as unit; make lengths configurable |
| Temptation bundling | Weak outside exercise | 10–14% more workouts in a large trial; untested on knowledge work | Optional AI suggestion in iteration 2, as an experiment |
| Progress principle | Not verified in a peer-reviewed source | Consistent with monitoring and sub-goal evidence | Day summary framed as progress |
| Alternating heavy and light work | No direct evidence; underlying theory failed | Ego depletion did not replicate; preferring easy tasks under load hurts | No rule; protect key tasks instead |
| Hardest task first | Weak (one paper, lab tasks) | Hard-to-easy order left people feeling more capable than easy-to-hard | Default ordering hint, not a rule |

## 3. The techniques, one by one

### 3.1 Tasks as outcomes, not effort

**Claim.** "Draft offer sent to the client" works better than "work on the offer for 30 minutes".

**Evidence: strong for specificity, with a caveat about what kind of outcome.** Goal-setting theory summarises 35 years of experiments: specific, difficult goals lead to higher performance than urging people to "do their best", with meta-analytic effect sizes of d = .42 to .80, because a vague goal has no reference point for what counts as enough (Locke & Latham, 2002). A later meta-analysis restricted to randomised trials found a smaller unique effect of setting a goal on behaviour, d = .34 across 384 effect sizes (Epton, Currie & Armitage, 2017). Two caveats matter for the app:

- *Complex or unfamiliar work.* The effect is smaller on complex tasks (d = .41 versus .77 on simple ones), and in one study a performance goal on a highly complex task interfered with learning; a specific *learning* goal fixed that (Locke & Latham, 2002).
- *Outcomes you do not control.* In sport, goals about the result of a competition had almost no effect on performance (d = 0.09), while goals about one's own actions had a large one (d = 1.36); the pooled studies are few (27) and from sport only (Williamson et al., 2022). The app's meaning of outcome ("a concrete, checkable result") is closer to a specific goal than to "winning", but the warning transfers: "Offer accepted by the client" depends on someone else, "Draft offer sent to the client" does not.

There is also a cost: failing a specific, difficult goal lowers mood and motivation, which is one more reason to keep steps small enough to finish.

**Fit.** A writing hint when a task or step is created: checkable, finishable by you. For exploratory work, an outcome about what will be known or produced ("Three pricing options listed with pros and cons"). In iteration 2 the AI can flag titles that describe effort ("work on…") or depend on other people.

### 3.2 Breaking key tasks into steps

**Claim.** Key tasks pay off slowly and get avoided; small steps turn them into visible progress.

**Evidence: moderate.** The premise is well supported: a meta-analysis of 691 correlations found task aversiveness and delay of the reward among the strong, consistent predictors of procrastination (Steel, 2007; correlational). For the remedy there are experiments but no dedicated meta-analysis. In the classic one, children who were weak at arithmetic and worked with near-term sub-goals progressed faster, mastered more, and gained confidence and interest; a distant goal had no demonstrable effect (Bandura & Schunk, 1981; one experiment, children). On a complex business game, adding near-term outcome goals to a distant one raised confidence and results (Latham & Seijts, 1999, as reported in Locke & Latham, 2002; original **[not verified]**). A refinement: sub-goals help most early on, when the question is "can I do this?"; near completion, looking at the whole goal motivates more (Huang, Jin & Zhang, 2017; four experiments).

**Fit.** The rule "key tasks are broken down until every step is as small as a quick task" is defensible. During a pomodoro show the current step; when a task is nearly finished, show the whole task's progress too ("5 of 6 pomodoros, last step").

### 3.3 Visible progress every pomodoro (and the progress principle)

**Claim.** The best days are the ones where you feel you moved forward; every pomodoro should show progress.

**Evidence: strong for monitoring progress; the "progress principle" itself is not verified.** A meta-analysis of 138 randomised studies (N = 19,951) found that prompting people to monitor progress towards a goal improved attainment (d = 0.40), with larger effects when the information was physically recorded or made public (Harkin et al., 2016; most studies are about health behaviour). Goal-setting research agrees: goals plus feedback on progress work better than goals alone (Locke & Latham, 2002). The progress principle (progress in meaningful work is the strongest daily driver of mood and motivation) comes from a diary study published as a book and a magazine article (Amabile & Kramer, 2011). I could open only a truncated summary, so the usual figures (238 employees, about 12,000 diary entries) are **[not verified]**, and the design is observational in any case. The related "endowed progress" and "goal gradient" effects (people speed up as they approach a goal, and a head start increases persistence) come from loyalty-card experiments (Kivetz, Urminsky & Zheng, 2006; Nunes & Drèze, 2006); the transfer to desk work is a guess.

**Fit.** The end-of-pomodoro moment in iteration 1 (note, steps ticked, estimate adjusted) is a progress-monitoring intervention in the sense of Harkin et al., and it is physically recorded. Keep it short so it is done every time. The day summary should lead with what was completed.

### 3.4 Estimates

**Claim.** Every task has an estimate in pomodoros, and estimates change along the way.

**Evidence: moderate, and it points at the history.** People's predictions of when they will finish their own tasks are optimistic, because they think about the plan ahead instead of similar past work; asking them to connect past experience to the prediction removed the bias in one study (Buehler, Griffin & Ross, 1994). A review argues the deeper cause is that people remember past tasks as shorter than they were (Roy, Christenfeld & McKenzie, 2005), and three experiments showed that giving people the real duration of previous similar work made predictions more accurate (Roy, Mitten & Christenfeld, 2008). A broader review is more cautious: underestimation dominates in engineering and management studies but not in psychology experiments, and the pattern "small tasks overestimated, large tasks underestimated" may be partly a statistical artefact (Halkjelsvik & Jørgensen, 2012). On breaking work down: the time allocated to a single task is consistently smaller than the sum of the times allocated to its parts (Forsyth & Burt, 2008; three experiments), so estimating step by step pushes estimates up, towards realism when the starting point is optimistic. The paper most often cited for this, Kruger & Evans (2004), I could not open: **[not verified]**.

**Fit.** Show, next to the estimate field, what the history says ("tasks you estimated at 3 took 4 on average"). Estimate at the step level and let the task total be the sum. Record every estimate change, so the correction factor can be computed later.

### 3.5 Morning planning

**Claim.** Deciding in the morning how many pomodoros there are and what goes in them makes the day better.

**Evidence: moderate.** A two-week experience-sampling study of employees found that days with time-management planning (list, priorities, when and how) had higher engagement and performance, but the benefit weakened on days with many interruptions; contingent planning (anticipating interruptions and deciding how to handle them) helped regardless (Parke et al., 2018; within-person, self-reported). A meta-analysis of 158 studies found time management moderately related to job performance (r ≈ .25) and more strongly to wellbeing; most of it is cross-sectional and planning is not analysed separately (Aeon, Faber & Panaccio, 2021). Making a specific plan for an unfinished goal also stops it intruding on other work (Masicampo & Baumeister, 2011; lab studies), and planning unfinished goals at the end of the day helped some employees detach in the evening (Smit, 2016). Nothing I found tests morning against evening planning, or the "one to three things" rule.

**Fit.** The day plan is supported. Add the contingent part cheaply: leave part of the budget unassigned, and ask one question in the morning ("what could interrupt today, and what will you do then?"). The evidence on unfinished goals bears on the open question in `IDEA.md` about a closing moment: a one-line plan for each unfinished task has some support.

### 3.6 The pomodoro: fixed work and break blocks

**Claim.** Working in fixed blocks with fixed breaks improves focus.

**Evidence: weak and mixed.** Two experiments from the same group compared fixed and self-chosen breaks in real study sessions. In the first (87 students, one day), fixed breaks went with less fatigue and distraction and more concentration and motivation, with the same amount of work done in less time (Biwer et al., 2023). In the second (94 students, two hours), pomodoro breaks led to a *faster* rise in fatigue and a faster drop in motivation than self-chosen breaks, with no difference in productivity, task completion or flow (Smits, Wenzel & de Bruin, 2025). A meta-analysis of short breaks (up to 10 minutes; 22 samples, N = 2,335) found small benefits for vigour (d = .36) and fatigue (d = .35) and no significant effect on performance overall (d = .16), with gains only on less demanding tasks; longer breaks helped performance more (Albulescu et al., 2022). A recent scoping review is more enthusiastic, but it is single-author, pools nothing, rates its own certainty "moderate to low", and its experimental evidence is essentially the Biwer study (Ogut, 2025). I found no experiment on working adults and none on the 25/5 lengths specifically.

What does have support is finishing or parking a piece of work before switching: people who leave a task unfinished keep thinking about it and do worse on the next one (Leroy, 2009; two experiments), and a short "ready-to-resume" note about where to pick up reduces this (Leroy & Glomb, 2018).

**Fit.** Keep the pomodoro as the unit of estimates, budgets and history; its value in this app is as a container for the outcome, the progress check and the next-step decision. Make work and break lengths configurable. The end-of-pomodoro note doubles as the ready-to-resume note when a step is not finished.

### 3.7 Implementation intentions ("if X, then I will Y")

**Claim.** Deciding in advance when and how you will act makes it more likely you do.

**Evidence: moderate; real but smaller than usually quoted.** The first meta-analysis reported d = .65 across 94 tests (Gollwitzer & Sheeran, 2006). The update, with 642 tests, reports d = .36 overall, finds "substantial" publication bias, and gives a bias-corrected estimate of d = .15 (robust Bayesian method) alongside d = .35 (trim-and-fill); effects were larger with an explicit if-then format, high motivation and at least one rehearsal, and cues tied to a task juncture (starting or ending a phase) worked well (Sheeran, Listrom & Gollwitzer, 2024). Combining if-then plans with imagining the obstacle (mental contrasting) shows g = 0.34 across 21 studies, again with signs of publication bias (Wang, Wang & Gai, 2021).

**Fit.** The principle "the next step is always known" is an implementation intention with a task-juncture cue: "when this pomodoro ends, the next step is…". In iteration 1 this is the "current step in view" plus choosing the next step at the end of the pomodoro. The contingent plan of 3.5 is the same technique applied to interruptions.

### 3.8 Temptation bundling

**Claim.** Pair an unrewarding but valuable activity with something enjoyable, allowed only during it.

**Evidence: weak outside exercise.** The original field experiment (N = 226) found 51% more gym visits at first when audiobooks were available only at the gym, fading within weeks (Milkman, Minson & Volpp, 2014). The larger follow-up (N = 6,792) found that a free audiobook plus encouragement to bundle raised the chance of a weekly workout by 10–14% for up to seventeen weeks, but the encouragement added little over the audiobook alone (Kirgios et al., 2020). Related observational work finds that enjoyment during an activity predicts persistence better than its delayed benefits (Woolley & Fishbach, 2017). All of this is about exercise or studying; I found no trial on knowledge work, where a second stream (an audiobook) would compete with the task for attention.

**Fit.** Not a feature for iteration 1. In iteration 2 the AI could suggest it for key tasks that keep being postponed, using rewards that do not compete with the work (a favourite place, a drink, a particular playlist), and the history can show whether those tasks then get done.

### 3.9 Alternating heavy and light work; which task first

**Claim.** Alternate demanding and easy work to last the day; quick tasks fill the gaps.

**Evidence: none directly, and the usual rationale failed.** The idea that self-control is a resource that runs down with use (ego depletion) did not hold in two preregistered multi-laboratory tests: 23 labs (N = 2,141) found a small effect whose confidence interval included zero (Hagger et al., 2016), and 36 labs (N = 3,531) found d = 0.06, with the data four times more likely under no effect (Vohs et al., 2021). Fatigue itself is real (breaks reduce it, section 3.6), but "a light task restores you for the next heavy one" is not established. The opposite risk is documented: over six years of emergency-department data, physicians under high workload picked easier cases, which looked productive in the short run and was associated with worse complexity-adjusted throughput and less learning; lab studies tied it to fatigue and to the sense of progress that completing easy things gives (KC et al., 2020). On ordering, six experiments (N = 2,013) found that people expect to feel more capable going from easy to hard, while actually doing the hardest task first left them feeling more capable, or no different in one of the three tests (Habbert & Schroeder, 2020; short lab tasks, self-rated confidence).

**Fit.** No alternation rule. Quick tasks keep their place for gaps and for batching, but the day plan should make it hard for them to displace key tasks: place the key task early by default, and let the day summary show key and quick pomodoros separately so the drift is visible.

## 4. What this means for iteration 1

Tied to the iteration 1 list in `IDEA.md`:

- **Task list, title as an outcome, optional steps.** Supported (3.1, 3.2). Add a one-line hint by the title field: checkable, and finishable by you. No validation; a hint is enough.
- **Estimate per task and per step, editable.** Supported (3.4). Store every estimate change with its date. Show the past ratio of actual to estimated pomodoros next to the field as soon as there is history; without AI this is a plain average.
- **Areas with a daily budget.** No research bears on it directly. The interruption finding (3.5) suggests allowing part of a budget to stay unassigned without the app treating it as a gap to fill.
- **The day: declare pomodoros, choose tasks and order.** Supported (3.5). Two cheap additions: default the first key task to the top of the order (3.9), and an optional free-text line for "what could interrupt today".
- **Execution: timer, current step in view.** Current step in view is the best-supported part (3.2, 3.7). Timer lengths configurable, default 25/5 (3.6).
- **End of pomodoro: note, steps completed, estimate updated.** The most evidence-backed moment in the app (3.3). Add one thing: confirm or choose the next step before the break starts (3.7), and when the step is unfinished, the note says where to resume (3.6). Keep it to a few seconds.
- **History and day summary.** Lead with outcomes and steps completed (3.3); show actual against estimate (3.4); show key and quick pomodoros separately (3.9).
- **SQLite schema.** Fields worth having from the start so these ideas can be tested later: estimate history; per pomodoro, whether the step was finished and which next step was chosen; key or quick; whether a task in the day plan was done that day.

Not for iteration 1: temptation bundling (3.8), any automatic alternation of heavy and light work (3.9), any claim in the app's text that pomodoros are proven to increase productivity (3.6).

## 5. Open questions

- **Does a fixed block suit this kind of work?** The two student experiments disagree, and neither covers a full working day. The history could answer it for one user: compare notes and completion on days with different block lengths.
- **How small should a step be?** The evidence supports near-term sub-goals but gives no size. "As small as a quick task" is the working rule; the ratio of steps finished within their estimate will show whether it is right.
- **Does the next-step prompt help or annoy?** The corrected effect of if-then plans is small (d ≈ .15), so the prompt has to cost almost nothing.
- **Morning or evening for the day plan?** Not tested in what I found. The closing-moment question in `IDEA.md` stays open; the detachment finding (Smit, 2016) is one argument for a short evening version.
- **Do one to three "success" tasks beat a longer list?** No direct evidence found.
- **Does temptation bundling transfer to desk work?** Untested; worth a personal experiment in iteration 2, not a feature.
- **The summit.** Out of scope here; the evidence on long-term direction and reflection exercises needs its own research.
- **Not covered:** time of day and energy, notifications and phone distraction, music, sleep. Each could matter more than anything above.

## 6. Sources

How much of each I read is marked: **[full text]**, **[abstract only]** (abstract or publisher record; the full text was paywalled or blocked automated access), **[not verified]**.

Goals, outcomes, steps
- Locke, E. A., & Latham, G. P. (2002). Building a practically useful theory of goal setting and task motivation: A 35-year odyssey. *American Psychologist*, 57(9), 705–717. https://doi.org/10.1037/0003-066X.57.9.705 **[full text]**
- Epton, T., Currie, S., & Armitage, C. J. (2017). Unique effects of setting goals on behavior change: Systematic review and meta-analysis. *Journal of Consulting and Clinical Psychology*, 85(12), 1182–1198. https://doi.org/10.1037/ccp0000260 **[abstract only]**
- Williamson, O., Swann, C., Bennett, K. J. M., Bird, M. D., Goddard, S. G., Schweickle, M. J., & Jackman, P. C. (2022). The performance and psychological effects of goal setting in sport: A systematic review and meta-analysis. *International Review of Sport and Exercise Psychology*. https://doi.org/10.1080/1750984X.2022.2116723 **[abstract only]**
- Höpfner, J., & Keith, N. (2021). Goal missed, self hit: Goal-setting, goal-failure, and their affective, motivational, and behavioral consequences. *Frontiers in Psychology*, 12, 704790. https://doi.org/10.3389/fpsyg.2021.704790 **[abstract only]** (the source for the cost of failing a difficult goal in 3.1)
- Steel, P. (2007). The nature of procrastination: A meta-analytic and theoretical review of quintessential self-regulatory failure. *Psychological Bulletin*, 133(1), 65–94. https://doi.org/10.1037/0033-2909.133.1.65 **[abstract only]**
- Bandura, A., & Schunk, D. H. (1981). Cultivating competence, self-efficacy, and intrinsic interest through proximal self-motivation. *Journal of Personality and Social Psychology*, 41(3), 586–598. https://doi.org/10.1037/0022-3514.41.3.586 **[abstract only]**
- Huang, S.-C., Jin, L., & Zhang, Y. (2017). Step by step: Sub-goals as a source of motivation. *Organizational Behavior and Human Decision Processes*, 141, 1–15. https://doi.org/10.1016/j.obhdp.2017.05.001 **[abstract only]**
- Latham, G. P., & Seijts, G. H. (1999). The effects of proximal and distal goals on performance on a moderately complex task. *Journal of Organizational Behavior*. **[not verified]**: known only through its description in Locke & Latham (2002); title and journal not checked against the publisher record.

Progress
- Harkin, B., Webb, T. L., Chang, B. P. I., Prestwich, A., Conner, M., Kellar, I., Benn, Y., & Sheeran, P. (2016). Does monitoring goal progress promote goal attainment? A meta-analysis of the experimental evidence. *Psychological Bulletin*, 142(2), 198–229. https://doi.org/10.1037/bul0000025 **[abstract only]**
- Amabile, T. M., & Kramer, S. J. (2011). The power of small wins. *Harvard Business Review*, May 2011. https://hbr.org/2011/05/the-power-of-small-wins **[not verified]**: only a truncated summary was accessible; not a peer-reviewed paper.
- Kivetz, R., Urminsky, O., & Zheng, Y. (2006). The goal-gradient hypothesis resurrected: Purchase acceleration, illusionary goal progress, and customer retention. *Journal of Marketing Research*, 43(1), 39–58. https://doi.org/10.1509/jmkr.43.1.39 **[abstract only]**
- Nunes, J. C., & Drèze, X. (2006). The endowed progress effect: How artificial advancement increases effort. *Journal of Consumer Research*, 32(4), 504–512. https://doi.org/10.1086/500480 **[abstract only]**

Estimates
- Buehler, R., Griffin, D., & Ross, M. (1994). Exploring the "planning fallacy": Why people underestimate their task completion times. *Journal of Personality and Social Psychology*, 67(3), 366–381. https://doi.org/10.1037/0022-3514.67.3.366 **[abstract only]**
- Roy, M. M., Christenfeld, N. J. S., & McKenzie, C. R. M. (2005). Underestimating the duration of future events: Memory incorrectly used or memory bias? *Psychological Bulletin*, 131(5), 738–756. https://doi.org/10.1037/0033-2909.131.5.738 **[abstract only]**
- Roy, M. M., Mitten, S. T., & Christenfeld, N. J. S. (2008). Correcting memory improves accuracy of predicted task duration. *Journal of Experimental Psychology: Applied*, 14(3), 266–275. https://doi.org/10.1037/1076-898X.14.3.266 **[abstract only]**
- Halkjelsvik, T., & Jørgensen, M. (2012). From origami to software development: A review of studies on judgment-based predictions of performance time. *Psychological Bulletin*, 138(2), 238–271. https://doi.org/10.1037/a0025996 **[abstract only]**
- Forsyth, D. K., & Burt, C. D. B. (2008). Allocating time to future tasks: The effect of task segmentation on planning fallacy bias. *Memory & Cognition*, 36(4), 791–798. https://doi.org/10.3758/MC.36.4.791 **[abstract only]**
- Kruger, J., & Evans, M. (2004). If you don't want to be late, enumerate: Unpacking reduces the planning fallacy. *Journal of Experimental Social Psychology*, 40(5), 586–598. https://doi.org/10.1016/j.jesp.2003.11.001 **[not verified]**: bibliographic record confirmed, abstract and full text not accessible; no claim above rests on it.

Planning the day
- Parke, M. R., Weinhardt, J. M., Brodsky, A., Tangirala, S., & DeVoe, S. E. (2018). When daily planning improves employee performance: The importance of planning type, engagement, and interruptions. *Journal of Applied Psychology*, 103(3), 300–312. https://doi.org/10.1037/apl0000278 **[abstract only]**
- Aeon, B., Faber, A., & Panaccio, A. (2021). Does time management work? A meta-analysis. *PLOS ONE*, 16(1), e0245066. https://doi.org/10.1371/journal.pone.0245066 **[full text]**
- Masicampo, E. J., & Baumeister, R. F. (2011). Consider it done! Plan making can eliminate the cognitive effects of unfulfilled goals. *Journal of Personality and Social Psychology*, 101(4), 667–683. https://doi.org/10.1037/a0024192 **[abstract only]**
- Smit, B. W. (2016). Successfully leaving work at work: The self-regulatory underpinnings of psychological detachment. *Journal of Occupational and Organizational Psychology*, 89(3), 493–514. https://doi.org/10.1111/joop.12137 **[abstract only]**

Pomodoro, breaks, switching
- Biwer, F., Wiradhany, W., oude Egbrink, M. G. A., & de Bruin, A. B. H. (2023). Understanding effort regulation: Comparing "Pomodoro" breaks and self-regulated breaks. *British Journal of Educational Psychology*, 93(S2), 353–367. https://doi.org/10.1111/bjep.12593 **[abstract only]**
- Smits, E. J. C., Wenzel, N., & de Bruin, A. (2025). Investigating the effectiveness of self-regulated, Pomodoro, and Flowtime break-taking techniques among students. *Behavioral Sciences*, 15(7), 861. https://doi.org/10.3390/bs15070861 **[full text]**
- Albulescu, P., Macsinga, I., Rusu, A., Sulea, C., Bodnaru, A., & Tulbure, B. T. (2022). "Give me a break!" A systematic review and meta-analysis on the efficacy of micro-breaks for increasing well-being and performance. *PLOS ONE*, 17(8), e0272460. https://doi.org/10.1371/journal.pone.0272460 **[full text]**
- Ogut, E. (2025). Assessing the efficacy of the Pomodoro technique in enhancing anatomy lesson retention during study sessions: A scoping review. *BMC Medical Education*, 25, 1440. https://doi.org/10.1186/s12909-025-08001-0 **[full text]**
- Leroy, S. (2009). Why is it so hard to do my work? The challenge of attention residue when switching between work tasks. *Organizational Behavior and Human Decision Processes*, 109(2), 168–181. https://doi.org/10.1016/j.obhdp.2009.04.002 **[abstract only]**
- Leroy, S., & Glomb, T. M. (2018). Tasks interrupted: How anticipating time pressure on resumption of an interrupted task causes attention residue and low performance on interrupting tasks and how a "ready-to-resume" plan mitigates the effects. *Organization Science*, 29(3), 380–397. https://doi.org/10.1287/orsc.2017.1184 **[abstract only]**

If-then plans
- Gollwitzer, P. M., & Sheeran, P. (2006). Implementation intentions and goal achievement: A meta-analysis of effects and processes. *Advances in Experimental Social Psychology*, 38, 69–119. https://doi.org/10.1016/S0065-2601(06)38002-1 **[abstract only]**
- Sheeran, P., Listrom, O., & Gollwitzer, P. M. (2024). The when and how of planning: Meta-analysis of the scope and components of implementation intentions in 642 tests. *European Review of Social Psychology*, 36(1), 162–194. https://doi.org/10.1080/10463283.2024.2334563 **[full text of the accepted manuscript]**, from the university repository: https://doi.org/10.17615/mmbd-f786
- Wang, G., Wang, Y., & Gai, X. (2021). A meta-analysis of the effects of mental contrasting with implementation intentions on goal attainment. *Frontiers in Psychology*, 12, 565202. https://doi.org/10.3389/fpsyg.2021.565202 **[abstract only]**

Temptation bundling and immediate rewards
- Milkman, K. L., Minson, J. A., & Volpp, K. G. M. (2014). Holding the Hunger Games hostage at the gym: An evaluation of temptation bundling. *Management Science*, 60(2), 283–299. https://doi.org/10.1287/mnsc.2013.1784 **[abstract only]**
- Kirgios, E. L., Mandel, G. H., Park, Y., Milkman, K. L., Gromet, D. M., Kay, J. S., & Duckworth, A. L. (2020). Teaching temptation bundling to boost exercise: A field experiment. *Organizational Behavior and Human Decision Processes*, 161 (Suppl.), 20–35. https://doi.org/10.1016/j.obhdp.2020.09.003 **[full text]**
- Woolley, K., & Fishbach, A. (2017). Immediate rewards predict adherence to long-term goals. *Personality and Social Psychology Bulletin*, 43(2), 151–162. https://doi.org/10.1177/0146167216676480 **[abstract only]**

Heavy and light work, task order
- Hagger, M. S., Chatzisarantis, N. L. D., et al. (2016). A multilab preregistered replication of the ego-depletion effect. *Perspectives on Psychological Science*, 11(4), 546–573. https://doi.org/10.1177/1745691616652873 **[abstract only]**
- Vohs, K. D., Schmeichel, B. J., et al. (2021). A multisite preregistered paradigmatic test of the ego-depletion effect. *Psychological Science*, 32(10), 1566–1581. https://doi.org/10.1177/0956797621989733 **[abstract only]**
- KC, D. S., Staats, B. R., Kouchaki, M., & Gino, F. (2020). Task selection and workload: A focus on completing easy tasks hurts performance. *Management Science*, 66(10), 4397–4416. https://doi.org/10.1287/mnsc.2019.3419 **[abstract only]**
- Habbert, R., & Schroeder, J. (2020). To build efficacy, eat the frog first: People misunderstand how the difficulty-ordering of tasks influences efficacy. *Journal of Experimental Social Psychology*, 91, 104032. https://doi.org/10.1016/j.jesp.2020.104032 **[full text]**

Notes on reliability
- Authors, year, title, journal, volume and pages were checked against each DOI's registration record (Crossref), except the volume of Gollwitzer & Sheeran (2006), which that record did not list. Issue numbers in parentheses were mostly not in those records and are **[not verified]**. Every DOI above resolved to the paper named.
- Effect sizes quoted from **[abstract only]** sources are the ones stated in the abstract; I could not check how they were computed or what the authors list as limitations.
