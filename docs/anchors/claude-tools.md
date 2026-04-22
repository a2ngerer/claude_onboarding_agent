---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-04-22
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
- **Auto memory:** Claude writes its own notes to `~/.claude/projects/<project>/memory/MEMORY.md`. First 200 lines (or 25 KB) load each session. Toggle with `autoMemoryEnabled` setting or `/memory` command.

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `effortLevel`, `allowManagedHooksOnly`, `disableSkillShellExecution`, `showThinkingSummaries`, `statusLine`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

## Hooks

26 hook events span the full Claude Code lifecycle. Key events:

| Event | Trigger | Blocking |
|---|---|---|
| `SessionStart` | Session opens or resumes | No |
| `SessionEnd` | Session terminates | No |
| `UserPromptSubmit` | User submits a prompt | Yes |
| `PreToolUse` | Before a tool call executes | Yes |
| `PostToolUse` | After a tool call succeeds | Yes (feedback) |
| `Stop` | Claude finishes a turn | Yes |
| `StopFailure` | Turn ends due to API error | No |
| `PreCompact` | Before context compaction | Yes |
| `PostCompact` | After compaction completes | No |
| `CwdChanged` | Working directory changes | No |
| `FileChanged` | Watched file changes on disk | No |
| `TaskCreated` | Task created via `TaskCreate` | Yes |
| `Elicitation` | MCP server requests user input | Yes |
| `ElicitationResult` | After user responds to elicitation | Yes |

Hook handler types: `command`, `http`, `prompt`, `agent`. Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and handler list. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands / Skills

- Skills live at `.claude/skills/<name>/SKILL.md`; commands at `.claude/commands/<name>.md`; user skills at `~/.claude/skills/`. Both create the same `/name` slash command.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Key frontmatter: `description`, `disable-model-invocation`, `allowed-tools`, `context: fork`, `agent`, `effort`, `paths`, `hooks`, `model`.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`.
- Components sit at the plugin root: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `settings.json`, `bin/`.
- `bin/` executables are added to Bash's `PATH` while the plugin is enabled.
- Version every release; `/reload-plugins` picks up local edits; `--plugin-dir ./path` for local dev testing.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Use `CwdChanged` / `FileChanged` hooks for reactive environment management (e.g. reload `.envrc` on change).
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
- Pin plugin versions in team repos; run `/reload-plugins` after edits instead of restarting.
- Namespace plugin skills; never rely on a collision-prone flat name.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md`.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
