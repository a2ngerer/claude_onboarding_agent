---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-04-28
sources:
  - https://docs.claude.com/en/docs/claude-code/hooks
  - https://docs.claude.com/en/docs/claude-code/settings
  - https://docs.claude.com/en/docs/claude-code/plugins
  - https://docs.claude.com/en/docs/claude-code/slash-commands
  - https://docs.claude.com/en/docs/claude-code/memory
version: 2
---

## Memory files

- `CLAUDE.md` — project instructions at `./CLAUDE.md` or `./.claude/CLAUDE.md`; user-level at `~/.claude/CLAUDE.md`; managed-policy at `/Library/Application Support/ClaudeCode/CLAUDE.md` (macOS) or `/etc/claude-code/CLAUDE.md` (Linux). Loaded into every session.
- `CLAUDE.local.md` — personal project notes; gitignored, appended after `CLAUDE.md`.
- `AGENTS.md` — not read natively by Claude Code. If the repo needs both, `CLAUDE.md` imports it with `@AGENTS.md`.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 5).
- **Auto memory** — Claude writes its own notes to `~/.claude/projects/<repo>/memory/MEMORY.md` (first 200 lines loaded each session). Toggle via `/memory` or the `autoMemoryEnabled` setting.

## Settings

Key top-level fields in `.claude/settings.json` (partial — see docs for full list): `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `effortLevel`, `autoMemoryEnabled`, `disableSkillShellExecution`, `autoScrollEnabled`, `viewMode`, `tui`, `awaySummaryEnabled`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

Policy fragments drop into `managed-settings.d/` (alphabetical merge) for org-level configuration.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

## Hooks

Hook types: `command`, `http`, `mcp_tool`, `prompt`, `agent`. All support an `if` field (permission-rule syntax) for conditional filtering within a matcher group.

| Event | Typical use |
|---|---|
| `SessionStart` | Load context or env vars on session open |
| `UserPromptSubmit` | Validate or enrich the user prompt |
| `UserPromptExpansion` | When a slash command expands into a prompt |
| `PreToolUse` | Block or gate a tool call |
| `PostToolUse` | Lint or log after a tool runs; can replace tool output via `hookSpecificOutput.updatedToolOutput` |
| `PostToolBatch` | After a full batch of parallel tool calls |
| `PostToolUseFailure` | After a tool call fails |
| `PermissionRequest` | Intercept permission dialogs |
| `PermissionDenied` | Fires after auto-mode classifier denials |
| `Stop` | Cleanup when Claude finishes a turn |
| `StopFailure` | Handle turn endings caused by API errors |
| `SessionEnd` | Release resources or save artifacts |
| `InstructionsLoaded` | React when CLAUDE.md or rules files load |
| `PreCompact` | Block or react before context compaction |
| `PostCompact` | React after compaction completes |
| `CwdChanged` | Reactive env management on directory change |
| `FileChanged` | Watch specific files for disk changes |
| `SubagentStart` / `SubagentStop` | Track subagent lifecycle |
| `TaskCreated` / `TaskCompleted` | React to task creation or completion |
| `WorktreeCreate` / `WorktreeRemove` | React to worktree events |
| `TeammateIdle` | Agent team teammate about to go idle |
| `Notification` | Claude Code notification events |
| `Elicitation` / `ElicitationResult` | MCP server elicitation events |
| `ConfigChange` | Configuration file changes during a session |

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, command, if }` entries. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- `disable-model-invocation: true` prevents Claude from auto-invoking a skill; `paths:` scopes activation to matching globs.

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/`, `settings.json`.
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
- Pin plugin versions in team repos; run `/reload-plugins` after edits instead of restarting.
- Namespace plugin skills; never rely on a collision-prone flat name.
- Use auto memory for cross-session learnings Claude discovers; keep `CLAUDE.md` for rules you write yourself.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md` so supporting files and frontmatter are available.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
