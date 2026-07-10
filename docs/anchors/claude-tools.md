---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-07-10
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
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 4 hops).
- **Auto memory** — separate from CLAUDE.md: Claude writes its own notes at `~/.claude/projects/<project>/memory/`, entrypoint `MEMORY.md` (first 200 lines / 25KB loaded every session; topic files load on demand). CLAUDE.md is instructions you write; auto memory is learnings Claude accumulates. Toggle with `autoMemoryEnabled` or via `/memory`.

## Settings

`.claude/settings.json` has grown a large key surface; the ones most relevant to this plugin's configs are `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `requiredMaximumVersion`, `enforceAvailableModels`, `availableModels`, `disabledMcpjsonServers`/`enabledMcpjsonServers`, `autoMemoryEnabled`/`autoMemoryDirectory`, `effortLevel`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — model to use when the primary `model` is unavailable or rate-limited (accepts a chain of up to 3).
- **`requiredMinimumVersion`** / **`requiredMaximumVersion`** — semver strings; Claude Code refuses to run outside this range.
- **`enforceAvailableModels`** / **`availableModels`** — restrict which model IDs users/subagents can select; rejects excluded IDs at startup rather than failing at runtime.
- **`disabledMcpjsonServers`** / **`enabledMcpjsonServers`** — approve or reject individual servers from a project's `.mcp.json` without touching the file.
- **`autoMemoryEnabled`** / **`autoMemoryDirectory`** — toggle or relocate Claude's auto memory (see Memory files above).

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI environments or troubleshooting a broken config.

## Hooks

Claude Code ships ~31 hook events (plus `TeammateIdle` for agent teams); the table below groups the ones worth wiring up.

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` / `Setup` / `SessionEnd` | Load context on open, react to `--init`/`--maintenance`, release resources on close | Inject current git branch |
| `InstructionsLoaded` | React to what triggered loading; inspect `load_reason` | Log which skills were loaded |
| `UserPromptSubmit` / `UserPromptExpansion` | Validate/enrich a prompt, or react when a typed command expands into one | Block secret patterns |
| `PreToolUse` / `PermissionRequest` / `PermissionDenied` | Block or gate a tool call before it runs | Deny `Bash(rm -rf *)` |
| `PostToolUse` / `PostToolUseFailure` / `PostToolBatch` | Lint or log after a tool call succeeds, fails, or a parallel batch resolves | Auto-run `eslint --fix` after `Edit` |
| `SubagentStart` / `SubagentStop` / `TaskCreated` / `TaskCompleted` | React to subagent or Task lifecycle | Log subagent spawns |
| `ConfigChange` / `CwdChanged` / `FileChanged` | React to config, directory, or watched-file changes | Reload derived config |
| `PreCompact` / `PostCompact` | Save/restore state around context compaction | Checkpoint session notes |
| `WorktreeCreate` / `WorktreeRemove` | Set up or clean up a worktree | `npm ci` in the new branch |
| `Elicitation` / `ElicitationResult` | Handle or auto-respond to an MCP server's input request | Auto-approve a known prompt |
| `Notification` / `MessageDisplay` | React to or annotate a notification/message before it's shown | Inject a reminder banner |
| `Stop` / `StopFailure` | Cleanup when a turn ends normally or on API error | Persist session notes |

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of handler entries; plugins ship hooks in `hooks/hooks.json`; skills and agents can also scope hooks in their own frontmatter. Handler `type` is one of `command` (shell, JSON via stdin), `http`, `mcp_tool`, `prompt` (ask Claude yes/no), or `agent` (spawn a subagent to verify).

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- `/reload-skills` — re-scan skill/command directories for on-disk changes, no restart needed.
- `/reload-plugins [--force]` — reload active plugins (skills, agents, hooks, MCP/LSP servers) after local edits.
- `/doctor` (alias `/checkup`) — bundled-skill setup checkup: diagnoses install/config issues, finds unused skills/MCP servers, can pre-approve safe read-only commands.
- `/cd <path>` — change the working directory for the current session, preserving prompt cache.
- `/plugin list` — list installed plugins and their status.
- `claude plugin init` — scaffold a new plugin in the current directory (CLI, not a slash command).
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
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `settings.json`, `bin/` (executables added to the Bash tool's `PATH` while the plugin is enabled).
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
- Pin plugin versions in team repos; run `/reload-plugins` after edits instead of restarting. Namespace plugin skills; never rely on a collision-prone flat name.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md` so supporting files and frontmatter are available.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
