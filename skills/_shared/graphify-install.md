# Graphify Install Protocol

This file is read by `graphify-setup` AND by host setup skills (coding-setup, knowledge-base-setup, research-setup, data-science-setup, web-development-setup) when the user opts into the Graphify knowledge-graph integration.

Graphify (https://github.com/safishamsi/graphify) is an open-source knowledge-graph tool for AI coding assistants. It indexes code (25 languages via tree-sitter), Markdown, PDFs, diagrams, images, and audio/video into a local graph, and — once installed — registers a `/graphify` slash command and a PreToolUse hook that consults the graph before file-search tool calls, reducing token cost for the caller.

Follow every step in order. Never silently fall back to `pip install` — this repo is `uv`-first; `pipx` is an explicit fallback only.

## Inputs (set by the calling skill before reading this file)

- `host_setup_slug` — one of `coding`, `data-science`, `knowledge-base`, `research`, `web-development`, or `graphify` when graphify-setup runs standalone. Used as the `setup=<slug>` attribute on the CLAUDE.md marker.
- `host_skill_slug` — the directory name of the calling skill under `skills/` (`coding-setup`, `knowledge-base-setup`, …, or `graphify-setup`).
- `run_initial_build` — boolean. If `true`, the protocol offers to run `graphify .` on the current project after install.
- `install_git_hook` — boolean. If `true`, the protocol runs `graphify hook install` to auto-update the graph on commits.

If the calling skill has not set these, treat them as: `host_setup_slug: "graphify"`, `host_skill_slug: "graphify-setup"`, `run_initial_build: false`, `install_git_hook: false`, and re-ask during the standalone flow.

## Step G1 — Prerequisite: Python >= 3.10

Run `python3 --version` via Bash.

- If the output parses and the version is >= 3.10: set `python_ok: true` and continue.
- Otherwise: set `python_ok: false`, print ONCE:

  > "⚠ Graphify needs Python >= 3.10. Detected: [output or 'not found']. Install a newer Python from https://www.python.org/downloads/ (or `uv python install 3.12`) and re-run. Skipping Graphify installation."

  Stop the protocol and set `graphify_installed: false`. The calling skill continues with the rest of its steps unaffected.

## Step G2 — Prerequisite: `uv` or `pipx`

Probe the installers in this order:

1. Run `uv --version`. If it succeeds, set `installer: uv`.
2. Else run `pipx --version`. If it succeeds, set `installer: pipx`. Warn once:

   > "Note: `uv` is not installed — falling back to `pipx` for Graphify. For this project's `uv`-first convention, install `uv` (https://docs.astral.sh/uv/getting-started/installation/) and re-run to switch."

3. Else: set `installer: none`, print:

   > "⚠ Neither `uv` nor `pipx` is available. Install one of them first:
   >   - uv (recommended): https://docs.astral.sh/uv/getting-started/installation/
   >   - pipx (fallback):  https://pipx.pypa.io/stable/installation/
   > Never install Graphify with `pip` directly — it pollutes the system Python. Skipping Graphify installation."

   Stop the protocol and set `graphify_installed: false`.

Never auto-install `uv` or `pipx`. Never try `pip install graphifyy`.

## Step G3 — Install the `graphifyy` package

Run the matching command via Bash and show the output to the user:

- `installer: uv` → `uv tool install graphifyy`
- `installer: pipx` → `pipx install graphifyy`

If the command exits non-zero:

- Print: `"⚠ Graphify install failed (exit <code>). Manual install: https://github.com/safishamsi/graphify#installation — then re-run the graphify step. Setup continues without Graphify."`
- Set `graphify_installed: false` and stop the protocol.

On success, set `graphify_installed: true` and continue.

## Step G4 — Register slash command and PreToolUse hook

Run `graphify install` via Bash. This registers:

- The `/graphify` slash command with Claude Code.
- A PreToolUse hook that consults the local graph before file-search tool calls (Grep, Glob, Read, …), reducing token cost.

If the command exits non-zero, print:

> "⚠ `graphify install` failed (exit <code>). The package is installed but the slash command / PreToolUse hook are not registered. Fix manually: run `graphify install` yourself, or see https://graphify.net/graphify-claude-code-integration.html. Continuing without the hook."

Set `graphify_hook_registered: false` and continue — the rest of the protocol still runs.

On success, set `graphify_hook_registered: true`.

## Step G5 — Verify the hook and slash command

Read the active Claude settings file (prefer project-local, fall back to global):

- `./.claude/settings.json`
- `~/.claude/settings.json`

Grep for the substring `graphify`. If at least one of the settings files contains it, set `graphify_verified: true` and print `"✓ Graphify hook + slash command registered."`.

If neither file mentions `graphify`, set `graphify_verified: false` and print:

> "⚠ Could not find `graphify` in `.claude/settings.json` or `~/.claude/settings.json`. The registration may still be elsewhere in your Claude config — run `/graphify` in a new session to confirm. If it is missing, re-run `graphify install`."

Do not block. Continue.

## Step G6 — Optional: initial build

Only run this step if `run_initial_build: true`.

Ask ONCE (adapt to detected language): `"Run the initial graph build on this project now? This indexes the current directory via tree-sitter + Markdown/PDF parsers. Large corpora can take a few minutes. (yes / no)"`

- `yes` → run `graphify .` via Bash. Show the user the output. If it exits non-zero, print `"⚠ Initial build failed — you can re-run `graphify .` later."` and continue.
- `no` → print `"Skipped. Run `graphify .` manually when ready."`

Set `graphify_initial_build: yes|no|failed`.

## Step G7 — Optional: git auto-update hook

Only run this step if `install_git_hook: true` AND the current directory contains a `.git/` folder.

Ask ONCE: `"Install the git auto-update hook? Runs `graphify` automatically after each commit so the graph stays in sync. (yes / no)"`

- `yes` → run `graphify hook install` via Bash. If it exits non-zero, print `"⚠ `graphify hook install` failed — install manually later."` and continue.
- `no` → print `"Skipped. Run `graphify hook install` manually when ready."`

Set `graphify_git_hook: yes|no|failed`.

## Step G8 — Append CLAUDE.md pointer (attributed delimited section)

Resolve the target file: `./CLAUDE.md` in the current working directory.

Never silently overwrite the whole file. Instead append — or replace-in-place — the following delimited section. The `setup=<host_setup_slug>` attribute lets the block sit under any host setup; the `skill=graphify-setup` attribute marks it as owned by the graphify skill so `/upgrade-setup` can refresh it.

```
<!-- onboarding-agent:start setup=<host_setup_slug> skill=graphify-setup section=graphify -->
## Knowledge Graph (Graphify)

Graphify is installed and its PreToolUse hook consults a local graph before file-search tool calls.

- `/graphify query "<question>"` — ask the graph a question in natural language
- `/graphify path <from> <to>`  — shortest path between two symbols, files, or concepts
- `/graphify explain <symbol>`  — summarize a symbol, note, or file using graph context

Rebuild the graph with `graphify .` after large refactors. The git hook keeps it fresh on commit if you installed it.

Upstream: https://github.com/safishamsi/graphify · https://graphify.net/graphify-claude-code-integration.html
<!-- onboarding-agent:end -->
```

Rules:

- If a section with the SAME triple `(setup=<host_setup_slug>, skill=graphify-setup, section=graphify)` already exists, replace the body between its markers in place. Do not duplicate.
- If CLAUDE.md does not exist yet, create it with a one-line title and this section — host skills running before this protocol normally create CLAUDE.md themselves; graphify-setup running standalone may be the sole creator.
- Never remove or rewrite content outside these markers.

### "later" variant

If the calling skill invoked this protocol in "later" mode (user said `later`, not `yes`), skip Steps G1–G7 entirely and write ONLY this shorter pointer in Step G8 instead:

```
<!-- onboarding-agent:start setup=<host_setup_slug> skill=graphify-setup section=graphify -->
## Knowledge Graph (Graphify) — deferred

Knowledge graph: run `/graphify-setup` when ready to install Graphify and wire up the PreToolUse hook.

Upstream: https://github.com/safishamsi/graphify
<!-- onboarding-agent:end -->
```

The "later" variant does not set `graphify_installed: true`. It only records intent for the user.

## Step G9 — Return status to the calling skill

After this protocol ends, the calling skill should include one of the following lines in its own completion summary, based on the variables set above:

- `graphify_installed: true`, `graphify_verified: true` → `"✓ Graphify installed via <installer>, hook + /graphify command registered."`
- `graphify_installed: true`, `graphify_verified: false` → `"⚠ Graphify installed via <installer>, but the hook could not be verified in .claude/settings.json — run /graphify in a new session to confirm."`
- `graphify_installed: false` (prerequisite failure) → `"— Graphify skipped: <reason>. Re-run /graphify-setup once the prerequisites are fixed."`
- "later" mode → `"— Graphify deferred. Run /graphify-setup when ready."`
