---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-05-18
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
- `AGENTS.md` — not read natively by Claude Code. Import with `@AGENTS.md` in `CLAUDE.md` to share instructions.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 5).

## Auto memory

Claude accumulates learnings across sessions in `~/.claude/projects/<project>/memory/`. `MEMORY.md` is the index (first 200 lines or 25 KB loaded per session); topic files are read on demand. Manage via `/memory`. Toggle with `autoMemoryEnabled` in settings or `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`.

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `worktree.baseRef` (`"fresh"` or `"head"`), `worktree.symlinkDirectories`, `skillOverrides`, `autoMemoryEnabled`, `autoMemoryDirectory`, `parentSettingsBehavior`. Permission rules evaluate `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

## Hooks

Five hook types: `command`, `http`, `mcp_tool`, `prompt`, `agent`. Configured under `hooks.<EventName>[]` in settings or plugin `hooks/hooks.json`.

| Event | Typical use |
|---|---|
| `SessionStart` | Load context or env vars on session open |
| `UserPromptSubmit` | Validate or enrich the user prompt |
| `PreToolUse` | Block or gate a tool call |
| `PostToolUse` | Lint/log after a tool runs; `continueOnBlock` feeds rejection reason back to Claude |
| `PreCompact` / `PostCompact` | Gate or react to context compaction (new) |
| `SubagentStart` / `SubagentStop` | React to subagent lifecycle (new) |
| `WorktreeCreate` / `WorktreeRemove` | React to worktree lifecycle (new) |
| `FileChanged` | Watch specific files for on-disk changes (new) |
| `InstructionsLoaded` | React when CLAUDE.md or rules files load (new) |
| `Stop` / `StopFailure` | Cleanup or react to error when Claude finishes a turn |
| `SessionEnd` | Release resources or save artifacts |

Hook output fields: `continue`, `stopReason`, `systemMessage`, `terminalSequence` (OSC sequences for desktop notifications without controlling the terminal), `hookSpecificOutput`. Exit code 2 blocks the event; exit 0 with valid JSON is processed.

## Skills and slash commands

Skills (`skills/<name>/SKILL.md`) extend Claude's capabilities. Project skills: `.claude/skills/<name>/SKILL.md`; user skills: `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` still work; skills take precedence on name conflicts.

SKILL.md frontmatter fields: `description`, `disable-model-invocation` (user-only invocation), `user-invocable` (hide from `/` menu), `allowed-tools`, `model`, `effort`, `context` (`fork` for subagent isolation), `agent`, `paths` (glob filter), `shell`, `hooks`.

Dynamic context injection: `` !`command` `` inlines shell output before Claude sees the skill.

Argument substitution: `$ARGUMENTS` (full string), `$0`/`$1`/… (positional), named args via `arguments:` frontmatter, `${CLAUDE_SKILL_DIR}` for bundled script paths.

Notable built-in slash commands: `/goal` (completion condition across turns), `/ultrareview` (parallel multi-agent code review), `/agents` (manage subagents), `/focus`, `/recap`, `/effort`, `/less-permission-prompts` (scan transcripts and propose allowlist), `/tui fullscreen`, `/scroll-speed`, `/memory`.

`skillOverrides` in settings: `"on"`, `"name-only"`, `"user-invocable-only"`, `"off"`. The `/skills` menu writes this automatically.

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version`, `description`, optional `author`, `homepage`, `repository`.
- Components at plugin root (not inside `.claude-plugin/`): `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/monitors.json`, `bin/`, `settings.json`.
- `monitors/monitors.json` — background monitors auto-armed at session start; each `command`'s stdout lines are delivered to Claude as notifications.
- `bin/` — executables added to Bash tool's `PATH` while the plugin is active.
- `.lsp.json` — LSP server configuration for code intelligence.
- Version every release; `/reload-plugins` picks up local edits. Use `--plugin-dir` or `--plugin-url` for local/CI testing.

## Recommendations

- Point-don't-dump in `CLAUDE.md`; reference detail via `@imports` or `.claude/rules/`.
- Prefer skills over fat `CLAUDE.md` sections for procedures invoked only sometimes.
- Use a `PostToolUse` hook to run linters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly; deny reads of secrets (`Read(./.env)`).
- Use `terminalSequence` in hook output for desktop notifications without a controlling terminal.

## Deprecated patterns

- Do not stuff templates or multi-step procedures into `CLAUDE.md` — move them to `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly by Claude Code — import with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md`.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
