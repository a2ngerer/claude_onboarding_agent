---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-09-20
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
- `AGENTS.md` — read natively by Claude Code (v2.1.277+) when no `CLAUDE.md`/`CLAUDE.local.md` exists in the working directory or above it (default mode `claude-md-or-agents-md`). Set the built-in `agents-md` plugin's `instructionFiles` option to `claude-md-and-agents-md` to always read both, or `claude-md` to ignore `AGENTS.md`.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 4 hops).

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `enforceAvailableModels`, `pluginConfigs`, `autoMemoryEnabled`, `skillOverrides`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — model to use when the primary `model` is unavailable or rate-limited.
- **`requiredMinimumVersion`** — semver string; Claude Code refuses to run if the installed version is older.
- **`enforceAvailableModels`** — boolean; when `true`, rejects model IDs not available in the current account/tier at startup rather than failing at runtime.
- **`skillOverrides`** — per-skill visibility: `"on"` (default), `"name-only"` (listed but no description sent to Claude), `"user-invocable-only"` (hidden from Claude), `"off"`.

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI environments or troubleshooting a broken config.

## Hooks

Claude Code supports 40+ hook events across five handler types: `command`, `http`, `mcp_tool`, `prompt`, and `agent`. Handlers live in `.claude/settings.json`, a plugin's `hooks/hooks.json`, or scoped to a single skill's or subagent's own frontmatter.

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` | Load context or env vars on session open | Inject current git branch |
| `InstructionsLoaded` | React to what triggered loading (new session, `/reload-plugins`, plugin install) | Log which skills were loaded |
| `UserPromptSubmit` | Validate or enrich the user prompt | Block secret patterns |
| `PreToolUse` / `PostToolUse` | Gate or lint around a tool call | Deny `Bash(rm -rf *)`; auto-lint after `Edit` |
| `PermissionRequest` / `PermissionDenied` | React to a permission decision | Log actions auto mode blocked |
| `SubagentStart` / `SubagentStop` | React to subagent lifecycle | Track subagent fan-out |
| `PreCompact` / `PostCompact` | Save/restore state around context compaction | Checkpoint session notes |
| `ConfigChange` | React to a settings-file edit mid-session | Re-validate config |
| `WorktreeCreate` / `WorktreeRemove` | Set up or clean up a worktree | `npm ci` in the new branch |
| `Stop` / `SessionEnd` | Cleanup when Claude finishes | Persist session notes |

Only `command` hooks take a `command` field; the `http`, `mcp_tool`, `prompt`, and `agent` types each have their own handler schema.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; `synced` is reserved for skills synced from claude.ai.
- `/reload-plugins` — hot-reload plugins, skills, agents, hooks, and plugin MCP/LSP servers without restarting; add `--force` to skip re-reading conversation. This replaced the older `/reload-skills`.
- `/skill-doctor` — see which skills are unused and their context cost.
- `/cd <path>` — change the working directory for the current session.
- `/plugin list` — list installed plugins and their status.
- `claude plugin init <name>` — scaffold a skills-directory plugin at `~/.claude/skills/<name>/`, auto-loaded from the next session (CLI, not a slash command).
- `claude agents` — list all available named subagents (CLI).

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `allowed-tools` | Comma-separated tool whitelist for this skill's invocation |
| `model` | Override model for this skill (accepts aliases: `fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low` / `normal` / `high` — hint to the model's thinking budget |
| `context: fork` | Run the skill in a forked context (isolated from main conversation) |
| `context: agent` | Run the skill as a full subagent turn |
| `paths` | Glob list — load this skill only when CWD matches |
| `disable-model-invocation` | `true` — skill runs its command without calling the model (pure automation) |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; only callable programmatically |

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
- Do not assume `AGENTS.md` needs an `@AGENTS.md` import to be read — Claude Code reads it natively by default now. Only add that import for sessions that can't load `AGENTS.md` directly (third-party providers, telemetry disabled) or when Claude-specific content must sit alongside it.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md` so supporting files and frontmatter are available.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
