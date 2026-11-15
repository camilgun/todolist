# Research: on-disk data format

> Date: 2026-11-01 · Backlog task: "Choose the data format".
> Primary sources cited for every claim; what I could not verify is marked **[not verified]**.
> **Superseded (2026-11-01):** this research assumed the data had to live in text files that the AI could edit directly. That assumption was dropped: it was decided that the AI goes through the app's tools and that the data lives in SQLite ([ADR 0002](../adr/0002-data-in-sqlite.md)). The comparison between formats remains useful as a reference (for example for an export), but the JSON recommendation no longer applies.

## 1. Outcome in brief

I recommend **JSON files, one per entity** (one file per task, one per day, one for the areas), plus a **pomodoro log in JSON Lines** (one JSON object per line, one file per month, append-only), all described by a single **JSON Schema** (the standard for describing and validating the shape of a JSON document). JSON is the only format that Swift and TypeScript read without external libraries, it has no implicit typing (the YAML problem where `NO` can become `false`), and its schema is the same language that MCP (Model Context Protocol, the protocol through which Claude calls external tools) uses to describe tool input: a single contract covers the files, validation in the app, and the AI. The price is that, read raw, indented JSON costs about 50–60% more tokens than Markdown with a header; but the app will prepare a compact summary anyway that costs about a quarter, so the cost of the raw files matters little. On question (a)/(b): I recommend that the AI **write through the app's tools** (an MCP server with `add_task`, `split_task`, `log_pomodoro`, which validate the input), and **read** through the summary or the files; writing directly to the files (Claude Code in the folder) remains possible as a fallback, protected by a validator. If (b) is chosen exclusively, SQLite also becomes reasonable; I stay with JSON because it keeps the data readable, versionable with git, and editable by hand.

## 2. Comparison table

Legend: ✅ good · ⚠️ with reservations · ❌ weak. "Tokens" is the cost of reading the raw files on the test dataset (section 3.2), relative to indented JSON = 100.

| Criterion | JSON single file | **JSON per entity + JSONL** | YAML | Markdown + front matter | SQLite | Hybrid SQLite + export |
|---|---|---|---|---|---|---|
| Does not break if the AI edits it | ⚠️ obvious syntax errors; one large file = one error blocks everything | ✅ errors are obvious and confined to one file or one line | ❌ indentation, implicit typing, silent errors | ⚠️ YAML header + free-form body: two grammars | ✅ no text editing; only via SQL or tools | ⚠️ the export is read-only, edits must be re-imported |
| Concurrent writes app ↔ external editor | ❌ everything in one file, frequent conflicts | ✅ small files, atomic writes, append for the log | ⚠️ like JSON | ⚠️ like JSON | ✅ transactions and WAL, but a single writer | ⚠️ two sources to keep in sync |
| Tokens (raw) | 100 (indented) / ~70 (compact) | ~85 | ~73–78 | ~63–68 | n/a (the AI does not read the binary) | depends on the export |
| Validation | ✅ JSON Schema, Codable, Zod/Ajv | ✅ same, also line by line | ⚠️ JSON Schema after conversion; types already altered by the parser | ⚠️ schema only for the header; body cannot be validated | ✅ STRICT, CHECK, foreign keys | ✅ on the SQLite side |
| Swift | ✅ built-in `JSONDecoder` | ✅ | ⚠️ Yams (external library, YAML 1.1 booleans) | ⚠️ Markdown parser + Yams | ✅ GRDB, system SQLite | ✅ |
| TypeScript | ✅ built-in `JSON.parse` | ✅ | ✅ `yaml` library (YAML 1.2) | ⚠️ two parsers | ✅ `node:sqlite`, better-sqlite3 | ✅ |
| Readability and git diffs | ⚠️ noisy diffs on a large file | ✅ small, local diffs | ✅ | ✅ the best for humans | ❌ binary (needs `textconv`) | ⚠️ diffs only on the export |

## 3. The criteria, one by one

### 3.1 Does not break if the AI edits it

**JSON.** The RFC 8259 grammar does not allow trailing commas (a comma must be followed by another value), requires double quotes, and has no comments ([RFC 8259](https://www.rfc-editor.org/rfc/rfc8259)). These are the typical errors in an edit made by a model, but they are **loud**: the parser fails immediately. I verified with Node: `{"a":1,}`, `{'a':1}` and an unescaped double quote inside a note all make `JSON.parse` fail. The only silent error is the duplicate key: RFC 8259 only says that names "SHOULD be unique" and that the behaviour is unpredictable; `JSON.parse('{"a":1,"a":2}')` returns `{"a":2}` without errors. One file per entity limits the damage: a broken task does not prevent reading the others.

**JSON Lines.** Each line is a complete JSON value, encoded in UTF-8, separated by `\n`; the terminator after the last line is strongly recommended ([jsonlines.org](https://jsonlines.org/)). For an insert-only log it is ideal: adding a pomodoro means adding a line, and a malformed line can be isolated without losing the others.

**YAML.** The 1.2.2 spec says that in blocks "structure is determined by indentation" and forbids tabs for indentation ([YAML 1.2.2](https://yaml.org/spec/1.2.2/)). The "Norway" problem (the country code `NO` read as `false`) comes from YAML 1.1; in the YAML 1.2 Core schema only `true/True/TRUE/false/False/FALSE` are booleans, and the Core schema is the one recommended as the default ([YAML 1.2.2, §10.3](https://yaml.org/spec/1.2.2/)). But what matters is what the library does:

- the TypeScript library `yaml` uses 1.2 Core by default; with `version: '1.1'` I got `country: NO` → `false`, `active: on` → `true`, and even `time: 10:30` → `630` (a sexagesimal number) ([eemeli.org/yaml](https://eemeli.org/yaml/), verified locally with `yaml` 2.9.1);
- **Yams**, the most widely used YAML library in Swift, is based on LibYAML ([Yams](https://github.com/jpsim/Yams)) and its default resolver also recognises `yes/no/on/off` in any capitalisation as booleans ([Resolver.swift](https://raw.githubusercontent.com/jpsim/Yams/main/Sources/Yams/Resolver.swift), [Constructor.swift](https://raw.githubusercontent.com/jpsim/Yams/main/Sources/Yams/Constructor.swift)): that is, YAML 1.1 behaviour. With `Codable` and a field declared as `String` the value probably still arrives as text, but **[not verified]**.

More serious: YAML has **silent** errors. One extra dash (`- estimate: 1` instead of `estimate: 1`) produces a new untitled step instead of an error; a line shifted to the left moves the estimate from the step to the task. I tried both cases: the file reads without errors, with a different structure. Also `version: 1.10` becomes the number `1.1`. Only validation against a schema catches them.

**Markdown with front matter.** It is not a standard: it is a convention, born with Jekyll, whereby a YAML block "between triple-dashed lines" must be at the start of the file ([Jekyll](https://jekyllrb.com/docs/front-matter/)). It therefore inherits all of YAML's problems in the header, and in the body it adds ambiguity: steps as a list `- [ ] Title (2)`, estimates in parentheses, sections by heading. The AI writes this format well, but the app has to interpret free text, and a small variation ("(2 pom)", "2)") breaks parsing in fairly unpredictable ways.

**SQLite.** It is binary: the AI cannot edit it with a text editor; "text editors, grep, awk" are of no use, as SQLite's own site says ([Application file format](https://sqlite.org/appfileformat.html)). Claude Code can, however, use `sqlite3` from the terminal, and an MCP server can expose queries. On the other hand, the data does not "break": writes are atomic transactions ([Application file format](https://sqlite.org/appfileformat.html)).

**The AI's writing tools.** In Claude Code, file edits are snapshotted beforehand and can be undone (checkpoints) ([How Claude Code works](https://code.claude.com/docs/en/how-claude-code-works)). The "filesystem" MCP server used by Claude Desktop has an `edit_file` that normalises whitespace and reapplies indentation, and a `write_file` that overwrites in place and **is not atomic in case of a crash** ([filesystem server](https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem)). Normalising whitespace is harmless for JSON, risky for YAML.

**Concurrency between app and external editor.** The practical rules:

1. *Atomic writes.* In Swift, `Data.write(to:options: .atomic)` writes to an auxiliary file and then replaces the original with it ([Apple, `.atomic`](https://developer.apple.com/documentation/foundation/nsdata/writingoptions/atomic)). In Node you write a temporary file and rename it with `fs.rename`, which on macOS on the same volume is atomic **[not verified on the Node page; it is the behaviour of POSIX `rename(2)`]**.
2. *Watch the folder, not the file.* `fs.watch` "is not 100% consistent across platforms", on macOS it uses FSEvents for folders and does not guarantee the file name in the event ([Node.js fs](https://nodejs.org/api/fs.html#caveats)). On Mac you use FSEvents; `NSFileCoordinator` only coordinates processes that use it ([Apple, NSFileCoordinator](https://developer.apple.com/documentation/foundation/nsfilecoordinator)), so it does not protect against Claude Code or an editor.
3. *Optimistic checking.* Before saving, the app compares the modification date or hash with the ones it read; if the file has changed, it reloads, revalidates, and reapplies the change or reports the conflict.
4. *If an external file is not valid*, the app does not overwrite it: it shows the error and keeps the last valid version in memory.

Small per-entity files greatly reduce the probability that the app and the AI touch the same file at the same moment. SQLite solves the problem at the root with WAL (write-ahead log: readers and the writer do not block each other), but allows "only one writer at a time" and does not work on network file systems ([WAL](https://sqlite.org/wal.html), [When to use](https://sqlite.org/whentouse.html)).

### 3.2 Few tokens to read

I built a test dataset (2 areas, 5 tasks of which 3 have steps, 1 planned day, 10 pomodoros with notes and one corrected estimate) and counted the tokens with two local tokenizers: `o200k_base` (via `js-tiktoken` 1.0.21; it is OpenAI's tokenizer) and `@anthropic-ai/tokenizer` 0.0.4 (the tokenizer of earlier Claude generations). **Neither is the one used by current Claude models**: Anthropic documents that from Claude Opus 4.7 the tokenizer is new and produces about 30% more tokens on the same text ([Token counting](https://platform.claude.com/docs/en/build-with-claude/token-counting)). I did not have an API key for the counting endpoint, so the absolute values are indicative; the **ratios** between formats are the useful figure.

| Same dataset in… | Characters | o200k tokens | Claude tokens (old) | Relative to indented JSON |
|---|---:|---:|---:|---:|
| Indented JSON, single file | 4810 | 1682 | 1700 | 100% |
| Compact JSON, single file | 3113 | 1156 | 1201 | ~70% |
| YAML, single file | 3413 | 1319 | 1232 | ~73–78% |
| JSON per entity (indented) + JSONL pomodoros | 3692 | 1432 | 1480 | ~85% |
| Markdown with front matter + JSONL pomodoros | 2676 | 1066 | 1162 | ~63–68% |
| **Compact summary prepared by the app** | 1071 | 380 | 434 | **~23–26%** |

The 10 pomodoros alone: JSONL 673/704 tokens, YAML 740/697: practically the same.

What follows from this: (1) YAML does not save much compared with compact JSON; (2) Markdown is the cheapest of the raw formats, but only by a third; (3) the summary made by the app costs a quarter of any raw format, because it contains only the information that is needed (done/estimate, open steps, latest notes). Example of a summary line:

```
- t-001 [work] "Draft offer sent to the client" 3/6 in_progress; steps: ✓Client requirements summarised on one page (1); ·Cost estimate completed (3); ·Draft written and sent (2); notes: The client wants delivery by March.
```

So the on-disk format should be chosen for robustness and validation, not for tokens. If the AI reads the files directly (Claude Code in the folder), per-entity files help: it reads only the tasks it needs, not the whole history.

### 3.3 Validation

- **JSON Schema.** The current version is 2020-12 ([json-schema.org](https://json-schema.org/specification)). In TypeScript, Ajv supports drafts 04, 06, 07, 2019-09 and 2020-12 ([Ajv](https://ajv.js.org/)); Zod 4 generates JSON Schema natively with `z.toJSONSchema()` (default target `draft-2020-12`), while `z.fromJSONSchema()` is experimental ([Zod](https://zod.dev/json-schema)). So in TypeScript you can write the schema once in Zod and generate the `.schema.json` file.
- **Swift.** `Codable` with `JSONDecoder` is typed decoding: a missing required key raises `DecodingError.keyNotFound` ([Apple](https://developer.apple.com/documentation/swift/decodingerror/keynotfound(_:_:))), and `CodingKeys` is the authoritative list of properties ([Apple, Encoding and decoding custom types](https://developer.apple.com/documentation/foundation/encoding-and-decoding-custom-types)). However, it is not entirely "strict": unknown keys are ignored **[not verified on an Apple page; known behaviour of the synthesised conformance]**, so an AI typo on an optional field (`estimat` instead of `estimate`) passes silently. There is `allowsJSON5` (macOS 12+) to accept comments and trailing commas when reading ([Apple](https://developer.apple.com/documentation/foundation/jsondecoder/allowsjson5)): useful as a tolerance, but comments disappear on save. JSON Schema validators in Swift are young: `swift-json-schema` claims 2020-12 validation ([GitHub](https://github.com/ajevans99/swift-json-schema)), JSONSchema.swift has incomplete 2020-12 support ([GitHub](https://github.com/kylef-archive/JSONSchema.swift)). In practice: in Swift, Codable plus hand-written consistency checks is enough; the JSON schema is for tests, for the AI, and for external tools.
- **YAML** can be validated with JSON Schema only after conversion: if the parser has already turned `NO` into `false`, the schema sees `false`.
- **Front matter**: the header is validated; the Markdown body is not.
- **SQLite**: STRICT tables (since SQLite 3.37.0) reject values that cannot be converted to the declared type ([STRICT tables](https://sqlite.org/stricttables.html)); with `CHECK` and foreign keys the rules can be expressed too. Verified locally (sqlite 3.54): inserting `'three'` into a STRICT `INTEGER` column gives an error, while in a normal table it is stored as text.

**Validating the AI's direct edits too.** In Claude Code, a `PostToolUse` hook with the matcher `Edit|Write` can run a validator after every edit; with exit code 2 the error goes back to Claude, which can fix it (the edit has already happened, it is not blocked) ([Hooks](https://code.claude.com/docs/en/hooks)).

### 3.4 Fit with Swift and TypeScript, readability, git

- **JSON**: built into both (`JSONDecoder`/`JSONEncoder`; `JSON.parse`). In Swift, `outputFormatting = [.prettyPrinted, .sortedKeys]` produces files with keys in a fixed order ([Apple](https://developer.apple.com/documentation/foundation/jsonencoder/outputformatting-swift.struct)): essential so that git diffs show only the real changes. In TypeScript the key order has to be enforced by the saving code. With Tauri, the Rust backend normally uses serde_json **[not verified in this research]**.
- **YAML**: Swift requires Yams (Codable via `YAMLEncoder`/`YAMLDecoder`) ([Yams](https://github.com/jpsim/Yams)); TypeScript the `yaml` library, which also preserves comments, with some instability around trailing comments ([eemeli.org/yaml](https://eemeli.org/yaml/)).
- **SQLite**: in Swift, GRDB 7.11.1 (June 2026) offers Codable records, migrations, change observation, and `DatabasePool` in WAL; it requires Swift 6.1+ and macOS 10.15+ ([GRDB README](https://raw.githubusercontent.com/groue/GRDB.swift/master/README.md)). In Node, `node:sqlite` has been built in since v22.5.0, without a flag since v22.13/23.4, and has been a "Release candidate" (stability 1.2) since v25.7.0 ([Node.js sqlite](https://nodejs.org/api/sqlite.html)); better-sqlite3 is the mature alternative with a synchronous API, but it is a native module ([better-sqlite3](https://github.com/WiseLibs/better-sqlite3)). With Tauri there is the SQL plugin based on sqlx ([Tauri SQL](https://v2.tauri.app/plugin/sql/)).
- **Git**: JSON and YAML diff well if the keys have a stable order; SQLite is binary and needs a `textconv` driver (for example `sqlite3 .dump`) to see readable differences, which work only with `git diff`/`git log` and cannot be applied as patches ([gitattributes](https://git-scm.com/docs/gitattributes)).
- **TOML**: designed as a "minimal configuration file format" ([TOML 1.0.0](https://toml.io/en/v1.0.0)); lists of nested objects (task → steps) with `[[...]]` are awkward, and Swift has no built-in support. I do not recommend it for this data.

### 3.5 Iteration 2: how will the AI write?

**(a) Writing directly to the files.** With Claude Code in the data folder it is immediate. With Claude Desktop it is not "direct": an MCP server is still needed, typically the filesystem server, configured in `claude_desktop_config.json` with the allowed folders; Claude Desktop starts it and asks for approval for actions ([Connect to local MCP servers](https://modelcontextprotocol.io/docs/develop/connect-local-servers)). The AI has to know and respect the format rules and the invariants (unique identifiers, steps consistent with the estimate, pomodoros pointing to existing tasks), and an error is discovered only afterwards.

**(b) Only through the app's tools.** In the current MCP spec (2026-07-28) every tool declares an `inputSchema` that is a JSON Schema (2020-12 if not specified), the server "MUST" validate all inputs, and validation errors go back to the model with `isError: true` so that it can correct itself ([MCP Tools 2026-07-28](https://modelcontextprotocol.io/specification/2026-07-28/server/tools), [Versioning](https://modelcontextprotocol.io/specification/versioning)). For Claude Desktop the server is distributed as a `.mcpb` extension installable with one click; Node.js, Python, or binary servers are supported, and Node is bundled with the app ([Claude Help Center](https://support.claude.com/en/articles/10949351-getting-started-with-local-mcp-servers-on-claude-desktop)). Claude Code uses the same server via `claude mcp add` or `.mcp.json` ([Claude Code MCP](https://code.claude.com/docs/en/mcp)). In Swift there is the official MCP SDK (macOS 13+, server and stdio transport), which however declares the 2025-11-25 spec, not 2026-07-28 ([swift-sdk](https://github.com/modelcontextprotocol/swift-sdk)); compatibility with current clients is **[not verified]**.

**My view: (b) is more advisable, and also more likely for everyday use.** Reasons:

1. Operations like "split the task into steps" touch several pieces of data together; a `split_task` tool performs all of them or none, with the app's rules. With text edits the AI has to reconstruct the invariants every time.
2. Claude Desktop, which is the first tool planned, requires an MCP server anyway: it might as well be the app's own rather than the generic filesystem one.
3. Tools keep token consumption low: the AI asks for `get_day_summary` instead of reading files.
4. The protocol itself pushes in this direction: mandatory server-side validation and errors designed for self-correction.

But (a) will not go away: Claude Code in the folder is convenient for large clean-ups. That is why the format must remain robust to text edits, and it is the reason for choosing neither YAML nor Markdown as the source of truth.

**How the format choice changes.** With exclusive (b) the format can favour the app, and SQLite becomes strong: transactions, constraints, and inter-process concurrency already solved. Note, however: even in (b) the MCP server is a **separate process** started by Claude Desktop, not the app; the app and the server therefore write to the same data from two processes. With SQLite, WAL handles this; with JSON you need atomic writes, folder watching, and optimistic checking (section 3.1). With (a) the format must be robust, validatable text: JSON. Since we want both routes, plus readability and git, JSON per entity plus JSONL is the compromise.

## 4. Recommended structure

```
data/                           ← folder chosen by the user, can be versioned with git
├── schema/                     ← JSON Schema 2020-12, the same ones used by the MCP tools
│   ├── areas.schema.json
│   ├── task.schema.json
│   ├── day.schema.json
│   └── pomodoro.schema.json
├── areas.json                  ← areas and daily budget
├── task/
│   ├── t-0001.json             ← one file per task, name = id assigned by the app
│   └── t-0002.json
├── days/
│   └── 2026-11-01.json         ← pomodoros available per area, chosen tasks and their order
└── pomodoros/
    ├── 2026-10.jsonl           ← log: append-only, one line per pomodoro
    └── 2026-11.jsonl
```

Daily summaries and history are **computed** from the log; if they are needed for speed, they go in a regenerable cache, not in the source of truth.

Example of `task/t-0001.json` (saved indented and with sorted keys):

```json
{
  "area": "work",
  "estimate": 6,
  "id": "t-0001",
  "notes": "The client wants delivery by March.",
  "schemaVersion": 1,
  "status": "in_progress",
  "steps": [
    { "done": true,  "estimate": 1, "id": "s1", "title": "Client requirements summarised on one page" },
    { "done": false, "estimate": 3, "id": "s2", "title": "Cost estimate completed" },
    { "done": false, "estimate": 2, "id": "s3", "title": "Draft written and sent" }
  ],
  "title": "Draft offer sent to the client"
}
```

Example of a line in `pomodoros/2026-10.jsonl`:

```json
{"id":"p-0002","start":"2026-10-30T09:30:00+01:00","end":"2026-10-30T09:55:00+01:00","task":"t-0001","step":"s2","note":"Supplier prices are still missing.","estimateChange":{"from":5,"to":6}}
```

Usage rules: `schemaVersion` for future migrations; ISO 8601 dates with time zone; the app always writes atomically and revalidates every file changed from outside; in Claude Code a `PostToolUse` hook runs the same validator.

## 5. Risks and uncertainties

- **Tokens measured with approximate tokenizers.** Current Claude models use a different tokenizer (about +30% tokens); the ratios between formats should hold, but I did not measure them with the official endpoint.
- **Long notes in JSON** become strings with `\n` that are hard to read. If notes grow, they can be moved to a `.md` file next to the task.
- **Codable ignores unknown keys** (not verified on an Apple page): a typo on an optional field passes silently. Schema validation (`additionalProperties: false`) is needed at least in the hook and in the tests.
- **JSON Schema validation in Swift** is less mature than in TypeScript; if the app is in Swift, the schema and the Codable rules have to be kept in sync by hand or generated.
- **Swift MCP SDK** stuck at the 2025-11-25 spec while the current one is 2026-07-28: compatibility to be verified when we get to iteration 2.
- **Two processes writing** (app and MCP server) with JSON files require a write discipline that SQLite would give for free. If conflicts emerge in real use, the hybrid "SQLite as the source + JSON/Markdown export for the AI" is the escape route, at the price of losing hand editing and git diffs.
- **Atomicity of `fs.rename` on macOS**: inferred from POSIX behaviour, not read in the Node documentation.
- Library versions read on 2026-11-01; Yams and better-sqlite3 did not show the latest release on the pages consulted.

## 6. Sources

- RFC 8259, JSON: https://www.rfc-editor.org/rfc/rfc8259
- JSON Lines: https://jsonlines.org/
- JSON Schema, specification: https://json-schema.org/specification
- YAML 1.2.2: https://yaml.org/spec/1.2.2/
- Jekyll, front matter: https://jekyllrb.com/docs/front-matter/
- TOML 1.0.0: https://toml.io/en/v1.0.0
- SQLite STRICT: https://sqlite.org/stricttables.html
- SQLite WAL: https://sqlite.org/wal.html
- SQLite as an application file format: https://sqlite.org/appfileformat.html
- SQLite, when to use it: https://sqlite.org/whentouse.html
- Apple, `JSONDecoder.allowsJSON5`: https://developer.apple.com/documentation/foundation/jsondecoder/allowsjson5
- Apple, `JSONEncoder.OutputFormatting`: https://developer.apple.com/documentation/foundation/jsonencoder/outputformatting-swift.struct
- Apple, Encoding and decoding custom types: https://developer.apple.com/documentation/foundation/encoding-and-decoding-custom-types
- Apple, `DecodingError.keyNotFound`: https://developer.apple.com/documentation/swift/decodingerror/keynotfound(_:_:)
- Apple, `.atomic` writing: https://developer.apple.com/documentation/foundation/nsdata/writingoptions/atomic
- Apple, NSFileCoordinator: https://developer.apple.com/documentation/foundation/nsfilecoordinator
- Yams: https://github.com/jpsim/Yams · resolver: https://raw.githubusercontent.com/jpsim/Yams/main/Sources/Yams/Resolver.swift · constructors: https://raw.githubusercontent.com/jpsim/Yams/main/Sources/Yams/Constructor.swift
- `yaml` library for JavaScript: https://eemeli.org/yaml/
- GRDB: https://github.com/groue/GRDB.swift
- swift-json-schema: https://github.com/ajevans99/swift-json-schema · JSONSchema.swift: https://github.com/kylef-archive/JSONSchema.swift
- Node.js `node:sqlite`: https://nodejs.org/api/sqlite.html · `fs.watch`: https://nodejs.org/api/fs.html#caveats
- better-sqlite3: https://github.com/WiseLibs/better-sqlite3
- Tauri SQL plugin: https://v2.tauri.app/plugin/sql/
- Ajv: https://ajv.js.org/ · Zod and JSON Schema: https://zod.dev/json-schema
- Git, gitattributes (textconv): https://git-scm.com/docs/gitattributes
- MCP, tools (spec 2026-07-28): https://modelcontextprotocol.io/specification/2026-07-28/server/tools · versioning: https://modelcontextprotocol.io/specification/versioning
- MCP, local servers in Claude Desktop: https://modelcontextprotocol.io/docs/develop/connect-local-servers
- MCP, filesystem server: https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem
- MCP Swift SDK: https://github.com/modelcontextprotocol/swift-sdk
- Claude Help Center, local MCP servers and desktop extensions: https://support.claude.com/en/articles/10949351-getting-started-with-local-mcp-servers-on-claude-desktop
- Claude Code, MCP: https://code.claude.com/docs/en/mcp · hooks: https://code.claude.com/docs/en/hooks · how it works and checkpoints: https://code.claude.com/docs/en/how-claude-code-works
- Anthropic, token counting and the new tokenizer: https://platform.claude.com/docs/en/build-with-claude/token-counting
