---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-06-04
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
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 4).
- HTML block comments (`<!-- ... -->`) are stripped before injecting into Claude's context — use for maintainer notes without spending tokens.
- **Auto memory** — Claude writes learnings to `~/.claude/projects/<project>/memory/MEMORY.md` across sessions. First 200 lines or 25 KB loaded at startup. Toggle with `autoMemoryEnabled` in `settings.json`.

## Settings

Key top-level fields in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `effortLevel`, `autoMemoryEnabled`, `autoMemoryDirectory`, `ultracode`. Permission rules evaluate in order `deny → ask → allow`; first match wins. Settings apply at user / project / local / managed scopes; managed has highest priority.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

## Hooks

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and `{ type, command }` entries. Supported hook types: `command`, `http`, `mcp_tool`, `prompt`, `agent`. Plugins ship hooks in `hooks/hooks.json`.

| Event | When it fires | Key use |
|---|---|---|
| `SessionStart` | Session opens or resumes | Inject context; can return `reloadSkills`, `sessionTitle`, `watchPaths` |
| `UserPromptSubmit` | User submits a prompt | Validate/block input |
| `PreToolUse` | Before a tool call | Gate or modify tool input |
| `PostToolUse` | After a tool succeeds | Lint, format, replace tool output via `hookSpecificOutput.updatedToolOutput` |
| `Stop` | Claude finishes a turn | Persist notes; receives `background_tasks`, `session_crons` |
| `SessionEnd` | Session terminates | Cleanup / flush metrics |
| `MessageDisplay` | While assistant message is displayed | Transform displayed text (transcript unchanged) |
| `PreCompact` / `PostCompact` | Before / after context compaction | Block or react to compaction |
| `SubagentStart` / `SubagentStop` | Subagent spawned / finished | Add context or block |
| `FileChanged` | Watched file changes on disk | Reactive env management |
| `PermissionRequest` | Permission dialog appears | Auto-approve or deny |
| `PermissionDenied` | Tool denied by auto mode | Return `retry: true` to allow retry |

## Slash commands

- Project skills: `.claude/skills/<name>/SKILL.md`; user skills: `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` still works.
- Plugin skills are namespaced: `/<plugin-name>:<skill-name>`.
- New built-in commands: `/goal` (set completion condition), `/effort` (persists level as default), `/workflows` (view dynamic workflow runs), `/reload-skills` (re-scan skill directories without restart), `/code-review` (bug review at chosen effort; `--comment` posts inline PR comments, `--fix` applies findings).
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… (positional). Name slugs: lowercase letters, digits, hyphens; max 64 chars.

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`.
- Components at plugin root (not inside `.claude-plugin/`): `skills/`, `agents/`, `hooks/`, `.mcp.json`, `settings.json`.
- Version every release; run `/reload-plugins` after local edits.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit`.
- Scope permissions explicitly: allowlist safe commands, deny reads of secrets.
- Use `effortLevel` in `settings.json` to persist a default effort level across sessions.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md`.
- Do not place components (`agents/`, `skills/`, `hooks/`) inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly — import it with `@AGENTS.md`.
- `/simplify` is removed — its behavior moved to `/code-review --fix`.
