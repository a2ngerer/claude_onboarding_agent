---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-04-25
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

Top-level key groups in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `autoMode`, `effortLevel`, `alwaysThinkingEnabled`, `prUrlTemplate`, `attribution`, `editorMode`, and more — see the full reference at `code.claude.com/docs/en/settings`.

Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

**Settings hierarchy** (highest → lowest precedence):
1. Managed settings (IT/admin-deployed via MDM or system directory — cannot be overridden)
2. CLI arguments (session-only)
3. `.claude/settings.local.json` (personal project, gitignored)
4. `.claude/settings.json` (shared project, in source control)
5. `~/.claude/settings.json` (user global)

Array settings (e.g. `permissions.allow`) **merge** across all scopes rather than being replaced.

## Hooks

| Event | When it fires | Practical use |
|---|---|---|
| `SessionStart` | Session opens or resumes | Inject context or env vars |
| `SessionEnd` | Session terminates | Flush metrics or save artifacts |
| `InstructionsLoaded` | A `CLAUDE.md` or `.claude/rules/*.md` file loads | Log or gate which rule files are active |
| `UserPromptSubmit` | User submits a prompt | Block secret patterns, enrich input |
| `UserPromptExpansion` | Slash command expands to a prompt | Transform or cancel command expansion |
| `PreToolUse` | Before a tool call executes | Block dangerous commands |
| `PostToolUse` | After a tool call succeeds | Auto-run linters; input includes `duration_ms` |
| `PostToolUseFailure` | After a tool call fails | Alert or retry; also includes `duration_ms` |
| `PostToolBatch` | After a batch of parallel tool calls resolves | Aggregate results from parallel work |
| `Stop` | Claude finishes a turn | Persist session notes |
| `StopFailure` | Turn ends due to API error | Surface or handle the error |
| `SubagentStart` / `SubagentStop` | Subagent spawned / finishes | Observe delegation boundaries |
| `PreCompact` / `PostCompact` | Before / after context compaction | Save or restore state around compaction |
| `WorktreeCreate` / `WorktreeRemove` | Worktree created / removed | Replace default git worktree behaviour |

Hook entry types: `command` (shell), `http` (webhook), `prompt` (Claude turn), `agent` (subagent), `mcp_tool` (invoke an MCP server tool directly — available after Claude Code connects to MCP servers).

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, ... }` entries. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `settings.json`, `themes/`.
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
