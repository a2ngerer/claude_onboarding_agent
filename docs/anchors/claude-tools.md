---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-05-30
sources:
  - https://docs.claude.com/en/docs/claude-code/hooks
  - https://docs.claude.com/en/docs/claude-code/settings
  - https://docs.claude.com/en/docs/claude-code/plugins
  - https://docs.claude.com/en/docs/claude-code/slash-commands
  - https://docs.claude.com/en/docs/claude-code/memory
version: 2
---

## Memory files

- `CLAUDE.md` — project instructions at `./CLAUDE.md` or `./.claude/CLAUDE.md`; user-level at `~/.claude/CLAUDE.md`; org-managed policy at a platform-specific system path. All load into every session.
- `CLAUDE.local.md` — personal project notes; gitignored, appended after `CLAUDE.md`.
- `AGENTS.md` — not read natively by Claude Code. Import with `@AGENTS.md` in `CLAUDE.md`.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- **Auto memory** — Claude writes its own notes to `~/.claude/projects/<repo>/memory/`. First 200 lines of `MEMORY.md` load each session; topic files load on demand. Toggle via `autoMemoryEnabled` setting or `/memory` command.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 4 hops).

## Settings

Key top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `autoMemoryEnabled`, `autoMemoryDirectory`, `effortLevel`, `teammateMode`, `disableWorkflows`, `disableAgentView`. Permission rules evaluate `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

## Hooks

| Event | Fires when | Can block |
|---|---|---|
| `SessionStart` / `SessionEnd` | Session begins or ends | No |
| `UserPromptSubmit` | User submits a prompt | Yes |
| `UserPromptExpansion` | Slash command expands | Yes |
| `PreToolUse` | Before any tool call | Yes |
| `PostToolUse` / `PostToolUseFailure` | Tool call completes | Yes |
| `PostToolBatch` | Parallel batch of tool calls resolves | Yes |
| `Stop` | Claude finishes responding | Yes |
| `SubagentStart` / `SubagentStop` | Subagent lifecycle | Stop: Yes |
| `TeammateIdle` | Agent-team teammate about to go idle | Yes |
| `TaskCreated` / `TaskCompleted` | Task lifecycle | Yes |
| `FileChanged` | Watched file changes on disk | No |
| `InstructionsLoaded` | CLAUDE.md / rules file loads | No |
| `PreCompact` / `PostCompact` | Context compaction | Pre: Yes |
| `MessageDisplay` | Assistant message text streams | No |
| `WorktreeCreate` / `WorktreeRemove` | Worktree lifecycle | Create: Yes |
| `Elicitation` / `ElicitationResult` | MCP server requests user input | Yes |

Hook handler `type` options: `command`, `http`, `mcp_tool`, `prompt`, `agent`. Hooks live in `.claude/settings.json` under `hooks.<EventName>[]`. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands / Skills

- Skills (`SKILL.md`) and legacy commands (`commands/*.md`) are merged; both create slash commands. Skills add supporting files and frontmatter options.
- Project skills at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/`; legacy `.claude/commands/*.md` still works.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Frontmatter: `disallowed-tools` removes tools while skill is active; `disable-model-invocation: true` prevents auto-triggering.
- `/reload-skills` reloads skill directories without restarting.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`.
- Components sit at the plugin root (not inside `.claude-plugin/`): `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/monitors.json`, `themes/`, `bin/`, `settings.json`.
- `bin/` — executables added to Bash tool's PATH while the plugin is active.
- `settings.json` at plugin root ships default settings (supports `agent` and `subagentStatusLine` keys).
- Scaffold: `claude plugin init <name>`. `/reload-plugins` picks up local edits.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
- Use auto memory for persisting Claude's learned preferences; reserve `CLAUDE.md` for stable, human-authored project rules.

## Deprecated patterns

- Do not stuff templates or multi-step procedures into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place components inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not use `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md`.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
