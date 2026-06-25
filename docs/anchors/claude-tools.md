---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-06-25
sources:
  - https://docs.claude.com/en/docs/claude-code/hooks
  - https://docs.claude.com/en/docs/claude-code/settings
  - https://docs.claude.com/en/docs/claude-code/plugins
  - https://docs.claude.com/en/docs/claude-code/slash-commands
  - https://docs.claude.com/en/docs/claude-code/memory
version: 3
---

## Memory files

- `CLAUDE.md` — project instructions at `./CLAUDE.md` or `./.claude/CLAUDE.md`; user-level at `~/.claude/CLAUDE.md`. Loaded into every session.
- `CLAUDE.local.md` — personal project notes; gitignored, appended after `CLAUDE.md`.
- `AGENTS.md` — not read natively by Claude Code. If the repo needs both, `CLAUDE.md` imports it with `@AGENTS.md`.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 5).

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `requiredMaximumVersion`, `enforceAvailableModels`, `language`, `effortLevel`, `alwaysThinkingEnabled`, `autoMemoryEnabled`, `autoMemoryDirectory`, `disableBundledSkills`, `disableWorkflows`, `attribution`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

- **`fallbackModel`** — model (or ordered list of up to 3) to use when the primary `model` is unavailable.
- **`requiredMinimumVersion` / `requiredMaximumVersion`** — semver bounds; Claude Code refuses to run outside the range.
- **`enforceAvailableModels`** — rejects model IDs not in the account allowlist at startup.
- **`language`** / **`effortLevel`** — preferred response language; persist effort level (`"low"`, `"medium"`, `"high"`, `"xhigh"`).
- **`autoMemoryEnabled`** / **`autoMemoryDirectory`** — control auto memory; custom storage path.
- **`disableBundledSkills`** / **`disableWorkflows`** — hide bundled skills or the dynamic workflow system.

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers.

## Hooks

| Event | Typical use |
|---|---|
| `SessionStart` | Load context or env vars on session open; set `sessionTitle`, `watchPaths`, `reloadSkills` |
| `Setup` | React to `--init` or `--maintenance` flag; prepare workspace on first run |
| `InstructionsLoaded` | React when CLAUDE.md or rules load; inspect `load_reason` |
| `UserPromptSubmit` | Validate or enrich the user prompt |
| `PreToolUse` | Block or gate a tool call; return `permissionDecision: allow/deny/ask` |
| `PostToolUse` | Lint or log after a tool runs; replace output with `updatedToolOutput` |
| `PostToolUseFailure` | Log or recover from a failed tool call |
| `PostToolBatch` | React after a full parallel tool batch completes |
| `PermissionRequest` | Grant or deny a permission dialog programmatically |
| `PermissionDenied` | React when auto-mode classifier blocks a tool |
| `MessageDisplay` | Intercept or annotate a message before it is shown |
| `SubagentStart` | Inject config or context when a subagent spawns |
| `SubagentStop` | Process subagent results before the turn continues |
| `FileChanged` | React when a watched file changes on disk (pair with `watchPaths` in `SessionStart`) |
| `PreCompact` | Save state before context compaction |
| `PostCompact` | Re-inject context after compaction |
| `WorktreeCreate` | Set up a fresh worktree (install deps, copy env) |
| `WorktreeRemove` | Clean up after a worktree is deleted |
| `Stop` | Cleanup when Claude finishes a turn |
| `SessionEnd` | Release resources or save artifacts |

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and `{ type, command }` entries. Types: `command`, `http`, `mcp_tool`, `prompt`, `agent`. Plugins ship hooks in `hooks/hooks.json`. Additional events (not shown): `UserPromptExpansion`, `CwdChanged`, `ConfigChange`, `Notification`, `Elicitation`, `ElicitationResult`, `TaskCreated`, `TaskCompleted`, `TeammateIdle`, `StopFailure` — see docs for full 30-event catalog.

## Slash commands

- Skills and custom commands are merged. Project skills at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>`.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… (positional), named args via `arguments:` frontmatter.
- `/reload-skills` — hot-reload skill/command files without restarting.
- `/cd <path>` — change the working directory for the current session.
- `/config key=value` — set any setting from prompt (e.g. `/config thinking=false`).
- `/plugin list` — list installed plugins and their status.
- `/workflows` — view dynamic workflow runs and status.
- `claude plugin init` — scaffold a new plugin (CLI).
- `claude agents` — list all available named subagents (CLI).

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `argument-hint` | Short placeholder shown in autocomplete |
| `allowed-tools` | Comma-separated tool whitelist for this skill |
| `disallowed-tools` | Comma-separated tools removed from model during this skill |
| `model` | Override model (`fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low` / `normal` / `high` — thinking budget hint |
| `context: fork/agent` | Run in a forked context or as a full subagent turn |
| `paths` | Glob list — load this skill only when CWD matches |
| `disable-model-invocation` | `true` — skill runs without calling the model |
| `user-invocable` | `false` — hide from `/` autocomplete |
| `default-enabled` | `false` — skill opt-in; not activated on plugin install |

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version`, `description`, optional `author`, `homepage`, `repository`, `defaultEnabled`, `dependencies`.
- Components at plugin root (not inside `.claude-plugin/`): `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/`, `settings.json`.
  - `monitors/` — background file/log watchers (`monitors/monitors.json`); each stdout line is delivered to Claude as a notification.
  - `bin/` — executables added to `PATH` while the plugin is enabled.
  - `settings.json` — default settings applied when enabled (currently supports `agent`, `subagentStatusLine`).
- `/reload-plugins` picks up local edits. `--plugin-dir` accepts a directory or `.zip` archive for testing.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference details via `@imports` or `.claude/rules/`.
- Prefer skills over fat `CLAUDE.md` sections for multi-step procedures or infrequently-used workflows.
- Use a `PostToolUse` hook to run linters/formatters after `Write`/`Edit` instead of instructing Claude.
- Scope permissions explicitly: allowlist safe commands, deny reads of secrets.

## Deprecated patterns

- Do not stuff templates or tool references into `CLAUDE.md` — move them to `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md`.
