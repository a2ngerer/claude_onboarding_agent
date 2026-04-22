---
name: knowledge-base-setup
description: Set up Claude to build and maintain a structured knowledge base using the Karpathy LLM Wiki pattern — works with codebases, personal notes, or both. Integrates with Obsidian via the official Obsidian CLI (token-efficient, dispatched through a dedicated subagent — no always-on MCP overhead).
---

# Knowledge Base Setup

This skill configures Claude to build and maintain a structured, interlinked knowledge base using the Karpathy LLM Wiki pattern.

**Handoff context:** Read `skills/_shared/consume-handoff.md` and run it with the handoff block (if any). The helper guarantees the following locals: `detected_language`, `existing_claude_md`, `inferred_use_case`, `repo_signals`, `graphify_candidate`. Use `detected_language` for all user-facing prose; generated file content stays in English.

**Existing CLAUDE.md:** If `existing_claude_md: true`, DO NOT overwrite it. Append a new delimited section at the end of the file:

```
<!-- onboarding-agent:start setup=knowledge-base skill=knowledge-base-setup section=claude-md -->
## Claude Onboarding Agent — Knowledge Base
...generated content...
<!-- onboarding-agent:end -->
```

If the delimited block already exists from a previous run, replace only the content between the markers; leave the rest of the file untouched. Wrap generated `.gitignore` entries in `# onboarding-agent: knowledge-base — start` / `— end` markers so `/upgrade-setup` can refresh them non-destructively.

## Supporting Files

Read these on-demand at the step that invokes them. Do not read eagerly.

- `skills/_shared/consume-handoff.md` — orchestrator handoff parse + inline fallback (preamble, before Step 1)
- `skills/_shared/offer-superpowers.md` — canonical Superpowers opt-in (Step 1)
- `skills/_shared/offer-graphify.md` — canonical Graphify opt-in (Step 4)

## Step 1: Install Dependencies

Read `skills/_shared/offer-superpowers.md` and run it with `skill_slug: knowledge-base-setup`, `mandatory: true`. The helper delegates to `skills/_shared/installation-protocol.md` and sets `superpowers_installed`, `superpowers_scope`, `superpowers_method`.

Then read `skills/_shared/installation-protocol.md` and follow it for Karpathy Guidelines:
- Karpathy Guidelines (optional) — github only: `https://github.com/forrestchang/andrej-karpathy-skills`, name: `karpathy-skills`

Note: The Obsidian CLI verification is handled inline in Step 2 (after question 2) — it is a system check, not an install.

## Step 2: Context Questions

Ask one at a time, waiting for each answer:

1. "What are you primarily building this knowledge base from?
   A) An existing codebase
   B) Personal notes and documents
   C) Both"

2. "Do you have Obsidian installed?

   Obsidian is a free, local-first markdown editor with graph view and wiki-style linking. With the official **Obsidian CLI** (desktop 1.12.4+), Claude can read and write your vault directly from the terminal — wikilinks are rewritten on `move`, new notes go through Obsidian's own APIs, and the graph view picks up changes automatically.

   This setup wires the CLI into a dedicated subagent (`obsidian-vault-keeper`). Claude dispatches the agent only when your task actually touches the vault — so you pay **no extra context tokens** in chats that don't involve Obsidian. This replaces the earlier Obsidian MCP approach, whose tool schemas were loaded into every Claude session regardless of whether you used them.

   Without Obsidian, Claude creates well-organized markdown files you can open in any text editor — this works great and unlocks the same core workflow.

   **Recommendation: Option A** if you use Obsidian — the graph view makes a large knowledge base much easier to navigate.

   A) Yes, I have Obsidian installed — set up the CLI + subagent integration
   B) No / skip for now — use plain markdown files"

   After the user answers question 2: if they chose Option A (Obsidian), run the **Obsidian CLI verification** immediately:

   ### Obsidian CLI verification

   a. Tell the user (adapt to detected language):
      > "To finish the Obsidian integration I need the official Obsidian CLI on your PATH.
      > 1. Open Obsidian → Settings → General → enable **Command line interface**.
      > 2. Follow the on-screen steps to add `obsidian` to your PATH (macOS/Linux may need `source ~/.zshrc` or a new terminal).
      > 3. Keep Obsidian running — the CLI is a remote control, not a headless tool.
      > Reply `done` when ready."

   b. When the user confirms, detect the CLI with **3 retries and a 3-second sleep between attempts**. A freshly enabled Obsidian CLI typically needs 5–10 s and a fresh shell to register on `PATH`, so a single probe produces false negatives. Run `command -v obsidian` via Bash; if the command returns empty or errors, `sleep 3` and retry. Repeat up to three attempts in total.
      - If any attempt returns a path: set `obsidian_cli_available: true` and continue with step c.
      - If all three attempts fail: **do not fall back silently.** Fallback is opt-in, not automatic. Ask the user verbatim (adapt to detected language, keep the three lettered options):
        > "Obsidian CLI still not detected. Options: (a) I'll wait and retry, (b) fall back to plain markdown, (c) abort setup."
        - **(a)** Run the same 3-retry detection loop again. If it still fails, re-ask the same three-option question.
        - **(b)** Set `obsidian_cli_available: false` and treat the remaining steps as Option B (plain markdown).
        - **(c)** Abort the skill — do not generate any artifacts. Tell the user they can re-run `/knowledge-base-setup` after enabling the CLI.

   c. If `obsidian_cli_available: true`, also check that Obsidian responds: run `obsidian help` via Bash. If it errors with "Obsidian is not running", ask the user to open Obsidian and retry once. If it still fails, re-ask the same three-option question from step b (wait / fall back / abort) — again, the fallback to plain markdown requires explicit user confirmation and is never chosen automatically.

3. "What is the path to your target folder?
   - Obsidian users: your vault path (e.g., `/Users/you/Documents/MyVault`)
   - Others: any folder you choose (e.g., `~/my-wiki`)"

4. "What language are your source files in? (for code: the programming language; for notes: the human language, e.g., English, German)"

## Step 3: Generate Artifacts

### Folder Structure

Create the following in the target path from question 3:
```
[target_path]/
├── raw/          ← drop source material here (articles, code files, PDFs, notes)
└── wiki/
    └── README.md ← overview of the wiki structure
```

`wiki/README.md`:
```markdown
# Knowledge Base

Built with Claude using the Karpathy LLM Wiki pattern.

## How to Use

**Adding sources:** Drop files into `raw/`. Then ask Claude: "Ingest the new files in raw/ and update the wiki."

**Wiki structure:** Each note in `wiki/` covers one concept, person, project, or topic. Notes link to related notes using [[wikilinks]].

**Note format:**
- First line: one-sentence summary
- Second line: `tags: #topic #subtopic`
- Body: structured content with headers
- Last section: `## Related: [[linked-note-1]], [[linked-note-2]]`
```

### Obsidian integration files (ONLY if `obsidian_cli_available: true`)

Create two files in the current repo (not inside the vault):

**a) `.claude/agents/obsidian-vault-keeper.md`** — subagent definition. Claude Code auto-loads this from `.claude/agents/`. The main thread dispatches this agent via the Agent tool whenever an operation must land in the vault.

```markdown
---
name: obsidian-vault-keeper
description: Use to read, write, search, move, or delete notes in the user's Obsidian vault via the official Obsidian CLI. Dispatch this agent for any operation that should touch the vault — it reads .claude/rules/obsidian-cli.md for the command reference and runs `obsidian …` via Bash. Returns a compact summary, not raw note contents (unless asked).
tools: Bash, Read, Glob, Grep
---

You are the Obsidian Vault Keeper. You perform read/write operations on the user's Obsidian vault using the official Obsidian CLI.

## Before your first command
Read `.claude/rules/obsidian-cli.md` for the full command reference and output formats.

## Rules
- Use the `obsidian` CLI via Bash exclusively. Never edit vault files with Edit/Write — wikilinks and backlinks depend on Obsidian's own APIs (e.g. `obsidian move` rewrites links, a plain `mv` does not).
- Obsidian must be running. If a command errors with "Obsidian is not running", ask the caller to open Obsidian, then retry once.
- Prefer structured output: append `format=json` or `format=paths` when supported. It parses smaller and cleaner than prose.
- For multi-step operations (e.g. search → move all matches), pipe `format=paths` through a shell loop rather than issuing commands one note at a time.
- Return a compact summary — operation name, counts, paths affected. Do NOT dump note contents unless explicitly asked.

## Error handling
- `obsidian` binary missing → tell caller: enable "Command line interface" in Obsidian Settings → General, then add to PATH. Abort.
- Command fails for another reason → surface stderr verbatim so the caller can see it.

## Out of scope
- Configuring Obsidian plugins, themes, or settings.
- Writing outside the vault path (use normal tools for that).
```

**b) `.claude/rules/obsidian-cli.md`** — read-on-demand CLI reference. Keeps CLAUDE.md lean (point-don't-dump).

```markdown
# Obsidian CLI Reference

Official Obsidian CLI (desktop 1.12.4+). Requires the Obsidian app to be running and the `obsidian` binary on PATH (Settings → General → Command line interface).

## Read
- `obsidian read file="path/to/note"` — print note content
- `obsidian file file="path/to/note"` — file metadata
- `obsidian files` — list all notes (add `format=paths` for path-only output)
- `obsidian folders` — folder tree

## Write
- `obsidian create name="path/to/note" content="..."` — create a new note
- `obsidian create name="path/to/note" template="TemplateName"` — create from a template
- `obsidian append file="path/to/note" content="..."` — append to an existing note
- `obsidian prepend file="path/to/note" content="..."` — insert after frontmatter

## Search
- `obsidian search query="term"` — fulltext search
- `obsidian search:context query="term" limit=10` — include surrounding lines
- Add `format=json` or `format=paths` for machine-readable output

## Tags
- `obsidian tag tag="#name"` — list files with a specific tag
- `obsidian tags` — list every tag in the vault

## Move / Delete
- `obsidian move file="note" to="folder/"` — moves and rewrites wikilinks automatically
- `obsidian delete file="note"` — move to system trash
- `obsidian delete file="note" permanent` — delete permanently

## Output formats
Supported values for `format=`: `json`, `csv`, `tsv`, `md`, `paths`, `text`, `tree`, `yaml`. Prefer `paths` or `json` for piping.

## Troubleshooting
- "Obsidian is not running" → open Obsidian, retry.
- "Unknown command" → run `obsidian help` to list commands for the installed version.
- Wikilinks broke after moving a file → always use `obsidian move`, never Finder/`mv`.
```

### CLAUDE.md

```markdown
# Claude Instructions — Knowledge Base

## Setup
Target path: [answer from Q3]
Source material: [answer from Q1]
Source language: [answer from Q4]

## Workflow — Karpathy LLM Wiki Pattern
[Include ONLY if superpowers_installed is true]
At the start of every new conversation, invoke the `using-superpowers` skill.

### Structure
- `raw/` — source material (never modify files here)
- `wiki/` — organized, interlinked knowledge notes

### Note Format
Every wiki note must have:
1. First line: one-sentence summary of the topic
2. Second line: `tags: #tag1 #tag2`
3. Body: structured content with H2/H3 headers
4. Last section: `## Related: [[note1]], [[note2]]`

### Ingestion Process
When asked to ingest new material from raw/:
1. Read the source file
2. Extract key concepts, facts, and insights
3. Create or update wiki notes — one note per concept
4. Link new notes to related existing notes using [[wikilinks]]
5. Update existing notes if new material adds to them
6. Do NOT delete or overwrite existing wiki content — only extend it

### For Codebases
When documenting code:
1. Create one wiki note per module/package/component
2. Note: purpose, public API, key dependencies, important design decisions
3. Link to notes about dependencies
4. Maintain a `wiki/architecture.md` overview that links to all component notes

## Obsidian
[Include if obsidian_cli_available is true]
Obsidian vault ops run through the `obsidian-vault-keeper` subagent (see `.claude/agents/obsidian-vault-keeper.md`). **Always dispatch that agent via the Agent tool** for reads, writes, searches, moves, or deletes on the vault — do not shell out to `obsidian` directly from this thread and do not edit vault files with Edit/Write.
Command reference: `.claude/rules/obsidian-cli.md` (read-on-demand; the subagent handles this automatically).
Why a subagent: keeps CLI schema out of the main context window, so chats that don't touch the vault cost zero Obsidian tokens.

[Include if obsidian_cli_available is false]
Using plain markdown files. Open the `wiki/` folder in Obsidian or any markdown editor.
```

### .gitignore

Assemble the block from the knowledge-base-specific lines below plus the shared common patterns from `skills/_shared/gitignore-common.md`. Wrap in `# onboarding-agent: knowledge-base — start` / `— end` markers.

Knowledge-base-specific lines:

```gitignore
# Large source files in raw/
raw/*.pdf
raw/*.docx
raw/*.pptx
raw/*.mp4
raw/*.zip
```

Then inline the block from `skills/_shared/gitignore-common.md` (OS noise, env files, `.claude/settings.local.json`).

## Step 4: Optional Graphify Integration

A knowledge base is exactly the kind of corpus Graphify is designed for — interlinked Markdown notes and their raw/ sources, so the initial build is strongly recommended. Before invoking the helper, probe whether the target folder from Q3 is under git; if not, set `install_git_hook: false` instead of `true`.

Read `skills/_shared/offer-graphify.md` and run it with:

- `host_setup_slug: "knowledge-base"`
- `host_skill_slug: "knowledge-base-setup"`
- `run_initial_build: true`
- `install_git_hook: <true if target folder is under git, else false>`
- `corpus_blurb: "your \`raw/\` (PDFs, Markdown, code, diagrams, images, audio/video — 25 languages via tree-sitter) and \`wiki/\` folders"`

The helper owns the opt-in prompt and the three-way branch (yes / no / later),
delegating to `skills/_shared/graphify-install.md`. Record the `graphify_*`
variables it produces for use in Step 7.

## Step 5: Write Upgrade Metadata

Set `setup_slug: knowledge-base`, `skill_slug: knowledge-base-setup`. Resolve `plugin_version` from the plugin's own `plugin.json`. Then follow `skills/_shared/write-meta.md` to create or merge `./.claude/onboarding-meta.json`. If Step 4 installed Graphify, `skills_used` will automatically pick up `graphify-setup` via the shared protocol's own write-meta call — this step records `knowledge-base-setup` alongside it.

## Step 6: Render Anchor Sections

Read `skills/_shared/anchor-mapping.md`. Locate the row for `setup_type: knowledge-base`. For each anchor slug in that row:

1. Call `skills/_shared/render-anchor-section.md` with:
   - `setup_type: knowledge-base`
   - `skill_slug: knowledge-base-setup`
   - `anchor_slug: <slug>`
   - `target_file: ./CLAUDE.md`
   - `fallback_content: <embedded fallback from skills/anchors/SKILL.md for that slug>`
2. If a `./AGENTS.md` file was generated earlier in this skill, repeat the call with `target_file: ./AGENTS.md`.

Do not fail if any single `render-anchor-section.md` call returns `placeholder`. Collect rendered / placeholder slugs for the completion summary.

For every call, also capture `render_freshness`. When it is anything other than `network` or `cache` (i.e. `fallback` or `embedded`), record the `(anchor_slug, render_freshness)` pair in `anchor_freshness_notes`. The completion summary's `Anchor freshness` line consumes this list.

## Step 7: Completion Summary

```
✓ Knowledge Base setup complete!

Files created:
  CLAUDE.md                              — Karpathy-pattern workflow instructions
  [target]/raw/                          — drop source material here
  [target]/wiki/                         — your knowledge base will be built here
  [target]/wiki/README.md                — how to use your knowledge base
  [if obsidian_cli_available]
    .claude/agents/obsidian-vault-keeper.md — subagent that owns vault I/O
    .claude/rules/obsidian-cli.md     — CLI command reference (read-on-demand)
  .gitignore                             — excludes large source files
  .claude/onboarding-meta.json           — setup marker for /upgrade-setup

External skills:
  [✓/⚠] Superpowers [via superpowers_method (superpowers_scope) / failed — install manually]
  [✓/⚠] Karpathy Guidelines [via karpathy_method (karpathy_scope) / failed — optional, skipped]
  [✓ Obsidian CLI verified — vault ops routed through obsidian-vault-keeper subagent
   / ⚠ Obsidian CLI unavailable — using plain markdown files
   / — not requested]

Graphify (knowledge graph):
  [✓ installed via <installer>, /graphify + PreToolUse hook registered | ⚠ installed but hook not verified — run /graphify in a new session | — skipped: <reason> | — deferred: run /graphify-setup when ready | — not offered]

Anchor freshness:
  [omit the whole block if anchor_freshness_notes is empty; otherwise one line per entry:
   Anchor <anchor_slug> served from <render_freshness> — consider running /anchors to refresh.]

Next steps:
  Drop files into [target]/raw/
  Start a new Claude session and say: "Ingest the files in raw/ and build the wiki"
  [if obsidian_cli_available] For vault ops, just ask — Claude will dispatch the obsidian-vault-keeper agent automatically.
  [if graphify_installed] Try: /graphify query "which notes mention <topic>?"
  - Run `/anchors` any time to refresh the anchor-derived sections. If any section was rendered as a placeholder due to offline mode, re-run `/anchors` once you are back online.
```
