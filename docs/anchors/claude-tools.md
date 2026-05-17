---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-05-17
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
- Auto memory: Claude writes its own learnings to `~/.claude/projects/<repo>/memory/MEMORY.md` across sessions (first 200 lines loaded at start). Toggle with `autoMemoryEnabled` in `settings.json`.

## Settings

Key top-level settings in `.claude/settings.json`: `permissions`, `env`, `hooks`, `model`, `effortLevel`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `worktree`, `parentSettingsBehavior`, `autoMemoryEnabled`, `autoMemoryDirectory`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

## Hooks

Five handler types: `command`, `http`, `mcp_tool`, `prompt`, `agent`. Hooks live under `hooks.<EventName>[]` with a `matcher` and handler entries.

| Phase | Events |
|---|---|
| Session | `Setup`, `SessionStart`, `SessionEnd` |
| Input | `UserPromptSubmit`, `UserPromptExpansion` |
| Tool loop | `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PostToolBatch`, `PermissionRequest`, `PermissionDenied` |
| Completion | `Stop`, `StopFailure` |
| Agents | `SubagentStart`, `SubagentStop`, `TeammateIdle`, `TaskCreated`, `TaskCompleted` |
| Config/File | `InstructionsLoaded`, `ConfigChange`, `FileChanged`, `CwdChanged`, `WorktreeCreate`, `WorktreeRemove` |
| Context | `PreCompact` (can block), `PostCompact` |
| Notifications | `Notification`, `Elicitation`, `ElicitationResult` |

Key behaviors:
- `PreCompact` blocks compaction via exit code 2 or `{"decision":"block"}`.
- `PostToolUse`: `hookSpecificOutput.updatedToolOutput` replaces tool output for all tools.
- Hook inputs include `duration_ms` (tool execution time) and `effort.level` / `$CLAUDE_EFFORT`.
- `terminalSequence` in hook JSON output sends desktop notifications without a controlling terminal.
- Do NOT use `prompt`/`agent`-type hooks for `SessionStart`, `Setup`, or `SubagentStart` — use `command` instead.

## Skills and slash commands

Skills (`SKILL.md`) supersede legacy `.claude/commands/*.md`; both still work, but skills support supporting files, frontmatter control, and subagent execution. Commands and skills are merged in Claude's tool listing.

- Skills at `.claude/skills/<name>/SKILL.md` (project) or `~/.claude/skills/<name>/SKILL.md` (personal).
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>`.
- Arguments: `$ARGUMENTS`, `$0`/`$1`/…, or named via `arguments:` frontmatter.
- `context: fork` in frontmatter runs the skill as an isolated subagent.
- `disable-model-invocation: true` makes the skill user-only (Claude won't invoke it automatically).

Notable built-in skills added: `/goal` (work until a condition is met with live progress overlay), `/effort` (interactive effort-level selector), `/ultrareview` (cloud multi-agent code review), `/team-onboarding`, `/recap`, `/focus`, `/less-permission-prompts`.

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`.
- Components at plugin root: `skills/`, `agents/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `settings.json`.
- `claude plugin disable` refuses when another enabled plugin depends on the target and shows a disable-chain hint.
- Version every release; `/reload-plugins` picks up local edits.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands, deny reads of secrets.
- Pin plugin versions in team repos; run `/reload-plugins` after edits instead of restarting.

## Deprecated patterns

- Do not stuff templates or multi-step procedures into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md`.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
