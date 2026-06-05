---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-06-05
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
- `AGENTS.md` — not read natively by Claude Code. Import with `@AGENTS.md` from `CLAUDE.md` if needed.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 5).

## Settings

Key top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `claudeMdExcludes`, `skillOverrides`, `parentSettingsBehavior`, `workflowKeywordTriggerEnabled`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

New keys: `skillOverrides` (hide/show individual skills), `workflowKeywordTriggerEnabled` (control the `ultracode` keyword trigger), `parentSettingsBehavior` (how managed settings merge), `effortLevel` (persist effort across sessions).

## Hooks

| Event | Typical use |
|---|---|
| `SessionStart` | Load context; can return `reloadSkills: true` or set `sessionTitle` |
| `SessionEnd` / `Stop` | Cleanup, save artifacts |
| `UserPromptSubmit` | Validate or enrich prompt; block secret patterns |
| `UserPromptExpansion` | Gate slash-command expansion; can block it |
| `PreToolUse` | Block or gate a tool call before execution |
| `PostToolUse` | Lint/log after a tool runs; `continueOnBlock` feeds rejection reason to Claude |
| `PostToolBatch` | After a parallel tool batch resolves, before next model call |
| `SubagentStart` / `SubagentStop` | Subagent lifecycle; `SubagentStop` can return `additionalContext` |
| `TaskCreated` / `TaskCompleted` | Background task lifecycle |
| `MessageDisplay` | Transform displayed assistant text (display-only; no blocking; 10s timeout) |
| `PreCompact` / `PostCompact` | Hook into context compaction |
| `ConfigChange` / `CwdChanged` | React to config or directory changes |
| `WorktreeCreate` / `WorktreeRemove` | Worktree lifecycle |
| `Elicitation` / `ElicitationResult` | MCP server requests user input |

Hook types: `command` (shell via stdin), `http` (POST endpoint), `mcp_tool`, `prompt` (LLM yes/no), `agent` (subagent with tools).
Hooks live under `hooks.<EventName>[]` in `settings.json`. Use `args: string[]` (exec form) to bypass the shell.

## Slash commands

- Skills at `.claude/skills/<name>/SKILL.md` (preferred) or legacy `.claude/commands/*.md`. User skills at `~/.claude/skills/`.
- Plugin skills namespaced: `/<plugin>:<skill>`.
- Key commands: `/ultracode` (trigger dynamic workflows), `/goal` (multi-turn completion condition), `/reload-skills` (re-scan without restart), `/agents` (manage subagents interactively).
- Arguments: `$ARGUMENTS`, `$0`/`$1`, or named via `arguments:` frontmatter. Name slugs: lowercase, digits, hyphens, ≤64 chars.

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`.
- Components at plugin root (not inside `.claude-plugin/`): `skills/`, `agents/`, `hooks/`, `.mcp.json`, `settings.json`.
- `defaultEnabled: false` requires user to run `/plugin enable` before the plugin activates.
- `/reload-plugins` or `/reload-skills` picks up local edits without restarting the session.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short, reference detail files via `@imports` or `.claude/rules/`.
- Prefer `skills/` over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook for linters/formatters after `Write`/`Edit` instead of prompting Claude to run them.
- Scope permissions explicitly: allowlist safe commands, deny reads of secrets.
- Use `skillOverrides` in managed settings to hide skills irrelevant to a project.

## Deprecated patterns

- Stuffing templates or multi-step procedures into `CLAUDE.md` — move to `skills/` or `.claude/rules/`.
- Placing `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/` — only `plugin.json` belongs there.
- Using `AGENTS.md` without importing it from `CLAUDE.md` via `@AGENTS.md`.
- Using legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md`.
- Silently overwriting an existing `CLAUDE.md` — extend with a delimited, attributed section.
