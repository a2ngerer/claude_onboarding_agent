---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-08-20
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
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 4).
- Auto memory (separate from CLAUDE.md): Claude's own notes at `~/.claude/projects/<project>/memory/`, entry point `MEMORY.md` (first 200 lines / 25KB loaded every session), topic files loaded on demand.

## Settings

Key top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `enforceAvailableModels`, `autoMemoryEnabled`, `autoMemoryDirectory`.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **Scope precedence:** managed policy > CLI flags > `.claude/settings.local.json` > `.claude/settings.json` > `~/.claude/settings.json`. `permissions.allow` / `.deny` / `.ask` arrays merge (union) across scopes rather than one scope replacing another; a `deny` match in any scope wins regardless of `allow` rules elsewhere.
- **`fallbackModel`** — model to use when the primary `model` is unavailable or rate-limited.
- **`ANTHROPIC_DEFAULT_MODEL`** (env var) — sets the model for new sessions; an explicit `/model` pick overrides it.
- **`requiredMinimumVersion`** — semver string; Claude Code refuses to run if the installed version is older.
- **`enforceAvailableModels`** — boolean; when `true`, rejects model IDs not available in the current account/tier at startup rather than failing at runtime.

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI environments or troubleshooting a broken config.

## Hooks

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` (`matcher` + `{ type, command }` entries), in a plugin's `hooks/hooks.json`, or scoped to one skill/subagent via its own frontmatter `hooks:` field.

| Event | Typical use |
|---|---|
| `SessionStart` / `SessionEnd` | Load or release context/env vars at session boundaries |
| `InstructionsLoaded` | React to what triggered CLAUDE.md/rules loading (`load_reason`) |
| `UserPromptSubmit` | Validate or enrich the user prompt |
| `PreToolUse` / `PostToolUse` | Block or gate a tool call; lint/log after it succeeds |
| `PostToolBatch` | React after a full parallel tool batch resolves |
| `SubagentStart` / `SubagentStop` | React to a subagent spawning or finishing |
| `PermissionRequest` / `PermissionDenied` | React to a permission decision |
| `PreCompact` / `PostCompact` | Save state before, reload it after context compaction |
| `WorktreeCreate` / `WorktreeRemove` | Set up or clean up a git worktree |
| `Stop` | Cleanup when Claude finishes a turn |

Claude Code ships roughly 30 hook events in total (session, turn, tool, subagent, file/directory, config, and MCP-elicitation categories) — check the official hooks reference before assuming a niche event doesn't exist.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work identically.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), `$name` (named, via `arguments:` frontmatter).
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- `/reload-skills` — hot-reload skill/command files without restarting the session.
- `/cd <path>` — change the working directory for the current session.
- `/plugin list` — list installed plugins and their status.
- `claude plugin init` — scaffold a new plugin in the current directory (CLI, not a slash command).
- `claude agents` — list all available named subagents (CLI).

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `arguments` | Named positional args for `$name` substitution (space-separated string or YAML list) |
| `allowed-tools` | Tool whitelist granted for the invoking turn only; clears on the next message |
| `disallowed-tools` | Tools removed from Claude's pool while this skill is active |
| `model` | Override model for this skill's turn (accepts aliases: `fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low` / `medium` / `high` / `xhigh` / `max` — hint to the model's thinking budget |
| `context: fork` | Run the skill in a forked subagent context (isolated from main conversation) |
| `agent` | Which subagent type to use when `context: fork` is set |
| `background` | With `context: fork`, run in the background (default `true`) or wait for the result |
| `hooks` | Hooks registered when the skill is invoked, active for the rest of the session |
| `paths` | Glob list — auto-load this skill only when CWD/files match |
| `disable-model-invocation` | `true` — only you can invoke the skill; Claude never triggers it automatically |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; only Claude can invoke it |
| `shell` | `bash` (default) or `powershell` for inline `` !`command` `` blocks |

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`, `displayName`, `defaultEnabled`, `dependencies`.
  - `displayName` — human-readable name shown in the marketplace and `/plugin list`.
  - `defaultEnabled` — boolean; whether the plugin activates on install without user opt-in.
  - `dependencies` — list of other plugin names that must be installed for this plugin to function.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/`, `settings.json`.
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
- Pin plugin versions in team repos; run `/reload-plugins` after edits instead of restarting.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md` so supporting files and frontmatter are available.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
