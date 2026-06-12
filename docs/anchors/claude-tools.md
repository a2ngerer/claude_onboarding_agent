---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-06-12
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
- `AGENTS.md` — not read natively by Claude Code. Import it from `CLAUDE.md` with `@AGENTS.md` if the repo needs both.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally. Directory scanned recursively; symlinks supported.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 4 hops).
- **Auto memory**: Claude writes notes to `~/.claude/projects/<project>/memory/MEMORY.md` automatically. The first 200 lines or 25 KB loads every session; topic files load on demand. Toggle with `autoMemoryEnabled`; browse with `/memory`.

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `effortLevel`, `availableModels`, `requiredMinimumVersion`, `requiredMaximumVersion`, `disableBundledSkills`, `disableWorkflows`, `autoMemoryEnabled`, `autoMemoryDirectory`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

## Hooks

| Event | Typical use |
|---|---|
| `SessionStart` | Load context or env vars; can return `reloadSkills: true` to reload skill dirs |
| `UserPromptSubmit` | Validate or enrich the user prompt |
| `PreToolUse` | Block or gate a tool call |
| `PostToolUse` | Lint or log after a tool runs (e.g. `eslint --fix` after `Edit`) |
| `PostToolBatch` | After a set of parallel tool calls all resolve |
| `MessageDisplay` | Transform displayed assistant text (display-only; does not affect transcript) |
| `Stop` | Cleanup when Claude finishes a turn; return `additionalContext` to continue the turn |
| `StopFailure` | Handle API error at turn end |
| `SubagentStart` / `SubagentStop` | Audit or collect metrics on subagent lifecycle |
| `PreCompact` / `PostCompact` | Checkpoint or restore state around context compaction |
| `CwdChanged` | React to working-directory change mid-session |
| `SessionEnd` | Release resources or save artifacts |

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and `{ type, command }` entries. Exec form (`"args": []`) spawns commands without a shell. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- Built-in additions: `/goal` (keep working until a condition is met), `/cd` (change working directory mid-session without breaking prompt cache), `/reload-skills` (re-scan skill dirs in the current session), `/code-review` (replaced `/simplify`).

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (optional semver), `description`, optional `author`, `homepage`, `repository`.
- Components at the plugin root (not inside `.claude-plugin/`): `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/`, `settings.json`.
- `monitors/monitors.json` — background monitors that watch logs or files and push event lines to Claude as notifications.
- `bin/` — executables added to the Bash tool's `PATH` while the plugin is enabled.
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
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md`.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
- Do not use `/simplify` — it has been replaced by `/code-review`.
