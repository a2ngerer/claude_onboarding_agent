---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-11-22
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

Claude Code exposes ~33 hook events. Commonly used:

| Event | Typical use |
|---|---|
| `SessionStart` / `Setup` / `SessionEnd` | Load context or env on open; one-time prep with `--init`; flush on close |
| `UserPromptSubmit` / `UserPromptExpansion` | Validate or enrich a prompt; block a command expansion |
| `PreToolUse` / `PermissionRequest` / `PermissionDenied` | Gate a tool call; decide or log permission outcomes |
| `PostToolUse` / `PostToolUseFailure` / `PostToolBatch` | Lint or log after a tool runs, fails, or a parallel batch resolves |
| `SubagentStart` / `SubagentStop` / `TaskCreated` / `TaskCompleted` | Track delegated work |
| `Stop` / `StopFailure` | Cleanup when a turn ends or fails on an API error |
| `InstructionsLoaded` / `ConfigChange` / `CwdChanged` / `FileChanged` | React to loaded rules, settings edits, directory or file changes |
| `PreCompact` / `PostCompact` | Checkpoint before / re-inject context after compaction |
| `PreModelSwitch` / `PostModelSwitch` | Block or react to a model switch |
| `WorktreeCreate` / `WorktreeRemove` | Set up or clean a worktree |
| `Elicitation` / `ElicitationResult` | Handle MCP server input requests |

Handler types: `command`, `http`, `mcp_tool`, `prompt` (accepts model aliases like `haiku`), and experimental `agent`. Set `"onFailure": "block"` on `command`/`http`/`mcp_tool` handlers so a failed hook blocks the action instead of being non-blocking (it has no effect on `Stop`, `SubagentStop`, `TaskCompleted`, `TeammateIdle`).

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, command }` entries. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- `/reload-skills` — hot-reload skill files (live edits under `.claude/skills/` are also picked up automatically). `/skill-doctor` shows per-skill context cost.
- `/cd <path>` — change the working directory for the current session.
- `/plugin` — browse, install, and manage plugins (`claude plugin disable` from the shell).
- `claude plugin init` — scaffold a new plugin in the current directory (CLI, not a slash command).

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `allowed-tools` | Tools pre-approved for the invoking turn (does not restrict others); `disallowed-tools` removes tools while active |
| `model` | Override model for this skill (accepts aliases: `fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low` / `medium` / `high` / `xhigh` / `max` — effort level for the turn |
| `context: fork` | Run the skill in a subagent (isolated from main conversation); pick the type with `agent:` (`Explore`, `Plan`, `general-purpose`, custom) |
| `paths` | Glob list — load this skill only when CWD matches |
| `disable-model-invocation` | `true` — Claude never auto-loads the skill; only the user can invoke it (use for deploys and other side effects) |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; Claude can still use it as background knowledge |
| `when_to_use` | Extra trigger phrases appended to `description` (combined cap 1,536 chars) |

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
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md` so supporting files and frontmatter are available.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
