---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-05-22
sources:
  - https://docs.claude.com/en/docs/claude-code/hooks
  - https://docs.claude.com/en/docs/claude-code/settings
  - https://docs.claude.com/en/docs/claude-code/plugins
  - https://docs.claude.com/en/docs/claude-code/slash-commands
  - https://docs.claude.com/en/docs/claude-code/memory
version: 2
---

## Memory files

- `CLAUDE.md` — project instructions at `./CLAUDE.md` or `./.claude/CLAUDE.md`; user-level at `~/.claude/CLAUDE.md`. Loaded into every session.
- `CLAUDE.local.md` — personal project notes; gitignored, appended after `CLAUDE.md`.
- `AGENTS.md` — not read natively by Claude Code. If the repo needs both, `CLAUDE.md` imports it with `@AGENTS.md`.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 5).

## Settings

Notable top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `tui`, `effortLevel`, `alwaysThinkingEnabled`, `worktree.baseRef`, `worktree.bgIsolation`, `skillOverrides`, `prUrlTemplate`, `channelsEnabled`, `wslInheritsWindowsSettings`, `parentSettingsBehavior`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

## Hooks

| Event | Typical use |
|---|---|
| `SessionStart` | Load context or env vars on session open |
| `Setup` | One-time dependency installation (fires on `--init`) |
| `UserPromptSubmit` | Validate or enrich the user prompt |
| `UserPromptExpansion` | Block or approve slash command expansion |
| `PreToolUse` | Block or gate a tool call before execution |
| `PermissionRequest` | Auto-approve or customize permission dialogs |
| `PermissionDenied` | Handle auto-mode denials |
| `PostToolUse` | Lint or log after a tool runs; set `continueOnBlock: true` to feed rejection reason back to Claude |
| `PostToolUseFailure` | Handle tool failures and log errors (receives `duration_ms`) |
| `PostToolBatch` | React when all parallel tools in a batch complete |
| `Stop` | Validate Claude's response when a turn finishes |
| `StopFailure` | Handle turns that end due to API errors |
| `SubagentStart` | Monitor subagent spawning (receives `agent_id`, `agent_type`) |
| `SubagentStop` | Monitor subagent completion |
| `CwdChanged` | Reactive env management (direnv-style) |
| `PreCompact` / `PostCompact` | Pre/post context compaction hooks |
| `SessionEnd` | Release resources or save artifacts on session end |

Hook **types**: `command` (shell), `http`, `mcp_tool` (call an MCP server tool directly), `prompt`, `agent`.

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, command }` entries. Plugins ship hooks in `hooks/hooks.json`.

**New fields (since April 2026):**
- `args: string[]` — exec form for `command` hooks; spawns directly without a shell, no quoting issues.
- `asyncRewake: true` — run hook in background; wakes Claude on exit code 2 with stderr as a system reminder.
- `terminalSequence` — emit terminal escape sequences (notifications, bells) without `/dev/tty` access.
- `duration_ms` — available in `PostToolUse`/`PostToolUseFailure` input payloads.
- `effort.level` — current effort level available to all tool-use-event hooks; also in `$CLAUDE_EFFORT`.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `settings.json`.
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Use a `PostToolUseFailure` hook to alert or log when tools fail unexpectedly.
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
- Pin plugin versions in team repos; run `/reload-plugins` after edits instead of restarting.
- Namespace plugin skills; never rely on a collision-prone flat name.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md` so supporting files and frontmatter are available.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
