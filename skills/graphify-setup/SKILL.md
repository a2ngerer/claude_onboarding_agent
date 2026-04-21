---
name: graphify-setup
description: Install and wire up Graphify — an open-source knowledge-graph tool for Claude Code. Registers a /graphify slash command and a PreToolUse hook that consults a local graph before file-search tool calls, dramatically reducing token cost on large codebases, docs, and mixed-media corpora. Handles code (25 languages via tree-sitter), Markdown, PDFs, diagrams, images, audio/video.
---

# Graphify Setup — Knowledge-Graph Integration

This skill installs [Graphify](https://github.com/safishamsi/graphify), registers its `/graphify` slash command and PreToolUse hook with Claude Code, optionally builds an initial graph for the current project, and records a short pointer block in `CLAUDE.md`.

It is safe to run standalone via `/graphify-setup`, OR it is delegated to from any host setup skill (coding-setup, knowledge-base-builder, research-setup, data-science-setup, web-development-setup) when the user opts in.

**Language:** Use `detected_language` from handoff context, or detect from the user's first message and use it throughout. All generated file content stays in English.

**Existing CLAUDE.md:** never silently overwritten. Graphify's pointer block lives inside an attributed delimited section (`<!-- onboarding-agent:start setup=<host_setup_slug> skill=graphify-setup section=graphify -->`). When this skill runs standalone, the `setup=` attribute is `graphify`. When delegated to from another host setup, the attribute matches that host — so `/upgrade-setup` keeps every skill's block cleanly addressable.

## Step 1: Detect handoff vs standalone

If a HANDOFF_CONTEXT was passed (invoked from a host setup), read:

- `host_setup_slug` (one of `coding`, `data-science`, `knowledge-base`, `research`, `web-development`)
- `host_skill_slug` (the host skill's directory name)
- `run_initial_build` (bool)
- `install_git_hook` (bool)

If no handoff, set:

- `host_setup_slug: "graphify"`
- `host_skill_slug: "graphify-setup"`
- `run_initial_build: null` (ask in Step 3)
- `install_git_hook: null` (ask in Step 3)

Also detect whether `CLAUDE.md` already exists in the working directory → `existing_claude_md: true|false`.

## Step 2: Explain what Graphify does (standalone only)

Skip this step if invoked via handoff — the host skill already asked.

Print ONCE (adapt to detected language):

> "Graphify is a local, open-source knowledge graph for Claude Code (https://github.com/safishamsi/graphify).
>
> What it does for you:
>   - Indexes your project into a graph: code symbols (25 languages via tree-sitter), Markdown, PDFs, diagrams, images, audio/video.
>   - Registers a PreToolUse hook that consults the graph BEFORE Claude runs Grep / Glob / Read on your repo — cuts token cost substantially on large codebases or mixed-media corpora.
>   - Adds a `/graphify` slash command for natural-language queries against the graph (`/graphify query`, `/graphify path`, `/graphify explain`).
>
> This setup installs the `graphifyy` Python package (via `uv tool install`, or `pipx` as fallback), runs `graphify install` to wire up the hook and slash command, optionally builds the initial graph for this project, optionally installs a git hook that refreshes the graph on commit, and records a pointer block in your CLAUDE.md.
>
> Shall I proceed? (yes / no)"

If the user answers `no`: print `"Skipped. Run /graphify-setup any time."` and stop. Do not touch any files.

## Step 3: Context questions (standalone only — 4 questions)

Skip this step if invoked via handoff AND all four variables are already set from the host skill.

Ask these ONE AT A TIME. Wait for each answer.

1. **Project root confirmation** — "Is the current directory (`$PWD`) the project you want Graphify to index? (yes / no — if no, `cd` to the right folder and re-run `/graphify-setup`)"
   - `no` → stop. Print: `"Please cd into the target project and re-run /graphify-setup."`
   - `yes` → continue.

2. **Initial build** — "Build the graph on this project now? Graphify will index source files via tree-sitter + Markdown/PDF parsers. Large corpora can take a few minutes; you can always run `graphify .` later. (yes / no)"
   - Store as `run_initial_build: true|false`.

3. **Git auto-update hook** — only ask if the current directory contains a `.git/` folder. Otherwise set `install_git_hook: false` and skip this question.
   "Install the git auto-update hook? After each commit, `graphify` runs automatically so the graph stays in sync with the code. (yes / no)"
   - Store as `install_git_hook: true|false`.

4. **Installer preference** — "Preferred installer? Graphify is a Python CLI.
   A) `uv tool install` (recommended — this project is `uv`-first; no global Python pollution)
   B) `pipx install` (fallback — only if you don't have `uv` yet)
   C) Let the setup pick automatically (tries `uv` first, falls back to `pipx`)"
   - A / B / C → this is advisory only. The actual probe in the shared protocol picks the real installer based on what is available; if the user picks A and `uv` is missing, the protocol warns and falls back. Never silently downgrade to plain `pip`.

## Step 4: Run the shared install protocol

Read `skills/_shared/graphify-install.md` and follow every step G1–G9 in order, with the inputs resolved in Steps 1–3 of this skill.

The shared protocol handles:

- G1: Python >= 3.10 check
- G2: `uv` / `pipx` probe + non-pip guarantee
- G3: `uv tool install graphifyy` (or `pipx install graphifyy`)
- G4: `graphify install` to register the slash command and PreToolUse hook
- G5: verify `graphify` appears in `.claude/settings.json` or `~/.claude/settings.json`
- G6: optional `graphify .` initial build
- G7: optional `graphify hook install` for commit-time refresh
- G8: append / replace the attributed CLAUDE.md section
- G9: return status variables for the completion summary

## Step 5: Write upgrade metadata

Set:

- `setup_slug: graphify` (ONLY if this skill runs standalone — when delegated from a host skill, leave `setup_slug` to the host's value so `setup_type` in the meta file records the primary setup, and `skills_used` picks up `graphify-setup` through the merge rule).
- `skill_slug: graphify-setup`
- `plugin_version` — resolved as usual from the plugin's `plugin.json`.

Then follow `skills/_shared/write-meta.md` to create or merge `./.claude/onboarding-meta.json`.

Important: the meta-file's `skills_used` field is a list. The merge rule in `write-meta.md` dedupes and preserves first-seen order — so running graphify-setup on top of an existing setup APPENDS `graphify-setup` to `skills_used` without overwriting the primary `setup_type`. This is the intended behavior for `/upgrade-setup` to later refresh graphify blocks alongside host-setup blocks.

## Step 6: Completion summary

Print one of the following blocks based on the variables set by the shared protocol:

### Success

```
✓ Graphify setup complete!

Installed via:     [uv | pipx]
Slash command:     /graphify  (query / path / explain)
PreToolUse hook:   [✓ verified in .claude/settings.json | ⚠ not verified — run /graphify in a new session to confirm]
Initial build:     [✓ ran graphify . on this project | — skipped, run `graphify .` when ready | ⚠ failed — retry manually]
Git auto-update:   [✓ installed (runs on commit) | — skipped | ⚠ install failed]

Files updated:
  CLAUDE.md                     — pointer block (delimited section, setup=<host_setup_slug>)
  .claude/onboarding-meta.json  — skills_used now includes graphify-setup

Next:
  - Try: /graphify query "where does auth happen in this repo?"
  - For mixed-media corpora: drop files into the project and re-run `graphify .` to re-index.
  - Upstream docs: https://graphify.net/graphify-claude-code-integration.html
```

### Prerequisite failure (Python < 3.10, or neither uv nor pipx available, or `uv tool install` non-zero)

```
— Graphify skipped

Reason: [Python < 3.10 | neither uv nor pipx available | `<installer> install graphifyy` exited non-zero | `graphify install` failed]

Fix:
  [Upgrade Python from https://www.python.org/downloads/ or `uv python install 3.12`]
  [Install uv: https://docs.astral.sh/uv/getting-started/installation/]
  [Install pipx: https://pipx.pypa.io/stable/installation/]
  [See upstream docs: https://github.com/safishamsi/graphify#installation]

Then re-run: /graphify-setup

No Claude config was changed. You can continue using the host setup that was already applied.
```

### Deferred (if invoked via handoff in "later" mode)

```
— Graphify deferred

Nothing installed. A short pointer was added to CLAUDE.md so you can run /graphify-setup when ready.
```
