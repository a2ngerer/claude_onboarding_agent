---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-06-01
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

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `effortLevel`, `worktree`, `skillOverrides`, `allowAllClaudeAiMcps`, `allowedMcpServers`, `deniedMcpServers`, `pluginSuggestionMarketplaces`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

## Hooks

| Event | Fires when | Blocking? |
|---|---|---|
| `SessionStart` | Session begins or resumes | No |
| `UserPromptSubmit` | User submits prompt | Yes |
| `UserPromptExpansion` | Slash command expands before reaching Claude | Yes |
| `PreToolUse` | Before a tool call | Yes |
| `PermissionRequest` | Permission dialog appears | Yes |
| `PostToolUse` | After a tool call succeeds | No |
| `PostToolBatch` | After a full batch of parallel tool calls | Yes |
| `MessageDisplay` | While assistant message is displayed (display-only) | No |
| `Stop` | Claude finishes responding | Yes |
| `SubagentStart` / `SubagentStop` | Subagent spawns / finishes | No / Yes |
| `PreCompact` / `PostCompact` | Before / after context compaction | Yes / No |
| `WorktreeCreate` / `WorktreeRemove` | Worktree lifecycle | Yes / No |
| `InstructionsLoaded` | CLAUDE.md or rules/*.md loaded | No |
| `TaskCreated` / `TaskCompleted` | Task lifecycle | Yes |
| `SessionEnd` | Session terminates | No |

Handler types: `command` (shell), `http` (POST to URL), `mcp_tool` (call an MCP tool), `prompt` (ask Claude), `agent` (spawn subagent). All via `.claude/settings.json` under `hooks.<EventName>[]` with optional `matcher` and `if` filter.

Notable hook I/O: `effort.level` in input (`low`/`medium`/`high`/`xhigh`); `terminalSequence` output for desktop notifications; `sessionTitle` + `reloadSkills` + `watchPaths` in SessionStart output; `displayContent` in MessageDisplay output (changes what appears on screen without affecting what Claude sees or the transcript).

## Slash commands

- Skills live at `.claude/skills/<name>/SKILL.md` (project) or `~/.claude/skills/<name>/SKILL.md` (user). Legacy `.claude/commands/*.md` still works.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… positional, or named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- New built-in commands: `/goal` (set completion condition), `/reload-skills` (re-scan skill dirs), `/ultrareview` (CI-friendly code review), `/code-review` (correctness bugs at chosen effort; `--comment` posts inline GitHub PR comments), `/workflows` (view dynamic workflow runs).

## Plugins

- Manifest: `.claude-plugin/plugin.json` with required `name`, `version` (semver), `description`; also validates `$schema`.
- Components sit at plugin root: `skills/`, `agents/`, `hooks/`, `.mcp.json`, `settings.json`.
- Plugins auto-load from `.claude/skills/` directories without marketplace requirement; scaffold with `/plugin init <name>`.
- `defaultEnabled: false` disables a plugin by default; enable via `/plugin`.
- A root-level `SKILL.md` (no `skills/` subdirectory) is surfaced as a skill.
- `disallowed-tools` in skill frontmatter removes specific tools while that skill is active.
- Version every release; `/reload-plugins` picks up local edits.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use `PostToolUse` hooks to run linters/formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Use `MessageDisplay` hooks to reformat or redact assistant output for the terminal without affecting Claude's view.
- Scope permissions explicitly; pin plugin versions in team repos; run `/reload-plugins` after edits.
- Namespace plugin skills; never rely on a collision-prone flat name.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md`.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
