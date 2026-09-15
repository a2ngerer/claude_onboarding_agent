---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-09-15
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
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally; `~/.claude/rules/` holds user-level rules applied to every project.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 4 hops).
- **Auto memory** — a second, Claude-authored system at `~/.claude/projects/<project>/memory/` (machine-local, shared across worktrees of one repo). `MEMORY.md` is the index (first 200 lines / 25KB load every session); per-topic files load on demand. Four types: `user`, `feedback`, `project`, `reference`. Toggle with `/memory` or the `autoMemoryEnabled` setting; Claude skips anything derivable from the codebase or already covered in CLAUDE.md.

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `enforceAvailableModels`. Permission rules evaluate in order `deny → ask → allow`; first match wins, e.g. `{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }`.

- **`fallbackModel`** — model to use when the primary `model` is unavailable or rate-limited.
- **`requiredMinimumVersion`** — semver string; Claude Code refuses to run if the installed version is older.
- **`enforceAvailableModels`** — boolean; when `true`, rejects model IDs not available in the current account/tier at startup rather than failing at runtime.
- **`maxEffortLevel`** / **`modelPricing`** / **`bashOutputMaxChars`** / **`taskOutputMaxChars`** — newer keys: cap effort per model, apply an internal cost multiplier (1–10) for chargeback, and bound tool-output truncation (up to 128K chars).

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
| `SubagentStart` / `SubagentStop` | React to a subagent's lifecycle | Log dispatch; relay a completion summary |
| `MessageDisplay` | Intercept or annotate a message before it is shown | Inject a reminder banner |
| `PreCompact` / `PostCompact` | Save state before compaction, re-inject it after | Checkpoint session notes; reload pinned snippets |
| `PreModelSwitch` / `PostModelSwitch` | React to a mid-session model change | Reload effort-tuned config after `/model` |
| `WorktreeCreate` / `WorktreeRemove` | Set up or clean up a worktree | `npm ci` in the new branch; remove temp build artifacts |
| `Stop` | Cleanup when Claude finishes a turn | Persist session notes |
| `SessionEnd` | Release resources or save artifacts | Flush metrics |

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, command }` entries. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- `/reload-skills` — hot-reload skill/command files without restarting the session.
- `/reload-plugins` — reload plugins, skills, agents, hooks, and plugin MCP/LSP servers after editing a plugin locally.
- `/cd <path>` — change the working directory for the current session.
- `/plugin list` — list installed plugins and their status.
- `/skill-doctor` — reports skill usage and context cost per skill.
- `claude plugin init` — scaffold a new plugin in the current directory (CLI, not a slash command).
- `claude agents` — list all available named subagents (CLI).

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `arguments` | Named positional arguments (e.g. `[component, from-lang, to-lang]`), bound to `$0`/`$1`/… or `$name` |
| `allowed-tools` | Comma-separated tool whitelist for this skill's invocation |
| `disallowed-tools` | Comma-separated tools to remove while this skill is active |
| `model` | Override model for this skill (accepts aliases: `fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low` / `normal` / `high` — hint to the model's thinking budget |
| `context: fork` | Run the skill in a forked, isolated subagent context |
| `agent` | Subagent type to run under `context: fork` (e.g. `Explore`, `Plan`, `general-purpose`) |
| `background` | `true` (default) — run a forked skill in the background; `false` — wait for its result in-turn |
| `paths` | Glob list — load this skill only when CWD matches |
| `disable-model-invocation` | `true` — skill runs its command without calling the model (pure automation) |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; only callable programmatically |

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`, `displayName`, `defaultEnabled`, `dependencies`.
  - `displayName` — human-readable name shown in the marketplace and `/plugin list`.
  - `defaultEnabled` — boolean; whether the plugin activates on install without user opt-in.
  - `dependencies` — list of other plugin names that must be installed for this plugin to function.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/` (executables added to the Bash tool's `PATH`), `settings.json`.
- A plugin's own `settings.json` supports exactly two keys: `agent` (activate one of the plugin's custom agents as the main thread) and `subagentStatusLine`.
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
- Pin plugin versions in team repos; namespace plugin skills to avoid collisions; run `/reload-plugins` after edits instead of restarting.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/` (only `plugin.json` belongs there), and do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md` so supporting files and frontmatter are available.
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
