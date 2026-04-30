---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-04-30
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
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally. Rules directories support symlinks for cross-project sharing.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 5).
- **Auto memory**: Claude writes its own notes to `~/.claude/projects/<project>/memory/`; first 200 lines or 25 KB of `MEMORY.md` load each session. Toggle via `/memory` or `autoMemoryEnabled` in settings.
- Use `claudeMdExcludes` in settings to skip specific `CLAUDE.md` files in large monorepos.

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `effortLevel`, `alwaysThinkingEnabled`, `prUrlTemplate`, `autoMemoryDirectory`. Permission rules evaluate in order `deny → ask → allow`; first match wins. Four scopes (highest → lowest): managed → local → project → user.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] },
  "sandbox": { "network": { "deniedDomains": ["*.internal"] } } }
```

## Hooks

Claude Code supports **31 hook events** across six categories. Each entry in `hooks.<EventName>[]` has a `matcher` and a list of `{ type, command }` entries. `type` is `"command"` (shell) or `"mcp_tool"` (invokes an MCP tool). Exit code 2 blocks the action and feeds stderr back to Claude.

| Category | Key events | Can block? |
|---|---|---|
| Session | `SessionStart`, `Setup`, `SessionEnd` | No (SessionEnd) |
| Per-turn | `UserPromptSubmit`, `Stop`, `StopFailure` | Yes |
| Tool calls | `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PostToolBatch`, `PermissionRequest`, `PermissionDenied` | Yes (most) |
| Subagent / task | `SubagentStart`, `SubagentStop`, `TaskCreated`, `TaskCompleted`, `TeammateIdle` | Yes (most) |
| Context | `PreCompact`, `PostCompact`, `InstructionsLoaded`, `ConfigChange`, `CwdChanged`, `FileChanged` | Yes (most) |
| MCP / UI | `Elicitation`, `ElicitationResult`, `Notification`, `WorktreeCreate`, `WorktreeRemove` | Yes (most) |

`PostToolUse` hooks can replace tool output by returning `hookSpecificOutput.updatedToolOutput`. `PreToolUse` hooks can modify tool input via `hookSpecificOutput.updatedInput`. Both support `additionalContext` to inject text for Claude.

## Slash commands / Skills

Skills are the primary extension mechanism. A skill is a directory with `SKILL.md` under `.claude/skills/<name>/` (project), `~/.claude/skills/<name>/` (user), or a plugin's `skills/` directory. Legacy `.claude/commands/*.md` files still work but lack skill features.

Key frontmatter fields:

| Field | Purpose |
|---|---|
| `description` | When Claude auto-invokes the skill |
| `disable-model-invocation: true` | User-triggered only, not auto |
| `user-invocable: false` | Claude-only, hidden from `/` menu |
| `allowed-tools` | Tools pre-approved while this skill is active |
| `context: fork` | Run in an isolated subagent context |
| `agent` | Subagent type when `context: fork` is set |
| `paths` | Glob patterns that scope auto-invocation |
| `effort` | Override effort level for this skill |

String substitutions: `$ARGUMENTS`, `$0`, `$1`, …, `${CLAUDE_EFFORT}`, `${CLAUDE_SESSION_ID}`, `${CLAUDE_SKILL_DIR}`. Shell injection: `` !`cmd` `` or fenced ` ```! ` block runs before Claude sees the prompt.

Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>`.

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`.
- Components at the plugin root (not inside `.claude-plugin/`): `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/`, `settings.json`.
- `monitors/monitors.json` — background monitors: each stdout line from `command` is delivered to Claude as a notification during the session.
- `bin/` — executables added to the Bash tool's `PATH` while the plugin is active.
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Use a `PreCompact` hook to inject critical context (e.g. file state, open tasks) before compaction discards history.
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
- Pin plugin versions in team repos; run `/reload-plugins` after edits instead of restarting.
- Namespace plugin skills; never rely on a collision-prone flat name.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md`.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
