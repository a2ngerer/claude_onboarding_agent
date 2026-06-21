---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-06-21
sources:
  - https://docs.claude.com/en/docs/claude-code/hooks
  - https://docs.claude.com/en/docs/claude-code/settings
  - https://docs.claude.com/en/docs/claude-code/plugins
  - https://docs.claude.com/en/docs/claude-code/slash-commands
  - https://docs.claude.com/en/docs/claude-code/memory
version: 3
---

## Memory files

- `CLAUDE.md` — project instructions at `./CLAUDE.md` or `./.claude/CLAUDE.md`; user-level at `~/.claude/CLAUDE.md`. Loaded every session.
- `CLAUDE.local.md` — personal project notes; gitignored, appended after `CLAUDE.md`.
- `AGENTS.md` — not read natively by Claude Code. Import with `@AGENTS.md` from `CLAUDE.md`.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- Modular rules: `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob.
- Imports: `@path/to/file` pulls a file into context at launch (max depth 4).
- **Auto memory**: Claude saves learnings to `~/.claude/projects/<repo>/memory/MEMORY.md`. First 200 lines loaded each session. Toggle via `autoMemoryEnabled`; custom path via `autoMemoryDirectory`.

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `enforceAvailableModels`, `attribution`, `language`, `disableBundledSkills`, `disableWorkflows`, `footerLinksRegexes`, `autoMemoryEnabled`, `autoMemoryDirectory`. Permission rules: `deny → ask → allow`; first match wins.

- **`fallbackModel`** — up to three fallbacks tried in order when primary model is unavailable.
- **`attribution`** — customizes git commit/PR attribution; replaces deprecated `includeCoAuthoredBy`.
- **`language`** — preferred response language (also controls session title language).
- **`enforceAvailableModels`** — rejects model IDs not in account allowlist at startup.

**Safe mode:** `--safe-mode` flag or `CLAUDE_CODE_SAFE_MODE=1` disables CLAUDE.md, plugins, skills, hooks, and MCP servers.

## Hooks

| Event | Typical use |
|---|---|
| `SessionStart` | Load context/env; can return `reloadSkills`, `sessionTitle`, `watchPaths` |
| `Setup` | One-time initialization with `--init-only` |
| `SessionEnd` | Release resources or save artifacts |
| `UserPromptSubmit` | Validate or enrich the prompt |
| `UserPromptExpansion` | React to slash command expansion |
| `Stop` | Cleanup after turn; return `additionalContext` to continue turn |
| `StopFailure` | Handle API-error turn end |
| `PreToolUse` | Block or gate a tool call |
| `PostToolUse` | Lint or log after tool runs; `continueOnBlock: true` feeds rejection to Claude |
| `PostToolUseFailure` | React to failed tool call |
| `PostToolBatch` | React after full parallel tool batch |
| `PermissionRequest` | Gate a permission dialog; return `decision.behavior` to allow/deny |
| `PermissionDenied` | React to auto-denied call; `retry: true` re-allows |
| `SubagentStart` | Set up newly spawned subagent |
| `SubagentStop` | React to subagent finish; `additionalContext` continues turn |
| `TaskCreated` | React to task creation |
| `TaskCompleted` | React to task completion |
| `TeammateIdle` | React to idle agent-team member |
| `FileChanged` | React to watched file change |
| `CwdChanged` | React to working directory change |
| `ConfigChange` | React to config file change |
| `InstructionsLoaded` | React to CLAUDE.md/rules load; inspect `load_reason` |
| `WorktreeCreate` | Set up fresh worktree (install deps, copy env) |
| `WorktreeRemove` | Clean up after worktree deletion |
| `PreCompact` | Save state before context compaction |
| `PostCompact` | Re-inject context after compaction |
| `MessageDisplay` | Transform message text before display; return `displayContent` |
| `Elicitation` | Handle MCP server user-input request |
| `ElicitationResult` | React to elicitation response |

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]`. Handler types: `command`, `http`, `mcp_tool`, `prompt`, `agent`. Output field `terminalSequence` sends desktop notifications/window titles. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills and custom commands merged. Project skills: `.claude/skills/<name>/SKILL.md`; user: `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` still works.
- Plugin skills namespaced: `/<plugin-name>:<skill-name>`.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… (positional), named via `arguments:` frontmatter.
- `/reload-skills` — hot-reload. `/cd <path>` — change session directory. `/config key=value` — set any setting inline.
- `/goal <condition>` — Claude keeps working until condition is met.
- `/memory` — browse and edit CLAUDE.md, rules, and auto memory files.
- `/plugin list` — list installed plugins. `claude plugin init` — scaffold new plugin. `claude agents` — list subagents.

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `argument-hint` | Short placeholder shown in autocomplete |
| `allowed-tools` | Tool whitelist for skill invocation |
| `disallowed-tools` | Tools removed from skill's allowed set |
| `model` | Override model (`fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low` / `normal` / `high` thinking budget |
| `context: fork` | Run skill in forked context |
| `context: agent` | Run skill as full subagent turn |
| `paths` | Glob list — load only when CWD matches |
| `disable-model-invocation` | Run command without calling model |
| `user-invocable` | `false` hides from `/` autocomplete |

## Plugins
- Manifest: `.claude-plugin/plugin.json` with `name`, `version`, `description`, optional `author`, `displayName`, `defaultEnabled`, `dependencies`.
- Components at plugin root (not inside `.claude-plugin/`): `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/`, `settings.json`.
- A single-skill plugin may place `SKILL.md` at plugin root instead of a `skills/` directory.
- `/reload-plugins` picks up local edits. Version every release.

## Recommendations
- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail via `@imports` or `.claude/rules/`.
- Prefer skills over fat `CLAUDE.md` sections for multi-step procedures or infrequently-invoked content.
- Use a `PostToolUse` hook to run linters after `Write`/`Edit` rather than instructing Claude.
- Scope permissions explicitly; namespace plugin skills to avoid collisions.

## Deprecated patterns
- Do not stuff templates or tool references into `CLAUDE.md` — use `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md`.
- Do not use `includeCoAuthoredBy`; use `attribution` instead.
