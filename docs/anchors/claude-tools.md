---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-05-12
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
- **Auto memory**: Claude writes session learnings automatically to `~/.claude/projects/<project>/memory/MEMORY.md`. Toggle with `autoMemoryEnabled` in settings or the `/memory` command.

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `modelOverrides`, `agent`, `outputStyle`, `sandbox`, `effortLevel`, `alwaysThinkingEnabled`, `autoMemoryEnabled`, `skillOverrides`, `worktree`, `claudeMdExcludes`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

## Hooks

31 hook events total. Five handler types: `command`, `http`, `mcp_tool`, `prompt`, `agent`. Key events:

| Event | Typical use |
|---|---|
| `SessionStart` | Load context or env vars on session open |
| `UserPromptSubmit` | Validate or enrich the user prompt |
| `UserPromptExpansion` | Intercept skill expansions before Claude sees them |
| `PreToolUse` | Block or gate a tool call (`permissionDecision: allow/deny/ask/defer`) |
| `PostToolUse` | Lint/log after a tool; replace output via `hookSpecificOutput.updatedToolOutput` |
| `PostToolBatch` | After a full parallel batch of tool calls completes |
| `PermissionRequest` | Auto-approve or deny permission dialogs |
| `SubagentStart` / `SubagentStop` | React to subagent lifecycle events |
| `FileChanged` / `CwdChanged` | Reactive environment management (e.g. direnv) |
| `PreCompact` / `PostCompact` | Before/after context compaction |
| `InstructionsLoaded` | Audit which CLAUDE.md/rules files were loaded |
| `WorktreeCreate` / `WorktreeRemove` | Override default worktree git behavior |
| `Stop` | Cleanup when Claude finishes a turn; can prevent stopping |
| `SessionEnd` | Release resources or save artifacts |

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]`. Use `args: ["cmd", "arg"]` exec form to eliminate shell-quoting issues. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md` (preferred); flat `.claude/commands/*.md` files still work.
- User skills at `~/.claude/skills/<name>/SKILL.md`. Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>`.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… (positional), named args via `arguments:` frontmatter.
- Frontmatter fields: `description`, `disable-model-invocation`, `user-invocable`, `allowed-tools`, `context`, `agent`, `model`, `effort`, `paths`, `hooks`.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`.
- Components sit at the plugin root: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/`, `settings.json`.
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits.
- Test locally with `--plugin-dir ./my-plugin` or `--plugin-url <archive-url>`.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
- Pin plugin versions in team repos; run `/reload-plugins` after edits instead of restarting.
- Namespace plugin skills; never rely on a collision-prone flat name.
- Use exec-form `args: ["cmd", "arg"]` in command hooks to eliminate shell-quoting pitfalls.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md` so supporting files and frontmatter are available.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
