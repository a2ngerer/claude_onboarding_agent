---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-05-03
sources:
  - https://docs.claude.com/en/docs/claude-code/hooks
  - https://docs.claude.com/en/docs/claude-code/settings
  - https://docs.claude.com/en/docs/claude-code/plugins
  - https://docs.claude.com/en/docs/claude-code/slash-commands
  - https://docs.claude.com/en/docs/claude-code/memory
version: 2
---

## Memory files

- `CLAUDE.md` — project instructions at `./CLAUDE.md` or `./.claude/CLAUDE.md`; user-level at `~/.claude/CLAUDE.md`; org-level at the managed-policy path. Loaded every session.
- `CLAUDE.local.md` — personal project notes; gitignored, appended after `CLAUDE.md`.
- `AGENTS.md` — not read natively by Claude Code. If the repo needs both, `CLAUDE.md` imports it with `@AGENTS.md`.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter (accepts a single glob or a YAML list) to scope by file pattern. Rules without `paths:` load unconditionally.
- Auto memory: Claude writes `~/.claude/projects/<project>/memory/MEMORY.md` (first 200 lines loaded each session) and topic files it reads on demand. Toggle with `autoMemoryEnabled` setting or `/memory`.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 5). `claudeMdExcludes` skips specific files in large monorepos.

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `effortLevel`, `alwaysThinkingEnabled`, `autoMode`. Policy fragments can be dropped into `managed-settings.d/` and are merged alphabetically. Permission rules evaluate `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

## Hooks

| Event | Typical use | Notes |
|---|---|---|
| `SessionStart` | Load context or env vars on session open | Keep fast |
| `UserPromptSubmit` | Validate or enrich the user prompt | Can block |
| `PreToolUse` | Block or gate a tool call | Can allow/deny/ask |
| `PostToolUse` | Lint or log after a tool runs | Can replace tool output |
| `PreCompact` | Block or modify compaction | Exit 2 to block |
| `PostCompact` | Notify after compaction | Observability only |
| `CwdChanged` | React to directory changes | Reload direnv |
| `FileChanged` | React to watched file edits | Matcher: literal filenames |
| `PermissionDenied` | Handle auto-mode refusals | Return `{retry:true}` to allow |
| `SubagentStop` | Audit subagent completion | Can block completion |
| `TaskCreated` | Gate or log task creation | Can block |
| `Stop` | Cleanup when Claude finishes a turn | Can prevent stopping |
| `SessionEnd` | Release resources or save artifacts | No blocking |

Hook types: `command` (shell script on stdin), `http` (POST to endpoint), `mcp_tool`, `prompt` (LLM yes/no evaluation), `agent` (subagent verification — experimental). All hooks support an `if` field for conditional filtering using permission rule syntax (e.g., `"Bash(git *)"`).

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, command }` entries. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `description`, optional `version` (semver), `author`, `homepage`, `repository`.
- Components sit at the plugin root: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/`, `settings.json`.
- `monitors/monitors.json` — background scripts whose stdout lines are delivered to Claude as session notifications.
- `bin/` — executables added to the Bash tool's `PATH` while the plugin is active.
- `settings.json` at plugin root supports `agent` key to activate a named subagent as the main thread.
- `/reload-plugins` picks up local edits; `--plugin-dir` loads a plugin for development without installing.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
- Pin plugin versions in team repos; run `/reload-plugins` after edits instead of restarting.
- Namespace plugin skills; never rely on a collision-prone flat name.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, `hooks/`, `monitors/`, or `bin/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md` so supporting files and frontmatter are available.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
