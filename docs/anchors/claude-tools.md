---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-05-16
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
- `AGENTS.md` — not read natively by Claude Code. If the repo needs both, `CLAUDE.md` imports it with `@AGENTS.md`.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 5).
- **Auto memory** (`~/.claude/projects/<repo>/memory/`): Claude accumulates notes across sessions into `MEMORY.md`; first 200 lines / 25 KB load at startup. Toggle with the `autoMemoryEnabled` setting.

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `effortLevel`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `autoMemoryEnabled`, `autoMemoryDirectory`, `alwaysThinkingEnabled`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

## Hooks

Handler types: `command` (shell), `http` (POST to external endpoint), `mcp_tool`, `prompt` (LLM evaluation), `agent` (subagent). Async execution supported via `async: true`.

| Event | Typical use |
|---|---|
| `SessionStart` / `SessionEnd` | Load context on open; flush artifacts on close |
| `Setup` | One-time init under `--init` / `--init-only` flag |
| `InstructionsLoaded` | Log which CLAUDE.md and rules files were loaded |
| `UserPromptSubmit` | Validate or enrich the user prompt before processing |
| `UserPromptExpansion` | Fires when a slash command expands into a prompt |
| `PreToolUse` / `PostToolUse` | Block or lint around tool calls |
| `PostToolUse` (`continueOnBlock`) | Feed rejection reason back to Claude instead of hard-blocking |
| `PostToolBatch` | Run once after all parallel tool calls complete |
| `SubagentStart` / `SubagentStop` | Observe subagent spawn and finish |
| `Stop` / `StopFailure` | Cleanup when a turn ends normally or on API error |
| `PreCompact` / `PostCompact` | Gate or react to context compaction |
| `WorktreeCreate` / `WorktreeRemove` | React to worktree lifecycle events |
| `FileChanged` | Respond to watched file edits on disk |
| `PermissionRequest` / `PermissionDenied` | Observe permission dialog events |

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and handler entries. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills live at `.claude/skills/<name>/SKILL.md` (project) or `~/.claude/skills/<name>/SKILL.md` (user). Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… (positional), named args via `arguments:` frontmatter.
- Key frontmatter fields: `disable-model-invocation`, `user-invocable`, `allowed-tools`, `model`, `effort`, `context: fork`, `paths:` (glob-scoped activation).
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`.
- Components at plugin root (NOT inside `.claude-plugin/`): `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/`, `settings.json`.
- `monitors/monitors.json` — background watchers (tail logs, file watches) delivering each stdout line as a session notification.
- `bin/` — executables added to Bash tool's `PATH` while the plugin is enabled.
- Version every release; `/reload-plugins` picks up local edits without restarting.

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
