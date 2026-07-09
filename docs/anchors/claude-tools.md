---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-07-09
sources:
  - https://docs.claude.com/en/docs/claude-code/hooks
  - https://docs.claude.com/en/docs/claude-code/settings
  - https://docs.claude.com/en/docs/claude-code/plugins
  - https://docs.claude.com/en/docs/claude-code/slash-commands
  - https://docs.claude.com/en/docs/claude-code/memory
version: 3
---

## Memory files

- `CLAUDE.md` — project instructions at `./CLAUDE.md` or `./.claude/CLAUDE.md`; user-level at `~/.claude/CLAUDE.md`. Loaded into every session.
- `CLAUDE.local.md` — personal project notes; gitignored, appended after `CLAUDE.md`.
- `AGENTS.md` — not read natively by Claude Code. If the repo needs both, `CLAUDE.md` imports it with `@AGENTS.md`.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 4).

## Auto memory

Separate from `CLAUDE.md`, Claude writes its own persistent notes to `~/.claude/projects/<project>/memory/` (an entrypoint `MEMORY.md` plus topic files), based on corrections and preferences it observes. On by default since v2.1.59; toggle with `/memory` or `"autoMemoryEnabled": false`. Only the first 200 lines / 25KB of `MEMORY.md` load at session start — topic files load on demand.

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `enforceAvailableModels`, `autoMemoryEnabled`, `autoMemoryDirectory`, `skillOverrides`, `disableBundledSkills`. Permission rules evaluate `deny → allow → ask`, merging across scopes rather than overriding.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — model(s) to use when the primary `model` is unavailable or rate-limited (up to 3, tried in order); **`requiredMinimumVersion`** — semver string Claude Code enforces at startup.
- **`enforceAvailableModels`** — boolean; when `true`, rejects model IDs not available in the current account/tier at startup rather than failing at runtime.

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI environments or troubleshooting a broken config.

## Hooks

Claude Code supports 30+ lifecycle hook events. Common ones:

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` | Load context or env vars on session open | Inject current git branch |
| `InstructionsLoaded` | React to what triggered loading (new session, `/reload-skills`, plugin install); inspect `load_reason` | Log which skills were loaded |
| `UserPromptSubmit` | Validate or enrich the user prompt | Block secret patterns |
| `PreToolUse` | Block or gate a tool call | Deny `Bash(rm -rf *)` |
| `PostToolUse` | Lint or log after a tool runs | Auto-run `eslint --fix` after `Edit` |
| `PostToolBatch` | React after a full parallel tool batch completes | Summarize a batch of file reads |
| `SubagentStart` / `SubagentStop` | React to a subagent's lifecycle, matched by agent type | Set up/tear down a DB connection for `db-agent` |
| `MessageDisplay` | Rewrite displayed text without changing what Claude sees | Redact secrets from terminal output |
| `PreCompact` / `PostCompact` | Save/restore state around context compaction | Checkpoint or reload session notes |
| `WorktreeCreate` / `WorktreeRemove` | Set up or tear down a git worktree | `npm ci` in the new branch |
| `Stop` / `SessionEnd` | Cleanup when Claude finishes a turn or session ends | Persist session notes, flush metrics |

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, command }` entries. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills and custom commands are merged: `.claude/skills/<name>/SKILL.md` and legacy `.claude/commands/<name>.md` both create `/<name>`.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Bundled skills (`/code-review`, `/debug`, `/loop`, `/claude-api`, …) are prompt-based, not fixed logic; disable with `disableBundledSkills`.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter. Up to 6 skills can be stacked in one message.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- `/reload-skills` — hot-reload skill/command files without restarting the session.
- `/cd <path>` — change the working directory for the current session.
- `/plugin list` — list installed plugins and their status.
- `claude plugin init <name>` — scaffold a skills-directory plugin at `~/.claude/skills/<name>/` that auto-loads every session, no marketplace needed.
- `claude agents` — list all available named subagents (CLI).

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `when_to_use` | Extra trigger phrases, appended to `description` (shares its 1,536-char cap) |
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `arguments` | Named positional args for `$name` substitution (space-separated string or YAML list) |
| `allowed-tools` | Tools usable without per-call approval while the skill is active |
| `disallowed-tools` | Tools removed from the pool while the skill is active |
| `model` | Override model for this skill (accepts aliases: `fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low` / `medium` / `high` / `xhigh` / `max` — thinking-budget hint |
| `context: fork` | Run the skill in a forked subagent context (isolated from main conversation) |
| `agent` | Which subagent type to use when `context: fork` is set |
| `paths` | Glob list — auto-load this skill only when CWD/files match |
| `shell` | `bash` (default) or `powershell` for inline `` !`command` `` injection |
| `disable-model-invocation` | `true` — only you can invoke the skill, never Claude automatically |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; only callable by Claude |

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`, `displayName`, `defaultEnabled`, `dependencies`.
  - `defaultEnabled` — boolean; whether the plugin activates on install without user opt-in.
  - `dependencies` — list of other plugin names that must be installed for this plugin to function.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/`, `settings.json`.
- Two official marketplaces: curated `claude-plugins-official` and reviewed `claude-community`. Run `claude plugin validate` before submitting either.
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md` so supporting files and frontmatter are available.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
