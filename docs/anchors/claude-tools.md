---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-06-08
sources:
  - https://docs.claude.com/en/docs/claude-code/hooks
  - https://docs.claude.com/en/docs/claude-code/settings
  - https://docs.claude.com/en/docs/claude-code/plugins
  - https://docs.claude.com/en/docs/claude-code/slash-commands
  - https://docs.claude.com/en/docs/claude-code/memory
version: 2
---

## Memory files

- `CLAUDE.md` — project instructions at `./CLAUDE.md` or `./.claude/CLAUDE.md`; user-level at `~/.claude/CLAUDE.md`; org-managed at `/etc/claude-code/CLAUDE.md` (Linux/WSL) or `/Library/Application Support/ClaudeCode/CLAUDE.md` (macOS). Loaded into every session.
- `CLAUDE.local.md` — personal project notes; gitignored, appended after `CLAUDE.md`.
- `AGENTS.md` — not read natively by Claude Code. Import from `CLAUDE.md` with `@AGENTS.md`.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 5).
- **Auto memory**: Claude writes notes to `~/.claude/projects/<repo>/memory/`; first 200 lines of `MEMORY.md` load per session. Toggle with `autoMemoryEnabled`. Inspect with `/memory`.

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `autoMemoryEnabled`, `effortLevel`, `autoMode`, `fallbackModel`. Permission rules evaluate in order `deny → allow → ask`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

## Hooks

Handlers live under `hooks.<EventName>[]` in `.claude/settings.json` (or `hooks/hooks.json` for plugins) with a `matcher` and handler entries. Handler types: `command`, `http`, `mcp_tool`, `prompt`, `agent`. Use `args: string[]` for exec-form shell-free dispatch.

| Event | Purpose | Blocking? |
|---|---|---|
| `SessionStart` | Load context or env vars; can return `reloadSkills: true` | No |
| `UserPromptSubmit` | Validate or enrich the user prompt | Yes |
| `UserPromptExpansion` | After a slash command expands into a prompt | Yes |
| `PreToolUse` | Block or gate a tool call | Yes |
| `PostToolUse` | Lint or log after a tool; `continueOnBlock: true` feeds rejection back to Claude | No |
| `PostToolBatch` | After a batch of parallel tool calls resolves | Yes |
| `MessageDisplay` | Transform or hide assistant message text as it displays | No |
| `Stop` | Cleanup when Claude finishes; can return `additionalContext` to continue the turn | Yes |
| `SubagentStop` | When a subagent finishes; can return `additionalContext` | Yes |
| `PreCompact` / `PostCompact` | Before/after context compaction | Pre: Yes |
| `InstructionsLoaded` | When a CLAUDE.md or rules file loads | No |
| `ConfigChange` | Config file changed during session | Yes |
| `WorktreeCreate` / `WorktreeRemove` | Worktree lifecycle | Create: Yes |
| `SessionEnd` | Release resources or save artifacts | No |

## Slash commands

Skills and commands are merged. Project skills at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`; legacy `.claude/commands/*.md` still work. Plugin skills are namespaced: `/<plugin-name>:<skill-name>`. Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… (positional); escape literal `$` before a digit with `\$`. Frontmatter options: `disable-model-invocation: true`, `disallowed-tools: [...]`. Run `/reload-skills` to pick up local edits without restarting.

## Plugins

- Manifest: `.claude-plugin/plugin.json` — fields: `name`, `description`, optional `version` (omit to version by git SHA), `author` (object), `homepage`, `repository`, `defaultEnabled`.
- Components at the plugin **root** (not inside `.claude-plugin/`): `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/monitors.json`, `bin/`, `settings.json`.
- `monitors/monitors.json` — background monitors that stream stdout lines to Claude as notifications.
- `bin/` — executables added to the Bash tool PATH while the plugin is enabled.
- Local testing: `claude --plugin-dir ./my-plugin` (also accepts a `.zip` archive); `/reload-skills` picks up edits.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands, deny reads of secrets.
- Pin plugin versions in team repos; run `/reload-skills` after edits.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not use `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md`.
- Do not rely on `AGENTS.md` being read directly — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
