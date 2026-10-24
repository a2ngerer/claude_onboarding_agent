---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-10-24
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

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `enforceAvailableModels`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — model to use when the primary `model` is unavailable or rate-limited.
- **`requiredMinimumVersion`** — semver string; Claude Code refuses to run if the installed version is older.
- **`enforceAvailableModels`** — boolean; when `true`, rejects model IDs not available in the current account/tier at startup rather than failing at runtime.

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI environments or troubleshooting a broken config.

## Hooks

| Event | Typical use |
|---|---|
| `SessionStart` / `Setup` / `SessionEnd` | Load context or env vars; one-time init; release resources |
| `UserPromptSubmit` / `UserPromptExpansion` | Validate or enrich a prompt; gate command expansion |
| `PreToolUse` / `PermissionRequest` / `PermissionDenied` | Block or gate a tool call (e.g. deny `Bash(rm -rf *)`); custom permission decisions |
| `PostToolUse` / `PostToolUseFailure` / `PostToolBatch` | Lint or log after a tool runs, fails, or a parallel batch resolves |
| `SubagentStart` / `SubagentStop` / `TaskCreated` / `TaskCompleted` / `TeammateIdle` | Track subagent and task lifecycle |
| `Stop` / `StopFailure` / `Notification` / `MessageDisplay` | Turn cleanup, API-error handling, notifications, message annotation |
| `InstructionsLoaded` / `ConfigChange` / `CwdChanged` / `DirectoryAdded` / `FileChanged` | React to loaded rules, config edits, directory or watched-file changes |
| `PreCompact` / `PostCompact` | Save state before / re-inject context after compaction |
| `PreModelSwitch` / `PostModelSwitch` | Gate (can block) or log model switches |
| `Elicitation` / `ElicitationResult` | Handle MCP server input requests |
| `WorktreeCreate` / `WorktreeRemove` | Set up / clean up worktrees (`WorktreeCreate` replaces default git behavior) |

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of handlers. Handler `type`: `command`, `http`, `mcp_tool`, `prompt`, or experimental `agent`; an `if` filter such as `"Bash(rm *)"` narrows a handler. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- `/reload-skills` — load skills from a top-level `.claude/skills/` created mid-session (existing skill dirs are watched).
- `/cd <path>` — move the session to another directory (v2.1.246+); `/add-dir` adds one and loads its skills.
- `/skill-doctor` — report each skill's context cost and usage; flags unused skills.
- `/plugin` — browse, install, and manage plugins.
- `claude plugin init` / `claude plugin eval` — scaffold a plugin / run plugin eval suites (CLI, not slash commands).
- `claude agents` — list all available named subagents (CLI).

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `allowed-tools` / `disallowed-tools` | Tools pre-approved for the turn / removed from the pool while the skill is active |
| `model` | Override model for this skill (accepts aliases: `fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low` / `medium` / `high` / `xhigh` / `max` — thinking effort hint |
| `context: fork` | Run the skill in a subagent; set `agent:` (e.g. `Explore`) to pick its type |
| `when_to_use` | Extra trigger phrases appended to `description` (combined listing capped at 1,536 chars) |
| `paths` | Glob list — limits automatic activation to matching files |
| `disable-model-invocation` | `true` — only the user can run it (`/name`); Claude will not invoke it |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; only callable programmatically |

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`, `displayName`, `defaultEnabled`, `dependencies`.
  - `displayName` — human-readable name shown in the marketplace and `/plugin list`.
  - `defaultEnabled` — boolean; whether the plugin activates on install without user opt-in.
  - `dependencies` — list of other plugin names that must be installed for this plugin to function.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `settings.json`.
- Version every release; users update through the marketplace. `/reload-plugins` picks up edits to plugin `hooks/`, `.mcp.json`, and `agents/`. Enabled plugins cost context every turn.

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
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md` so supporting files and frontmatter are available.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
