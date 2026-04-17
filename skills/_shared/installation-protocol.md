# Installation Protocol

This file is read by setup skills during their dependency installation step.
The calling skill declares which dependencies to install and their types.
Follow this protocol for each dependency in the declared order.

## Dependency Types

- **required** — always install; skip opt-in question
- **optional** — ask the user if they want it before proceeding
- **conditional** — gated on a boolean variable set by the skill before this protocol runs; skip if the condition is false; skip opt-in question

## Protocol Steps (run for each dependency in order)

### Step P1: Already-installed check

For plugins/skills (Superpowers, Karpathy Guidelines):
- Run `/plugin list` if available; check whether the plugin appears as installed. If `/plugin list` is unavailable or errors, fall back to filesystem check only.
- Also check filesystem: `~/.claude/plugins/<name>/` (global) and `.claude/plugins/<name>/` (project-local)
- If found by either method:
  - Tell the user: "Found [Name] already installed — skipping installation."
  - Set `<name>_installed: true`
  - Skip to next dependency

For MCPs (Obsidian MCP):
- Check `.claude/settings.json` for an existing entry under `mcpServers` with key `obsidian`
- If found:
  - Tell the user: "Found Obsidian MCP already configured — skipping."
  - Set `obsidian_mcp_installed: true`
  - Skip to next dependency

### Step P2: Opt-in / condition check

- **required**: skip this step, proceed to Step P3
- **optional**: ask "Would you like to install [Name]?" with a one-line description
  - If no: set `<name>_installed: false`, skip to next dependency
- **conditional**: check the boolean variable set by the skill (e.g. `obsidian_mcp_condition`)
  - If false: set `<name>_installed: false`, skip to next dependency
  - If true: proceed to Step P3

### Step P3: Scope (plugins/skills only — MCPs always skip to Step P5c)

Ask: "Install [Name] globally (`~/.claude`) or project-local (`.claude`)?"

- **global**: Marketplace and GitHub are both available → proceed to Step P4
- **local**: Only GitHub is available. Tell the user: "Project-local installs use GitHub only — the Plugin Marketplace only supports global installs." → skip Step P4, go to Step P5b

Store as `<name>_scope: global | local`.

### Step P4: Method (global scope only)

Ask: "Plugin Marketplace or GitHub?"

- **Marketplace**: run `/plugin install <marketplace-id>` → go to Step P5a
- **GitHub (global)**: `git clone <url> ~/.claude/plugins/<name>` → go to Step P5b

Store as `<name>_method: marketplace | github`.

### Step P5: Verify

- **P5a — Marketplace**: check via `/plugin list` that the plugin now appears. Set `<name>_method: marketplace`.
- **P5b — GitHub global**: check that `~/.claude/plugins/<name>/` exists. Set `<name>_method: github`, `<name>_scope: global`.
- **P5c — GitHub local**: `git clone <url> .claude/plugins/<name>`. Check that `.claude/plugins/<name>/` exists. Set `<name>_method: github`, `<name>_scope: local`.

On success: set `<name>_installed: true`.

On failure:
- Warn: "⚠ [Name] installation failed — setup continues without it. Install manually later."
- Set `<name>_installed: false`
- Never block — continue to the next dependency or the next skill step.

## Variable Reference

| Dependency          | `_installed`             | `_scope`            | `_method`            |
|---------------------|--------------------------|---------------------|----------------------|
| Superpowers         | `superpowers_installed`  | `superpowers_scope` | `superpowers_method` |
| Karpathy Guidelines | `karpathy_installed`     | `karpathy_scope`    | `karpathy_method`    |
| Obsidian MCP        | `obsidian_mcp_installed` | — (always local)    | — (always GitHub)    |
