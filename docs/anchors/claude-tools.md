---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-06-02
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
- **Auto memory:** Claude saves project learnings (build commands, debug patterns, preferences) to `~/.claude/projects/<repo>/memory/` automatically. `MEMORY.md` (first 200 lines) loads every session. Toggle with `autoMemoryEnabled` in settings or `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`.

## Settings

Top-level keys in `.claude/settings.json` (non-exhaustive): `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `autoMode`, `effortLevel`, `worktree`, `autoMemoryEnabled`, `disableAgentView`, `teammateMode`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

## Hooks

| Event | Typical use | Blocking |
|---|---|---|
| `SessionStart` | Load context or env vars; may return `reloadSkills: true` to reload skill files | No |
| `UserPromptSubmit` | Validate or enrich the user prompt | Yes |
| `PreToolUse` | Block or gate a tool call | Yes |
| `PostToolUse` | Lint or log after a tool runs | No |
| `Stop` | Cleanup when Claude finishes a turn; input includes `background_tasks` and `session_crons` | Yes |
| `SubagentStop` | Hook into subagent completion | Yes |
| `MessageDisplay` | Transform how an assistant message is displayed (transcript unchanged) | No |
| `PreCompact` | Block or prepare for context compaction | Yes |
| `PostCompact` | Log or react after compaction | No |
| `SessionEnd` | Release resources or save artifacts | No |

Hook handler types: `command` (shell script), `http` (webhook POST), `mcp_tool` (call an MCP tool directly), `prompt` (invoke a model for a decision), `agent` (experimental agentic handler).

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of handler entries. Plugins ship hooks in `hooks/hooks.json`. Hooks inside skill/agent frontmatter use `once: true` to run once per session.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Skill frontmatter options: `disallowed-tools:` restricts which tools Claude may use within the skill; `disable-model-invocation: true` makes the skill user-invoked only (no auto-trigger).
- Run `/reload-skills` to pick up skill file edits without restarting the session.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`.
- Components sit at the plugin root: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/`, `settings.json`. Nothing except `plugin.json` belongs inside `.claude-plugin/`.
- `bin/` — executables added to `PATH` inside the Bash tool while the plugin is active.
- `monitors/monitors.json` — background processes whose stdout lines are delivered to Claude as notifications during the session.
- Plugin `settings.json` supports `agent` key to set a default subagent as the main-thread persona.
- `claude plugin init <name>` scaffolds a plugin in `~/.claude/skills/<name>/` (auto-loads without `--plugin-dir`).
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
- Pin plugin versions in team repos; run `/reload-plugins` after edits instead of restarting.
- Namespace plugin skills; never rely on a collision-prone flat name.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md` so supporting files and frontmatter are available.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
