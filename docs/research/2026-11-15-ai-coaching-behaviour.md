# Research: how to give the AI its coaching behaviour

> Date: 2026-11-15 · Issue: #3 "Research: how to give the AI its coaching behaviour". Related: #2 (where the MCP server lives, language, transports, size of the summary), researched separately and not covered here.
> Primary sources only, cited for every claim and all opened on 2026-11-15; what I could not verify is marked **[not verified]**. Client support changes fast: every statement about a client is "as documented on 2026-11-15".
> Protocol version observed: MCP (Model Context Protocol) specification **2026-07-28**, marked "current" ([versioning](https://modelcontextprotocol.io/specification/versioning)).

## 1. Outcome in brief

There is no single form that fits. I recommend three layers, all shipped **inside the app's MCP server** so that they update together with the app and never drift from the tools they talk about:

1. **Tools carry the rules that must always hold.** The app validates every write (a step has an outcome and an estimate, a day plan fits the budget) and answers with an error that says what to fix. Tools are the only MCP feature every client supports, and a rule in prose is "a request, not a guarantee" ([Claude Code, Extend Claude Code](https://code.claude.com/docs/en/features-overview)).
2. **Server instructions carry a short orientation**: what the app is, the glossary terms, "read the summary first". A few hundred characters, because clients cut them (section 3.2).
3. **Each kind of AI session gets a written procedure** (below: *playbook*; the term is not in `GLOSSARY.md` yet), stored as one Markdown file per behaviour in the Agent Skills layout (`SKILL.md` plus reference files) and served by the MCP server as an **MCP prompt**, which is the feature designed for "the user explicitly picks a workflow". For clients whose documentation does not mention prompts, the same text is returned by a tool. Later, the same files can be installed as agent skills or served through the new "Skills over MCP" extension without rewriting them.

Plain instruction files (`AGENTS.md`, `CLAUDE.md`) are the wrong home for coaching behaviour: they are tied to a folder, load in full on every request, and are meant for "always do X" project rules. Agent skills are the best *format* (loaded only when needed, widest client support for instructions) but the worst *distribution* for a Mac app today: they live in per-client folders outside the app, or are uploaded by hand as a zip, and update separately from the tools.

| Coaching behaviour | Who starts it | Recommended form | Why |
|---|---|---|---|
| Breaking down a key task into steps | The user ("break this down"), or the AI when it sees a key task without steps | Rule in the tools (the "split task" tool rejects steps without an outcome or an estimate, with an error that explains) + playbook as MCP prompt with the task as argument + one line in the tool description saying when to use it | The rule must hold every time, so it belongs in validation. The "how to break down well" part is judgement and is only needed when it happens, so it loads on demand. |
| Applying a focus technique | The AI, while planning or breaking down | One short reference file per technique, loaded on demand (reference files of the planning playbook; a tool or resource that returns one technique). Techniques that are mechanical become app features, not text. | It is reference knowledge needed sometimes. Always-on text would cost tokens on every request and add noise. |
| Finding the summit | The user, rarely, in a dedicated reflection AI session | MCP prompt (user-triggered) holding the interview script; the summit itself is data stored by the app and returned inside the summary | Long text used a few times a year: zero cost until invoked. The result must reach every later AI session, so it is data, not instructions. |
| Morning planning (the day plan) | The user or the app, every morning | MCP prompt whose answer embeds today's summary next to the playbook (a prompt can embed resources) | A prompt is assembled by the server at the moment it is requested, so procedure and fresh data arrive in one message. |
| Tidying the list | The user, as an AI session task | MCP prompt; same mechanism as morning planning | Same reasons. One prompt per kind of AI session maps one-to-one to the "AI session as a task type" idea in `IDEA.md`. |

Main uncertainty: how well MCP prompts are surfaced by the client the author will actually use. Claude Code, the Claude apps, Cursor and Gemini CLI document them; the Codex / ChatGPT documentation and the VS Code page I opened do not mention them (section 4). That is why the fallback tool exists.

## 2. The forms compared

"Trigger" is who decides that the content enters the conversation. "Cost" is what occupies the model's context.

| Form | What it is, per its specification | Trigger | How it loads, and cost |
|---|---|---|---|
| **MCP tools** | Functions a server exposes, each with `name`, `description`, `inputSchema`, optional `outputSchema` ([spec, tools](https://modelcontextprotocol.io/specification/2026-07-28/server/tools)) | **Model**: "model-controlled" | Definitions are sent with the request unless the client defers them; results enter the context when called. Claude Code defers by default: "Only tool names and server instructions load at session start" ([Claude Code, MCP](https://code.claude.com/docs/en/mcp)) |
| **Server instructions** | `instructions`: "Optional natural-language guidance for LLMs on how to use this server effectively", returned by `server/discover` ([spec, discovery](https://modelcontextprotocol.io/specification/2026-07-28/server/discover)) | **Application**: the client decides whether and how to pass it on | Every session, in full or cut. The spec does not say what a client must do with it. |
| **MCP prompts** | "prompt templates" with arguments; `prompts/get` returns ready-made messages ([spec, prompts](https://modelcontextprotocol.io/specification/2026-07-28/server/prompts)) | **User**: "user-controlled … the user being able to explicitly select them" | Nothing until the user invokes one; then the whole text enters as messages. |
| **MCP resources** | Data identified by a URI that "provides context to language models" ([spec, resources](https://modelcontextprotocol.io/specification/2026-07-28/server/resources)) | **Application**: "application-driven" (a picker, an @-mention, or automatic inclusion) | Nothing until attached or read. |
| **Agent skills** | "a folder containing a `SKILL.md` file" with `name` and `description`, plus optional scripts and reference files ([Agent Skills overview](https://agentskills.io/home), [specification](https://agentskills.io/specification)) | **Model** (matches the task to the description) or **user** (`/name`) | Three stages: metadata "~100 tokens" always; body "< 5000 tokens recommended" on activation; other files only when read ([specification](https://agentskills.io/specification)) |
| **Instruction files** (`AGENTS.md`, `CLAUDE.md`) | A Markdown file in a folder; `AGENTS.md` is "a simple, open format for guiding coding agents" ([agents.md](https://agents.md/)) | **Application**: loaded automatically for sessions started in that folder | Full content on every request ([Claude Code, Extend Claude Code](https://code.claude.com/docs/en/features-overview)) |

## 3. Findings: each form in detail

### 3.1 MCP tools: descriptions and results

A tool's description and schema are the only instructions guaranteed to reach the model in every client, because tools are what every client implements (section 4). Two mechanisms make tools carry behaviour:

- **The description says when to use the tool.** Anthropic calls detailed descriptions "by far the most important factor in tool performance" and asks for "at least 3–4 sentences" covering what the tool does, when to use it and when not ([Define tools](https://platform.claude.com/docs/en/agents-and-tools/tool-use/define-tools)).
- **The result steers the next move.** The spec separates protocol errors from tool execution errors, which "contain actionable feedback that language models can use to self-correct and retry", and says clients "SHOULD provide tool execution errors to language models" ([spec, tools](https://modelcontextprotocol.io/specification/2026-07-28/server/tools)). Example: the AI calls "split task" with a step titled "work on the offer"; the app answers with `isError: true` and "A step is written as an outcome, for example 'Draft offer sent to the client'". The rule is applied whether or not the AI read any playbook.

Returning a playbook as the result of a tool (the fallback in section 1) uses only standard pieces, a text result, but it is my design inference: I found no first-party page that recommends it by name. The closest standardised version is the Skills extension (section 3.5).

Limits: Claude Code cuts the description of a tool that loads upfront at 4,096 characters, and warns when a tool result exceeds 10,000 tokens ([Claude Code, MCP](https://code.claude.com/docs/en/mcp)). Annotations on tools are hints that clients must treat as untrusted ([spec, tools](https://modelcontextprotocol.io/specification/2026-07-28/server/tools)).

### 3.2 Server instructions

In the current specification there is no `initialize` handshake any more; `instructions` is a field of the answer to `server/discover`, which servers must implement but clients may skip ([spec, discovery](https://modelcontextprotocol.io/specification/2026-07-28/server/discover), [versioning and compatibility](https://modelcontextprotocol.io/specification/2026-07-28/basic/versioning)). In the previous revision (2025-11-25) it is a field of the `initialize` result ([lifecycle, 2025-11-25](https://modelcontextprotocol.io/specification/2025-11-25/basic/lifecycle)). This matters because the official Swift SDK implements 2025-11-25 according to its README; it does accept an `instructions` parameter when the server is created (`Sources/MCP/Server/Server.swift`, release 0.12.1) ([Swift SDK](https://github.com/modelcontextprotocol/swift-sdk)).

What clients do with it:

- **Claude Code** loads it at session start and cuts it at 4,096 characters ("Claude sees only the text before the cut"); the limit was 2,048 before v2.1.296. It advises server authors to explain "what category of tasks your tools handle" and "when Claude should search for your tools" ([Claude Code, MCP](https://code.claude.com/docs/en/mcp)).
- **Codex and ChatGPT** read it and use it "alongside tool metadata"; OpenAI advises keeping the most important details in the first 512 characters and adds "Do not repeat every tool description" ([OpenAI, MCP](https://learn.chatgpt.com/docs/extend/mcp?surface=cli), [OpenAI, build an MCP server for a plugin](https://developers.openai.com/plugins/build/mcp-server)).
- **Gemini CLI** appends it to the system instructions ([Gemini CLI, MCP servers](https://geminicli.com/docs/tools/mcp-server/)).
- **Claude desktop and web apps, Cursor, VS Code**: the pages I opened do not mention it. **[not verified]**

Consequence: write it as if only the first 500 characters arrive, and never put a behaviour there that is not also enforced or reachable another way.

### 3.3 MCP prompts

A prompt has a name, a description and arguments; the server builds the messages when the client calls `prompts/get`, and those messages may embed resources ("Embedded resources enable prompts to seamlessly incorporate server-managed content") ([spec, prompts](https://modelcontextprotocol.io/specification/2026-07-28/server/prompts)). The MCP documentation describes them as "Pre-built instruction templates that tell the model to work with specific tools and resources", "requiring explicit invocation rather than automatic triggering" ([Understanding MCP servers](https://modelcontextprotocol.io/docs/2026-07-28/learn/server-concepts)).

That is exactly the shape of an AI session in this project: the user (or the app, when a pomodoro on an AI session task starts) chooses "morning planning", and the server answers with the playbook plus today's summary. In Claude Code the prompt appears as `/servername:promptname (MCP)` and also runs as `/mcp__servername__promptname`, with arguments after the name ([Claude Code, MCP](https://code.claude.com/docs/en/mcp)).

The limit is the trigger: the model cannot decide by itself to load a prompt. Behaviour that the AI should start on its own initiative (noticing that a key task has no steps) cannot live only in a prompt.

### 3.4 MCP resources

Resources are data, and the host application decides how they reach the model: a picker, a search, or "automatic context inclusion, based on heuristics or the AI model's selection" ([spec, resources](https://modelcontextprotocol.io/specification/2026-07-28/server/resources)). In Claude Code the user attaches one by typing `@server:protocol://path` ([Claude Code, MCP](https://code.claude.com/docs/en/mcp)).

For this project they fit **data the user may want to attach by hand** (the summit, today's summary) and the **reference files of a playbook** (one focus technique). They do not fit behaviour: no client I checked documents that the model reads resources on its own initiative, so anything the AI must be able to fetch by itself also needs a tool. **[not verified for clients other than those in section 4]**

### 3.5 Agent skills

The format: a folder named like the skill, with a `SKILL.md` whose front matter has `name` (max 64 characters) and `description` (max 1,024 characters, "what the skill does and when to use it"), and a body that should stay "under 500 lines"; extra files go in `references/`, `scripts/`, `assets/` and are read only when needed ([specification](https://agentskills.io/specification)). The format "was originally developed by Anthropic, released as an open standard" ([overview](https://agentskills.io/home)).

Cost and trigger in practice:

- Claude Code keeps a listing of names and descriptions in context, with a budget of 1% of the context window and at most 1,536 characters per skill; the body loads when the user types `/name` or when Claude matches the description. `disable-model-invocation: true` makes a skill user-only and keeps even its description out of context. Once loaded, the text is not re-read on later turns, and after the conversation is compacted only the first 5,000 tokens of each skill are kept ([Claude Code, skills](https://code.claude.com/docs/en/skills)).
- Codex loads only names, descriptions and paths at first, using "at most 2% of the model's context window, or 8,000 characters" ([OpenAI, skills](https://learn.chatgpt.com/docs/build-skills)).

Skills assume the AI can read files. In the Claude apps they require code execution to be enabled ([Claude Help Center, using skills](https://support.claude.com/en/articles/12512180-using-skills-in-claude)).

**Skills over MCP.** An official MCP extension (`io.modelcontextprotocol/skills`, SEP-2640 marked Final) lets a server list skills (`skills/list`) and serve their files as resources under `skill://` URIs; the host verifies each file against a manifest of SHA-256 digests and may ask the user for approval ([Skills extension](https://modelcontextprotocol.io/extensions/skills/overview)). It would give exactly what this project wants (skills bundled in the server), but "SDK and host support is still being implemented": in the support matrix the Skills column is empty for the Claude clients, Cursor and VS Code, and "Partial" for ChatGPT ([extension support matrix](https://modelcontextprotocol.io/extensions/client-matrix)). VS Code documents it as an experimental setting, off by default (`chat.agentHost.mcpSkills.enabled`) ([VS Code, agent skills](https://code.visualstudio.com/docs/agent-customization/agent-skills)). Not usable as the main path today; worth being ready for, which is why section 1 recommends storing playbooks in the skills layout.

### 3.6 Instruction files (`AGENTS.md`, `CLAUDE.md`)

They load automatically, in full, at the start of every session opened in their folder. Claude Code: "target under 200 lines per CLAUDE.md file. Longer files consume more context and reduce adherence", and a multi-step procedure should move "to a skill" ([Claude Code, memory](https://code.claude.com/docs/en/memory)). Claude Code reads `AGENTS.md` when no `CLAUDE.md` is present (v2.1.277 or later) ([same page](https://code.claude.com/docs/en/memory)). Codex builds the chain of `AGENTS.md` files once per run and stops at 32 KiB ([OpenAI, AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md)). `AGENTS.md` is stewarded by the Agentic AI Foundation under the Linux Foundation ([agents.md](https://agents.md/)).

They only make sense for this app if the app owns a folder and opens the AI tool there (section 5.4). Even then they should hold a few always-true lines, not the playbooks. A Claude Code plugin cannot ship one: "Claude Code doesn't load a `CLAUDE.md` at the plugin root" ([Claude Code, plugin components](https://code.claude.com/docs/en/plugins/components)).

## 4. Findings: what the clients support today

Observed on 2026-11-15 in first-party documentation. "Not mentioned" means the page I opened is silent, not that the feature is absent. The MCP site used to publish a feature matrix of clients; the address `modelcontextprotocol.io/clients` now shows the introduction page, and the documentation index lists only the matrix of *extensions*, so there is no longer a neutral table to rely on.

| Client | Tools | Server instructions | Prompts | Resources | Agent skills |
|---|---|---|---|---|---|
| **Claude Code** (terminal; docs mention versions up to v2.1.310) | Yes, deferred by default | Yes, cut at 4,096 characters | Yes, as slash commands | Yes, `@` mentions | Yes: `~/.claude/skills/`, project `.claude/skills/`, plugins |
| **Claude desktop and web apps** | Yes | Not mentioned **[not verified]** | Yes, from the attachment menu of a connector | Yes, same menu | Yes, uploaded as a zip in Customize > Skills; needs code execution |
| **Codex CLI, IDE extension, ChatGPT desktop app** | Yes | Yes; first 512 characters matter most | Not mentioned **[not verified]** | Not mentioned **[not verified]** | Yes: `~/.agents/skills/`, repository `.agents/skills/` |
| **VS Code (GitHub Copilot)**, docs dated 2026-11-11 | Yes | Not mentioned **[not verified]** | Not on the page I opened **[not verified]** | Not on the page I opened **[not verified]** | Yes: `~/.copilot/skills/`, and it also reads `.claude/skills/` and `.agents/skills/` |
| **Cursor** | Yes | Not mentioned **[not verified]** | Yes ("Supported") | Yes ("Supported") | Yes: `~/.agents/skills/`, `~/.cursor/skills/`, and it also reads `~/.claude/skills/` |
| **Gemini CLI** | Yes | Yes, appended to the system instructions | Yes, as slash commands | Yes, `@` syntax | Not checked |

Sources, in row order: [Claude Code, MCP](https://code.claude.com/docs/en/mcp) and [skills](https://code.claude.com/docs/en/skills); [Connect to remote MCP servers](https://modelcontextprotocol.io/docs/2026-07-28/develop/connect-remote-servers), [Agent Skills overview (Claude platform)](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) and [Claude Help Center](https://support.claude.com/en/articles/12512180-using-skills-in-claude); [OpenAI, MCP](https://learn.chatgpt.com/docs/extend/mcp?surface=cli) and [skills](https://learn.chatgpt.com/docs/build-skills); [VS Code, MCP servers](https://code.visualstudio.com/docs/agent-customization/mcp-servers) and [agent skills](https://code.visualstudio.com/docs/agent-customization/agent-skills); [Cursor, MCP](https://cursor.com/docs/context/mcp) and [skills](https://cursor.com/docs/context/skills); [Gemini CLI, MCP servers](https://geminicli.com/docs/tools/mcp-server/).

Caveats:

- **Claude apps**: the prompt-and-resource menu is documented for a remote server added as a custom connector. That a local server gets the same menu is likely but **[not verified]**.
- **VS Code**: the MCP page states only that "The Local harness is deprecated and will be removed in February 2027". A search-result summary (not a page I opened) says the `/mcp.server.prompt` commands belong to that deprecated harness and that skills are recommended instead. **[not verified]**
- **Gemini CLI**: the page carries a banner saying Gemini CLI "was replaced by Antigravity CLI on June 18th, 2026"; treat the row as possibly outdated. I did not check Antigravity CLI.
- **Skills client list**: the Agent Skills site has a "Client Showcase" page, but its list is not present in the page text I could fetch, so I rely on each vendor's own page. **[showcase list not verified]**
- **Custom skills do not sync** between Claude surfaces: "Skills uploaded to claude.ai must be separately uploaded to the API", and "Claude Code Skills are filesystem-based and separate from both" ([Agent Skills overview (Claude platform)](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)). The Claude Code page does list "Skills enabled for your claude.ai account" as loading in terminal sessions signed in with that account ([Claude Code, skills](https://code.claude.com/docs/en/skills)).

Reading the table: tools are the only column that is "yes" everywhere. Agent skills are the widest-supported way to ship *instructions*, and `~/.claude/skills/` is read by three of the clients. Prompts and server instructions are each documented by about half.

## 5. Findings: distribution and updates

### 5.1 Bundled in the MCP server (recommended base)

Tool descriptions, server instructions, prompts and resources are all produced by the server process. If the client's configuration points at an executable that ships inside the app, a new app version changes them all at once, with nothing to install twice. When the lists change while connected, a server can send `list_changed` notifications ([spec, prompts](https://modelcontextprotocol.io/specification/2026-07-28/server/prompts)); Claude Code then "fetches the updated list from that server, so you don't need to reconnect it" ([Claude Code, MCP](https://code.claude.com/docs/en/mcp)).

What is still per client is the one-time registration: `claude mcp add` (user scope is stored in `~/.claude.json`) ([Claude Code, MCP](https://code.claude.com/docs/en/mcp)); `claude_desktop_config.json` in `~/Library/Application Support/Claude/`, followed by a restart ([Connect to local MCP servers](https://modelcontextprotocol.io/docs/2026-07-28/develop/connect-local-servers)); `codex mcp add`, written to `~/.codex/config.toml`, which the ChatGPT desktop app, Codex CLI and IDE extension share ([OpenAI, MCP](https://learn.chatgpt.com/docs/extend/mcp?surface=cli)); `~/.cursor/mcp.json` ([Cursor, MCP](https://cursor.com/docs/context/mcp)). Where the server process lives and how it is launched is issue #2.

### 5.2 MCP Bundle (`.mcpb`) for the Claude desktop app

An MCP Bundle (formerly "desktop extension", `.dxt`) is a zip with a local server and a `manifest.json`; server types are `node`, `python`, `binary` and `uv`, and the manifest can list the server's tools and prompts ([MCPB](https://github.com/modelcontextprotocol/mcpb), [manifest](https://github.com/modelcontextprotocol/mcpb/blob/main/MANIFEST.md)). Updates: extensions from Anthropic's directory update automatically; for privately distributed ones "users will need to install updated .mcpb files manually" ([Claude Help Center, local MCP servers](https://support.claude.com/en/articles/10949351-getting-started-with-local-mcp-servers-on-claude-desktop)). A bundle therefore updates separately from the Mac app unless it only contains a thin launcher for the executable inside the app; whether that is practical is **[not verified]** and belongs with #2.

### 5.3 Claude Code plugin and marketplace

A plugin "bundles skills, hooks, subagents, and MCP servers into a single installable unit" ([Claude Code, Extend Claude Code](https://code.claude.com/docs/en/features-overview)); its `.mcp.json` can start a local server with `${CLAUDE_PLUGIN_ROOT}`, and it can also point at an `.mcpb` file ([plugin components](https://code.claude.com/docs/en/plugins/components)). A marketplace is a directory or git repository with `.claude-plugin/marketplace.json`; users run `/plugin marketplace add owner/repo` and `/plugin install name@marketplace` ([create a marketplace](https://code.claude.com/docs/en/plugins/create-marketplace)). This public repository could be its own marketplace.

Updates are the weak point: "Background auto-update is off for your marketplace by default, and `marketplace.json` has no field to turn it on"; users get a new copy only when the plugin's version changes ([host a marketplace](https://code.claude.com/docs/en/plugins/host-marketplace)). One documented exception fits a Mac app well: a marketplace added **from a local directory** is read in place, so "Users see your edits when they next start a session or run `/reload-plugins`, without an update step or a version bump" ([same page](https://code.claude.com/docs/en/plugins/host-marketplace)). The app could write a plugin folder to a known location and ask the user to add it once. This covers Claude Code only; plugin skills are namespaced (`/plugin-name:skill-name`).

### 5.4 Files the app writes to a known folder

Two variants, both documented on the client side:

- **Into the user's skills folders.** Claude Code watches `~/.claude/skills/` and "picks up the change within the current session, without a restart" ([Claude Code, skills](https://code.claude.com/docs/en/skills)); "Codex detects skill changes automatically" in `~/.agents/skills/` ([OpenAI, skills](https://learn.chatgpt.com/docs/build-skills)). The app can refresh the files at every launch. Costs: the app writes into configuration folders it does not own (needs the user's consent, and a sandboxed Mac app could not do it, **[not verified]**), and the Claude apps are not reached (zip upload only).
- **Into a folder the app owns, opened as the AI tool's project.** `IDEA.md` already imagines that the app "opens the AI tool on the right project". That folder can hold `.claude/skills/`, `.agents/skills/`, a short `AGENTS.md`, and a project `.mcp.json`. Nothing outside the app's own folders is touched. Limits: Claude Code "prompts for approval … before using project-scoped servers from `.mcp.json` files" ([Claude Code, MCP](https://code.claude.com/docs/en/mcp)), Codex reads a project's configuration only for trusted projects ([OpenAI, MCP](https://learn.chatgpt.com/docs/extend/mcp?surface=cli)), and chat apps without a working folder are not reached.

### 5.5 Summary

| Mechanism | Reaches | Stays current by | Main cost |
|---|---|---|---|
| Inside the MCP server | Every client (tools); about half (prompts, instructions) | Updating the app | One registration per client |
| `.mcpb` bundle | Claude desktop app | Manual reinstall, unless listed in Anthropic's directory | Second artefact to release |
| Claude Code plugin from a local folder | Claude Code | The app rewriting the folder | One command by the user; Claude Code only |
| Skills written to user folders | Claude Code, Codex, Cursor, VS Code | The app rewriting the files | Writing outside the app's folders |
| App-owned project folder | Clients that work in a folder | The app rewriting the folder | Approval prompts; no chat apps |
| Skills over MCP extension | Almost no client yet | Updating the app | Not usable today |

## 6. General lessons for instructing agents

These follow from the sources above and apply beyond this app.

1. **Choose the form by who triggers it and how often it is needed.** Always needed, a few lines: an always-on form (instruction file, server instructions). Needed sometimes: an on-demand form (skill, prompt). Claude Code's own rule: put it in `CLAUDE.md` "if Claude should always know it", in a skill "if it's reference material Claude needs sometimes" ([Extend Claude Code](https://code.claude.com/docs/en/features-overview)).
2. **What must always happen is code, not prose.** "An instruction like 'never edit `.env`' in CLAUDE.md or a skill is a request, not a guarantee" ([same page](https://code.claude.com/docs/en/features-overview)). For an MCP server the equivalent of a hook is validation inside the tool.
3. **Context is shared and finite.** "The context window is a public good"; ask of each paragraph "Does Claude really need this explanation?" ([skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)). Too much always-on text makes the agent worse, not only more expensive: "skills may not trigger correctly, or Claude may lose track of your conventions" ([Extend Claude Code](https://code.claude.com/docs/en/features-overview)).
4. **The description is the trigger.** For a skill it must say "both what the Skill does and when to use it", in the third person, with the words a user would say ([best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)). For a tool, the same: what it does, when to use it and when not ([Define tools](https://platform.claude.com/docs/en/agents-and-tools/tool-use/define-tools)).
5. **Put the important part first.** Every client cuts: 4,096 characters for server instructions in Claude Code, 512 characters that matter most in Codex, 1,536 characters per skill description, the first 5,000 tokens of a skill after compaction (sections 3.2 and 3.5).
6. **Match the strictness to the fragility.** Give "general direction" where many paths work and "exact instructions" where one mistake breaks things ([best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)). Breaking down a key task is the first kind; writing to the database is the second, and is the app's job.
7. **Explain why, show an example, say what to do.** "Think of Claude as a brilliant but new employee who lacks context"; give "context or motivation behind your instructions"; "Tell Claude what to do instead of what not to do" ([prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)).
8. **Do not shout.** With current models, aggressive wording causes overtriggering: instead of "CRITICAL: You MUST use this tool when...", write "Use this tool when..." ([same page](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)).
9. **Few tools, high-signal results.** "More tools don't always lead to better outcomes"; return only what the agent needs for its next step, and make errors "specific and actionable" ([Writing tools for agents](https://www.anthropic.com/engineering/writing-tools-for-agents), published 2025-09-11; [Define tools](https://platform.claude.com/docs/en/agents-and-tools/tool-use/define-tools)). This is the same principle as the summary in `IDEA.md`.
10. **One vocabulary.** "Choose one term and use it throughout" ([best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)). Tool names, descriptions, playbooks and server instructions should use the `GLOSSARY.md` terms and nothing else.
11. **Test before writing more.** "Create evaluations BEFORE writing extensive documentation": run the agent without the instructions, note where it fails, write the minimum that fixes it ([best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)). This matches the principle in `IDEA.md` that where AI helps "has to be proven in practice".
12. **Treat shipped instructions as software.** A skill "can direct Claude to call tools or run code", so it deserves the care of installing software ([Agent Skills overview (Claude platform)](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)); the Skills extension binds the user's approval to file digests for the same reason ([Skills extension](https://modelcontextprotocol.io/extensions/skills/overview)).

## 7. Open questions

- **Which AI client comes first?** The recommendation changes at the edges with the answer: prompts are well surfaced in Claude Code, less certain elsewhere. The project works "for its author first", so the author's client decides what to test.
- **Does a prompt or a tool-returned playbook actually produce better AI sessions than no playbook?** Nothing here measures quality. Lesson 11 suggests trying each behaviour without instructions first.
- **Can the app start a prompt by itself** when a pomodoro on an AI session task begins (for example by launching the AI tool with a slash command)? Not researched; depends on #2 and on each client's launch options.
- **Do the Claude desktop and web apps, Cursor and VS Code pass server instructions to the model?** Not documented on the pages opened; a five-minute test with a server whose instructions contain a marker phrase would settle it.
- **Does the model fetch resources on its own initiative in any client?** If not, focus techniques need a tool, not a resource.
- **Which specification revision will the server speak?** The Swift SDK README says 2025-11-25, where `instructions` travels in `initialize`; the current revision is 2026-07-28. Belongs with #2.
- **Is "playbook" the right glossary term** for the written procedure of one kind of AI session, or should `GLOSSARY.md` name it differently?
- **Which focus techniques exist and which are mechanical** (app features) rather than judgement (text for the AI)? That is the focus-science research, not this one.
- **Is writing into `~/.claude/skills/` or `~/.agents/skills/` acceptable** for this app, and possible given how it is packaged?

## 8. Sources

- MCP, versioning: https://modelcontextprotocol.io/specification/versioning · versioning and compatibility (2026-07-28): https://modelcontextprotocol.io/specification/2026-07-28/basic/versioning
- MCP spec 2026-07-28, tools: https://modelcontextprotocol.io/specification/2026-07-28/server/tools · prompts: https://modelcontextprotocol.io/specification/2026-07-28/server/prompts · resources: https://modelcontextprotocol.io/specification/2026-07-28/server/resources · discovery: https://modelcontextprotocol.io/specification/2026-07-28/server/discover
- MCP spec 2025-11-25, lifecycle: https://modelcontextprotocol.io/specification/2025-11-25/basic/lifecycle
- MCP docs, Understanding MCP servers: https://modelcontextprotocol.io/docs/2026-07-28/learn/server-concepts · client best practices: https://modelcontextprotocol.io/docs/2026-07-28/develop/clients/client-best-practices · connect local servers: https://modelcontextprotocol.io/docs/2026-07-28/develop/connect-local-servers · connect remote servers: https://modelcontextprotocol.io/docs/2026-07-28/develop/connect-remote-servers · build with agent skills: https://modelcontextprotocol.io/docs/2026-07-28/develop/build-with-agent-skills · documentation index: https://modelcontextprotocol.io/llms.txt
- MCP, Skills extension: https://modelcontextprotocol.io/extensions/skills/overview · extension support matrix: https://modelcontextprotocol.io/extensions/client-matrix
- MCP Bundles: https://github.com/modelcontextprotocol/mcpb · manifest: https://github.com/modelcontextprotocol/mcpb/blob/main/MANIFEST.md
- MCP Swift SDK: https://github.com/modelcontextprotocol/swift-sdk
- Agent Skills, overview: https://agentskills.io/home · specification: https://agentskills.io/specification · client showcase: https://agentskills.io/clients
- AGENTS.md: https://agents.md/
- Claude platform, Agent Skills overview: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview · skill authoring best practices: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices · define tools: https://platform.claude.com/docs/en/agents-and-tools/tool-use/define-tools · prompting best practices: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
- Anthropic, Writing tools for agents: https://www.anthropic.com/engineering/writing-tools-for-agents
- Claude Code, MCP: https://code.claude.com/docs/en/mcp · skills: https://code.claude.com/docs/en/skills · memory: https://code.claude.com/docs/en/memory · Extend Claude Code: https://code.claude.com/docs/en/features-overview · plugin components: https://code.claude.com/docs/en/plugins/components · create a marketplace: https://code.claude.com/docs/en/plugins/create-marketplace · host a marketplace: https://code.claude.com/docs/en/plugins/host-marketplace
- Claude Help Center, local MCP servers on Claude Desktop: https://support.claude.com/en/articles/10949351-getting-started-with-local-mcp-servers-on-claude-desktop · using skills: https://support.claude.com/en/articles/12512180-using-skills-in-claude
- OpenAI, skills: https://learn.chatgpt.com/docs/build-skills · MCP: https://learn.chatgpt.com/docs/extend/mcp?surface=cli · AGENTS.md: https://learn.chatgpt.com/docs/agent-configuration/agents-md · build an MCP server for a plugin: https://developers.openai.com/plugins/build/mcp-server
- VS Code, MCP servers: https://code.visualstudio.com/docs/agent-customization/mcp-servers · agent skills: https://code.visualstudio.com/docs/agent-customization/agent-skills
- Cursor, MCP: https://cursor.com/docs/context/mcp · skills: https://cursor.com/docs/context/skills
- Gemini CLI, MCP servers: https://geminicli.com/docs/tools/mcp-server/
