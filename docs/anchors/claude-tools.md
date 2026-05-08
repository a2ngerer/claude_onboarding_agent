---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-05-08
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
- `MEMORY.md` — auto memory written by Claude, stored at `~/.claude/projects/<project>/memory/MEMORY.md`. First 200 lines loaded each session. Claude accumulates build commands, debugging insights, and preferences here without manual editing.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 5).

## Settings

Top-level keys in `.claude/settings.json` include: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `worktree`, `effortLevel`, `disableSkillShellExecution`, `parentSettingsBehavior` (managed-only), and many more. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

## Hooks

| Event | Typical use | Notes |
|---|---|---|
| `SessionStart` | Load context or env vars on session open | matcher: `startup`, `resume`, `clear`, `compact` |
| `UserPromptSubmit` | Validate or enrich prompt; set session title via `hookSpecificOutput.sessionTitle` | Always fires |
| `UserPromptExpansion` | Intercept slash-command expansion before Claude sees it | matcher: command name |
| `PreToolUse` | Block or gate a tool call | matcher: tool name |
| `PostToolUse` | Lint or log after a tool runs; `updatedToolOutput` supported for all tools | matcher: tool name |
| `PostToolUseFailure` | Handle tool errors | matcher: tool name |
| `PermissionDenied` | Fires when auto-mode classifier denies a tool; return `{"retry":true}` to unblock | matcher: tool name |
| `Stop` | Cleanup when Claude finishes a turn | Always fires |
| `SessionEnd` | Release resources or save artifacts | matcher: `logout`, `clear`, etc. |
| `PreCompact` | Block or prepare before context compaction (exit 2 or `{"decision":"block"}`) | matcher: `manual`, `auto` |
| `InstructionsLoaded` | React when CLAUDE.md / rules load | matcher: load reason |
| `SubagentStart` / `SubagentStop` | Monitor subagent lifecycle | matcher: agent type |
| `ConfigChange` | React when settings change mid-session | matcher: settings file type |

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with an optional `matcher` and a list of entries with `type` (`command`, `http`, `mcp_tool`, `prompt`, or `agent`) plus a payload. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills are the canonical way: `.claude/skills/<name>/SKILL.md` (project) or `~/.claude/skills/<name>/SKILL.md` (user).
- Legacy `.claude/commands/*.md` still works. When both exist at the same scope, the skill takes precedence.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Key skill frontmatter flags: `disable-model-invocation: true` (user-only trigger), `context: fork` (run in isolated subagent context), `paths:` (scope by file globs), `effort:` (override effort level).
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`.
- Components at the plugin root: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `settings.json`, `bin/` (executables added to Bash's `PATH` while plugin is active).
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Use a `PreCompact` hook to snapshot state or warn before Claude compresses context.
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
- Pin plugin versions in team repos; run `/reload-plugins` after edits instead of restarting.
- Namespace plugin skills; never rely on a collision-prone flat name.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md`.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
