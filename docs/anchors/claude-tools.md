---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-05-31
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
- `AGENTS.md` — not read natively by Claude Code. Import with `@AGENTS.md` in `CLAUDE.md`, or symlink.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 4). HTML comments (`<!-- -->`) are stripped before injection.
- **Auto memory:** Claude writes notes across sessions to `~/.claude/projects/<repo>/memory/`. First 200 lines of `MEMORY.md` load each session. Controlled by `autoMemoryEnabled` (default: `true`) and `autoMemoryDirectory` settings.

## Settings

Top-level keys in `.claude/settings.json` (partial): `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `language`, `effortLevel`, `alwaysThinkingEnabled`, `skillOverrides`, `autoMemoryEnabled`, `autoMemoryDirectory`, `worktree.baseRef`, `worktree.bgIsolation`, `disableWorkflows`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

## Hooks

There are 25+ hook event types. The most commonly used:

| Event | Typical use |
|---|---|
| `SessionStart` | Load context or env vars on session open |
| `UserPromptSubmit` | Validate or enrich the user prompt |
| `PreToolUse` | Block or gate a tool call |
| `PostToolUse` | Lint or log after a tool runs |
| `PostToolUseFailure` | React to failed tool calls |
| `MessageDisplay` | Transform or hide assistant message text during display |
| `SubagentStart` / `SubagentStop` | React when subagents spawn or finish |
| `InstructionsLoaded` | React when CLAUDE.md / rules files load |
| `PreCompact` / `PostCompact` | Hook around context compaction |
| `Stop` | Cleanup when Claude finishes a turn |
| `SessionEnd` | Release resources or save artifacts |

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and `{ type, command }` entries. Hook types: `command`, `http`, `mcp_tool`, `prompt`, `agent`. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Custom commands and skills are merged: `.claude/commands/deploy.md` and `.claude/skills/deploy/SKILL.md` both create `/deploy`. Skills follow the [Agent Skills](https://agentskills.io) open standard.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… (positional), named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- New built-in skills: `/goal` (set completion conditions), `/reload-skills` (rescan skill dirs without restart), `/workflows` (view dynamic workflow runs), `/btw` (side questions outside conversation history).

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`.
- Components at plugin root (not inside `.claude-plugin/`): `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json` (LSP servers), `monitors/monitors.json` (background monitors), `bin/` (executables added to PATH), `settings.json`.
- `claude plugin init <name>` scaffolds a plugin in `~/.claude/skills/`; these load without marketplace requirement.
- Version every release; `/reload-plugins` picks up local edits without restart.

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
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md`.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
