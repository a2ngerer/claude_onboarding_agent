---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-05-28
sources:
  - https://docs.claude.com/en/docs/claude-code/hooks
  - https://docs.claude.com/en/docs/claude-code/settings
  - https://docs.claude.com/en/docs/claude-code/plugins
  - https://docs.claude.com/en/docs/claude-code/slash-commands
  - https://docs.claude.com/en/docs/claude-code/memory
version: 2
---

## Memory files

- `CLAUDE.md` — project instructions at `./CLAUDE.md` or `./.claude/CLAUDE.md`; user-level at `~/.claude/CLAUDE.md`. Loaded every session.
- `CLAUDE.local.md` — personal project notes; gitignored, appended after `CLAUDE.md`.
- `AGENTS.md` — not read natively by Claude Code. Import from `CLAUDE.md` with `@AGENTS.md` if the repo uses both.
- Size target: keep each `CLAUDE.md` under ~200 lines. HTML block comments (`<!-- ... -->`) are stripped before context injection.
- Modular rules: `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` pulls another file into context at launch (max depth 4 hops).

## Auto memory

Claude maintains its own persistent notes across sessions in `~/.claude/projects/<repo>/memory/`. The `MEMORY.md` index (first 200 lines or 25 KB) loads at session start; topic files load on demand. Toggle via `autoMemoryEnabled` in settings or the `/memory` command.

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `autoMemoryEnabled`, `autoMemoryDirectory`, `effortLevel`, `language`, `skillOverrides`. Permission rules evaluate `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

## Hooks

Hooks run at lifecycle events under `hooks.<EventName>[]` in settings. Handler types: `command`, `http`, `mcp_tool`, `prompt`, `agent`. Plugin hooks live in `hooks/hooks.json`. Skills can define scoped hooks in frontmatter.

**Session & prompt events:**

| Event | Typical use |
|---|---|
| `SessionStart` / `SessionEnd` / `Setup` | Load context, initialize env, flush metrics |
| `UserPromptSubmit` | Validate or enrich user prompt before Claude sees it |
| `UserPromptExpansion` | When a slash command expands into a prompt |
| `Stop` / `StopFailure` | Cleanup or alert when a turn ends (or errors) |

**Tool lifecycle events:**

| Event | Typical use |
|---|---|
| `PreToolUse` | Block or gate a tool call |
| `PostToolUse` / `PostToolUseFailure` | Lint, log, or retry after a tool |
| `PostToolBatch` | After a batch of parallel tool calls resolves |
| `PermissionRequest` | Override the auto-mode permission classifier |

**Context & other events:**

| Event | Typical use |
|---|---|
| `InstructionsLoaded` | Log which CLAUDE.md / rules files loaded and why |
| `FileChanged` | Trigger on watched file changes on disk |
| `PreCompact` / `PostCompact` | Preserve or restore state around context compaction |
| `SubagentStart` / `SubagentStop` | Monitor subagent lifecycle |
| `MessageDisplay` | Transform or suppress assistant message text (v2.1.152+) |

## Slash commands / Skills

Commands and skills are merged: `.claude/skills/<name>/SKILL.md` and `.claude/commands/<name>.md` both create `/<name>` and work identically. User skills live at `~/.claude/skills/`. Plugin-provided skills are namespaced: `/<plugin>:<skill>`. Arguments: `$ARGUMENTS` (full string) or positional `$0`/`$1`. Slugs: lowercase, digits, hyphens; max 64 chars.

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`.
- Components sit at the plugin root (not inside `.claude-plugin/`): `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `settings.json`.
- `/reload-plugins` picks up local edits without restart.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short, reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills over fat `CLAUDE.md` sections for anything longer than a few bullets or only invoked occasionally.
- Use a `PostToolUse` hook to run linters/formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
- Pin plugin versions in team repos; run `/reload-plugins` after edits instead of restarting.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them to `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
