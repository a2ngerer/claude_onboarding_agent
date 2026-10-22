---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-10-22
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
- `AGENTS.md` — read natively (v2.1.277+) only when no `CLAUDE.md`/`CLAUDE.local.md` exists in or above the working directory; otherwise only the `CLAUDE.md` files load. To use both, `CLAUDE.md` imports it with `@AGENTS.md`.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 4 hops).

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `enforceAvailableModels`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — model to use when the primary `model` is unavailable or rate-limited.
- **`requiredMinimumVersion`** — semver string; Claude Code refuses to run if the installed version is older.
- **`enforceAvailableModels`** — boolean; when `true`, rejects model IDs not available in the current account/tier at startup rather than failing at runtime.

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI environments or troubleshooting a broken config.

## Hooks

Claude Code supports 32 hook events. Common ones, grouped:

- **Session:** `SessionStart` (load context/env), `Setup`, `SessionEnd` (release resources).
- **Per turn:** `UserPromptSubmit` (validate/enrich; runs before skills expand), `UserPromptExpansion`, `Stop`, `StopFailure`.
- **Tool calls:** `PreToolUse` (block/gate), `PermissionRequest`, `PermissionDenied`, `PostToolUse` (lint/log), `PostToolUseFailure`, `PostToolBatch`, `Elicitation`, `ElicitationResult`.
- **Subagents/tasks:** `SubagentStart`, `SubagentStop`, `TaskCreated`, `TaskCompleted`, `TeammateIdle`.
- **Context/config:** `InstructionsLoaded`, `ConfigChange`, `CwdChanged`, `DirectoryAdded`, `FileChanged`.
- **Worktrees:** `WorktreeCreate`, `WorktreeRemove`.
- **Compaction/models:** `PreCompact`, `PostCompact`, `PreModelSwitch`, `PostModelSwitch`.
- **Display:** `Notification`, `MessageDisplay`.

Command and HTTP hooks accept `onFailure: "block"` (v2.1.295+): a hook that fails to start, times out, or exits unexpectedly then blocks the action.

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, command }` entries. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- `/reload-skills` — hot-reload skill/command files without restarting the session.
- `/cd <path>` — change the working directory for the current session.
- `/doctor` (also `claude doctor`) — setup checkup; `/skill-doctor` reports which skills cost context and go unused.
- `/plugin list` — list installed plugins and their status.
- `claude plugin init` — scaffold a new plugin in the current directory (CLI, not a slash command).
- `claude agents` — list all available named subagents (CLI).

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `allowed-tools` | Comma-separated tool whitelist for this skill's invocation |
| `model` | Override model for this skill (accepts aliases: `fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low` / `medium` / `high` / `xhigh` / `max` — effort level while the skill is active |
| `context: fork` | Run the skill in a forked subagent; pick the type with `agent:` (`Explore`, `Plan`, `general-purpose`) |
| `when_to_use` | Extra trigger phrases appended to `description` (combined text truncated at 1,536 chars) |
| `disallowed-tools` | Tools removed from Claude's pool while the skill is active |
| `paths` | Glob list — load this skill only when CWD matches |
| `disable-model-invocation` | `true` — only the user can invoke the skill (use for side-effect workflows like deploys) |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; only Claude invokes it |

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`, `displayName`, `defaultEnabled`, `dependencies`.
  - `displayName` — human-readable name shown in the marketplace and `/plugin list`.
  - `defaultEnabled` — boolean; whether the plugin activates on install without user opt-in.
  - `dependencies` — list of other plugin names that must be installed for this plugin to function.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `settings.json`.
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
- Pin plugin versions in team repos; run `/reload-plugins` after edits instead of restarting.
- Namespace plugin skills; never rely on a collision-prone flat name.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not assume `AGENTS.md` loads next to `CLAUDE.md` — it is read directly only when no `CLAUDE.md` exists; otherwise import it with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md` so supporting files and frontmatter are available.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
