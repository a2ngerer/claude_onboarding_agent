---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-05-07
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
- `AGENTS.md` — not read natively by Claude Code. Import it from `CLAUDE.md` with `@AGENTS.md`.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 5).
- **Auto memory**: Claude writes its own notes to `~/.claude/projects/<project>/memory/`. Toggle with `autoMemoryEnabled` in settings or `/memory`. First 200 lines of `MEMORY.md` load each session.

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `effortLevel`, `viewMode`, `showThinkingSummaries`, `skillOverrides`, `autoMemoryEnabled`, `autoMemoryDirectory`, `worktree.*`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"], "ask": ["Bash(git push *)"] } }
```

Rule specifiers: `Bash(cmd *)`, `Read(./path)`, `Edit(./src/**)`, `WebFetch(domain:x.com)`, `Agent(subagent-name)`, `MCP(server-name)`.

## Hooks

Hook handler types: `command` (shell script; JSON on stdin), `http` (POST endpoint), `mcp_tool` (MCP server tool), `prompt` (LLM eval), `agent` (subagent verification).

| Phase | Events |
|---|---|
| Session | `Setup`, `SessionStart`, `SessionEnd` |
| Per-turn | `UserPromptSubmit`, `UserPromptExpansion`, `Stop`, `StopFailure` |
| Tool execution | `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PostToolBatch` |
| Permissions | `PermissionRequest`, `PermissionDenied` |
| Subagents / tasks | `SubagentStart`, `SubagentStop`, `TaskCreated`, `TaskCompleted`, `TeammateIdle` |
| Config / files | `FileChanged`, `CwdChanged`, `ConfigChange`, `InstructionsLoaded` |
| Compaction | `PreCompact`, `PostCompact` |
| Worktrees | `WorktreeCreate`, `WorktreeRemove` |
| UI / MCP | `Notification`, `Elicitation`, `ElicitationResult` |

`PreToolUse` decisions: use `hookSpecificOutput.permissionDecision` with values `allow | deny | ask | defer`. The legacy top-level `{"decision": "approve|block"}` still works for backward compat but is deprecated; `defer` is only available in the new format.

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]`. Plugin hooks go in `hooks/hooks.json`.

## Slash commands / Skills

- Custom commands and skills are merged. Project skills: `.claude/skills/<name>/SKILL.md`; user skills: `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Key `SKILL.md` frontmatter: `description` (when to invoke), `disable-model-invocation: true` (user-only), `user-invocable: false` (Claude-only), `allowed-tools`, `context: fork` (run in subagent), `paths:` (glob-scoped loading), `effort:`, `model:`, `hooks:`, `when_to_use`.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter. Special vars: `${CLAUDE_SKILL_DIR}`, `${CLAUDE_SESSION_ID}`, `${CLAUDE_EFFORT}`.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`.
- Components at the plugin root (not inside `.claude-plugin/`): `skills/`, `agents/`, `commands/` (legacy; prefer `skills/`), `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/`, `settings.json`.
- `bin/` executables are added to the Bash tool's PATH when the plugin is active.
- `monitors/monitors.json` defines background watchers; each stdout line from the watched command is delivered to Claude as a notification.
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Use `PreCompact` to block or gate context compaction (exit code 2 or `{"decision":"block"}`).
- Scope permissions explicitly: allowlist safe commands, deny reads of secrets.
- Pin plugin versions in team repos; run `/reload-plugins` after edits instead of restarting.
- Namespace plugin skills; never rely on a collision-prone flat name.

## Deprecated patterns

- Do not use `{"decision": "approve|block"}` in `PreToolUse` hooks — use `hookSpecificOutput.permissionDecision`.
- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move to `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md`.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
