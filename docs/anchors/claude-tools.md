---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-05-29
sources:
  - https://docs.claude.com/en/docs/claude-code/hooks
  - https://docs.claude.com/en/docs/claude-code/settings
  - https://docs.claude.com/en/docs/claude-code/plugins
  - https://docs.claude.com/en/docs/claude-code/slash-commands
  - https://docs.claude.com/en/docs/claude-code/memory
version: 2
---

## Memory files

- `CLAUDE.md` — project instructions at `./CLAUDE.md` or `./.claude/CLAUDE.md`; user-level at `~/.claude/CLAUDE.md`; managed org-level at `/etc/claude-code/CLAUDE.md` (Linux/WSL) or `/Library/Application Support/ClaudeCode/CLAUDE.md` (macOS). Loaded into every session.
- `CLAUDE.local.md` — personal project notes; gitignored, appended after `CLAUDE.md`.
- `AGENTS.md` — not read natively by Claude Code. Import it with `@AGENTS.md` in `CLAUDE.md`, or use a symlink (`ln -s AGENTS.md CLAUDE.md`) on macOS/Linux.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 5).
- **Auto memory**: Claude accumulates its own notes across sessions at `~/.claude/projects/<repo>/memory/MEMORY.md`. Toggle with `autoMemoryEnabled` in settings; run `/memory` in-session to inspect or edit.

## Settings

Top-level keys in `.claude/settings.json` include: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `worktree`, `effortLevel`, `autoMemoryEnabled`, `alwaysThinkingEnabled`, `autoMode`, `attribution`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

## Hooks

| Event | Typical use | Blocks? |
|---|---|---|
| `SessionStart` | Load context, set session title, return `reloadSkills: true` | No |
| `UserPromptSubmit` | Validate or enrich the user prompt | Yes |
| `PreToolUse` | Block or gate a tool call | Yes |
| `PostToolUse` | Lint or log after a tool runs; can replace tool output | No |
| `PostToolBatch` | Act after a full batch of parallel tool calls resolves | Yes |
| `Stop` | Cleanup when Claude finishes a turn | Yes |
| `SessionEnd` | Release resources or save artifacts | No |
| `MessageDisplay` | Transform or hide assistant message text as displayed | No |
| `PreCompact` / `PostCompact` | Before/after context compaction | Yes/No |
| `WorktreeCreate` / `WorktreeRemove` | When a worktree is created or removed | Yes/No |
| `InstructionsLoaded` | When any CLAUDE.md or `.claude/rules/` file is loaded | No |
| `ConfigChange` | When a settings file changes during the session | Yes |
| `SubagentStart` / `SubagentStop` | When a subagent is spawned or finishes | No/Yes |
| `PermissionRequest` | When a permission dialog is triggered | Yes |

Hook types: `command`, `http`, `mcp_tool`, `prompt`, `agent`. Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of type+command entries. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills live at `.claude/skills/<name>/SKILL.md` (project) or `~/.claude/skills/<name>/SKILL.md` (user). Legacy `.claude/commands/*.md` still works.
- Plugin skills are namespaced: `/<plugin-name>:<skill-name>`.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… (positional), named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- `/reload-skills` re-scans skill directories without a session restart.

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `settings.json`.
- Version every release; `/reload-plugins` picks up local edits.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
- Pin plugin versions in team repos; run `/reload-plugins` after edits instead of restarting.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly by Claude Code — import or symlink it.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md`.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
