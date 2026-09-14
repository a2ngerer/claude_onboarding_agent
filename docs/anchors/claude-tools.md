---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-09-14
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
- `AGENTS.md` — not read natively by Claude Code. Import it from `CLAUDE.md` with `@AGENTS.md`, or symlink `CLAUDE.md -> AGENTS.md` (Unix only; use the import on Windows).
- **Auto memory** — Claude also writes its own notes (`user`/`feedback`/`project`/`reference` types) to `~/.claude/projects/<project>/memory/`: a `MEMORY.md` index (loaded every session, capped at 200 lines/25KB) plus per-topic files read on demand. Toggle with `autoMemoryEnabled` in settings; browse and edit with `/memory`.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 4 hops).

## Settings

Precedence, highest first: managed settings → CLI flags → `.claude/settings.local.json` (project-local) → `.claude/settings.json` (shared project) → `~/.claude/settings.json` (user). A key set at a higher level overrides the same key set at a lower one.

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `enforceAvailableModels`, `autoMemoryEnabled`, `autoMemoryDirectory`, `maxEffortLevel`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — model to use when the primary `model` is unavailable or rate-limited.
- **`requiredMinimumVersion`** — semver string; Claude Code refuses to run if the installed version is older.
- **`enforceAvailableModels`** — boolean; when `true`, rejects model IDs not available in the current account/tier at startup rather than failing at runtime.
- **`maxEffortLevel`** — caps the thinking-effort level across all providers (Bedrock, Vertex, Foundry).

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI environments or troubleshooting a broken config.

## Hooks

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` | Load context or env vars on session open | Inject current git branch |
| `InstructionsLoaded` | React to what triggered loading (new session, `/reload-skills`, plugin install); inspect `load_reason` | Log which skills were loaded |
| `UserPromptSubmit` | Validate or enrich the user prompt | Block secret patterns |
| `PreToolUse` | Block or gate a tool call | Deny `Bash(rm -rf *)` |
| `PostToolUse` | Lint or log after a tool runs | Auto-run `eslint --fix` after `Edit` |
| `PostToolBatch` | React after a full parallel tool batch completes | Summarize a batch of file reads |
| `MessageDisplay` | Intercept or annotate a message before it is shown | Inject a reminder banner |
| `PreModelSwitch` / `PostModelSwitch` | Block, confirm, or annotate a model switch | Deny switching away from a pinned eval model |
| `PreCompact` / `PostCompact` | Save/restore state around context compaction | Checkpoint and reload session notes |
| `WorktreeCreate` / `WorktreeRemove` | Set up or tear down a worktree | `npm ci` in a new branch |
| `Stop` / `SessionEnd` | Cleanup when Claude finishes a turn or session | Persist session notes, flush metrics |

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, command }` entries. Plugins ship hooks in `hooks/hooks.json`. This table covers the common events — Claude Code ships 30+ total, including subagent (`SubagentStart`/`SubagentStop`), task (`TaskCreated`/`TaskCompleted`), and permission (`PermissionRequest`/`PermissionDenied`) lifecycle events; see the official hooks reference for the full list.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- `/reload-skills` — hot-reload project/personal skill and command files. `/reload-plugins` — reload plugin skills, agents, hooks, and MCP servers after edits.
- `/cd <path>` — change the working directory for the current session.
- `/plugin list` — list installed plugins and their status. `/skill-doctor` — show unused skills and their context cost.
- `/output-style [name]` / `/diff` — switch output styles / open a live diff panel for uncommitted changes.
- `claude plugin init` — scaffold a new plugin in the current directory (CLI, not a slash command).
- `claude agents` — list all available named subagents (CLI).

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `allowed-tools` / `disallowed-tools` | Comma-separated tool allow/deny list for this skill's invocation |
| `arguments` | Named positional argument list (access as `$name`) |
| `when_to_use` | Extra trigger context beyond `description`, used for model-invocation matching |
| `model` | Override model for this skill (accepts aliases: `fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low` / `normal` / `high` — hint to the model's thinking budget |
| `context: fork` | Run the skill in an isolated subagent context; pair with `agent:` (subagent type, default `general-purpose`) and `background:` (wait for result, default `true`) |
| `paths` | Glob list — load this skill only when CWD matches |
| `disable-model-invocation` | `true` — skill runs its command without calling the model (pure automation) |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; only callable programmatically |

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`, `displayName`, `defaultEnabled`, `dependencies`.
  - `displayName` — human-readable name shown in the marketplace and `/plugin list`.
  - `defaultEnabled` — boolean; whether the plugin activates on install without user opt-in.
  - `dependencies` — list of other plugin names that must be installed for this plugin to function.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/` (executables added to the Bash tool's `PATH`), `settings.json`.
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
