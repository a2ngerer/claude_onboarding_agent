---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-06-09
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

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `fallbackModel`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `skillOverrides`, `parentSettingsBehavior`, `disableBundledSkills`, `requiredMinimumVersion`, `requiredMaximumVersion`. Permission rules evaluate in order `deny → ask → allow`; first match wins. Glob `"*"` in a deny rule denies all calls to that tool.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] },
  "fallbackModel": "claude-sonnet-4-6", "skillOverrides": "user-invocable-only" }
```

## Hooks

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` | Load context or set session metadata | Return `sessionTitle`, `additionalContext`, `reloadSkills` |
| `UserPromptSubmit` | Validate or enrich the user prompt | Block secret patterns |
| `PreToolUse` | Block or gate a tool call | Deny `Bash(rm -rf *)`; return `permissionDecision` |
| `PostToolUse` | Lint or log after a tool runs | Auto-run `eslint --fix` after `Edit` |
| `PostToolBatch` | React after a parallel batch of tool calls | Aggregate lint results across batch |
| `SubagentStart` | Track or gate subagent dispatch | Log context fork |
| `SubagentStop` | Inject feedback after subagent finishes | Return `additionalContext` with build status |
| `MessageDisplay` | Transform displayed assistant text (transcript unchanged) | Strip verbose preamble from rendered output |
| `InstructionsLoaded` | React when CLAUDE.md / rules files are loaded | Validate rule-file consistency |
| `Stop` | Cleanup when Claude finishes a turn | Persist session notes; return `additionalContext` |
| `SessionEnd` | Release resources or save artifacts | Flush metrics |

31 hook events total (see [hooks reference](https://code.claude.com/docs/en/hooks)). Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and `{ type, command }` entries. Plugins ship hooks in `hooks/hooks.json`. Hooks may return a `hookSpecificOutput` object (with `hookEventName` plus event-specific fields like `additionalContext`, `sessionTitle`, `permissionDecision`, `displayContent`) to pass structured control back to Claude.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- `/goal` — set a completion condition; Claude works autonomously across turns until the condition is met.
- `/cd` — move a session to a new working directory without breaking prompt cache.

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `settings.json`.
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits.
- Plugins can declare `defaultEnabled: false` in their manifest. `disableBundledSkills: true` in user settings opts out of all bundled skills globally.

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
