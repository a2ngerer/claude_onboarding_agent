---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-11-24
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
- `AGENTS.md` — read natively (v2.1.277+) only when no `CLAUDE.md`/`CLAUDE.local.md` exists in or above the working directory. If both exist, `CLAUDE.md` must import it with `@AGENTS.md`.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth four hops).

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `enforceAvailableModels`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — model to use when the primary `model` is unavailable or rate-limited.
- **`requiredMinimumVersion`** — semver string; Claude Code refuses to run if the installed version is older.
- **`enforceAvailableModels`** — boolean; when `true`, rejects model IDs not available in the current account/tier at startup rather than failing at runtime.

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI environments or troubleshooting a broken config.

## Hooks

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` / `Setup` | Load context or env on open; one-time prep (`--init`) | Inject current git branch |
| `InstructionsLoaded` | React to CLAUDE.md / rules loading; inspect `load_reason` | Log which rules were loaded |
| `UserPromptSubmit` / `UserPromptExpansion` | Validate or enrich a prompt, or block a command expansion | Block secret patterns |
| `PreToolUse` | Block or gate a tool call | Deny `Bash(rm -rf *)` |
| `PermissionRequest` / `PermissionDenied` | Decide a permission prompt; react to auto-mode denials (`retry`) | Auto-allow a safe command |
| `PostToolUse` / `PostToolUseFailure` | Lint or log after a tool succeeds or fails | Auto-run `eslint --fix` after `Edit` |
| `PostToolBatch` | React after a full parallel tool batch completes | Summarize a batch of reads |
| `SubagentStart` / `SubagentStop` | Track subagent lifecycle | Log delegated work |
| `TaskCreated` / `TaskCompleted` | Gate or log task state | Require tests before completion |
| `MessageDisplay` | Annotate a message before it is shown | Inject a reminder banner |
| `PreCompact` / `PostCompact` | Save state before, re-inject context after compaction | Reload pinned snippets |
| `ConfigChange` / `CwdChanged` / `FileChanged` / `DirectoryAdded` | React to config, directory, or watched-file changes | Reload env on `cd` |
| `PreModelSwitch` / `PostModelSwitch` | Gate or log a model switch | Block switching to Fable |
| `Elicitation` / `ElicitationResult` | Intercept MCP requests for user input | Auto-answer a known prompt |
| `WorktreeCreate` / `WorktreeRemove` | Set up or clean up a worktree | `npm ci` in the new branch |
| `Stop` / `StopFailure` / `SessionEnd` | Cleanup when a turn, API-error turn, or session ends | Persist session notes |

Command, HTTP, and `mcp_tool` hooks accept `"onFailure": "block"` so a hook error blocks the call instead of passing it. Prompt hooks accept model aliases (`haiku`, `sonnet`) in `model`.

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, command }` entries. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- `/reload-skills` — hot-reload skill/command files without restarting the session.
- `/cd <path>` — change the working directory for the current session.
- `/plugin list` — list installed plugins and their status.
- `claude plugin init` — scaffold a new plugin in the current directory (CLI, not a slash command).
- `claude agents` — list all available named subagents (CLI).

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `allowed-tools` | Comma-separated tool whitelist for this skill's invocation |
| `model` | Override model for this skill (accepts aliases: `fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low` / `medium` / `high` / `xhigh` / `max` — effort for the invoking turn |
| `context: fork` | Run the skill in a forked context (isolated from main conversation) |
| `agent` | Subagent type to use when `context: fork` is set |
| `paths` | Glob list — activate this skill only for matching files |
| `when_to_use` / `disallowed-tools` / `hooks` | Extra trigger phrases; tools removed while active; hooks scoped to the skill |
| `disable-model-invocation` | `true` — Claude cannot load the skill on its own; user-invoked only |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; only callable programmatically |

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`, `displayName`, `defaultEnabled`, `dependencies`, `optionalDependencies`.
  - `displayName` — human-readable name shown in the marketplace and `/plugin list`.
  - `defaultEnabled` — boolean; whether the plugin activates on install without user opt-in.
  - `dependencies` — other plugins that must be installed; `optionalDependencies` — plugins that can be disabled or uninstalled independently.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `settings.json`.
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
- Pin plugin versions in team repos; run `/reload-plugins` after edits instead of restarting.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read when a `CLAUDE.md` exists — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md` so supporting files and frontmatter are available.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
