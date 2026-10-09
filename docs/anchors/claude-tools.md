---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-10-09
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
- `AGENTS.md` — read natively since v2.1.277, but only when no `CLAUDE.md` / `CLAUDE.local.md` exists in the working directory or above. If the repo has both, `CLAUDE.md` imports it with `@AGENTS.md`, or set the built-in plugin option `instructionFiles: claude-md-and-agents-md`.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 4 hops). Imports organize a file but do not reduce its context cost.

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
| `SessionStart` | Load context or env vars on session open | Inject current git branch |
| `InstructionsLoaded` | React to what triggered loading (new session, `/reload-skills`, plugin install); inspect `load_reason` | Log which skills were loaded |
| `UserPromptSubmit` | Validate or enrich the user prompt | Block secret patterns |
| `PreToolUse` | Block or gate a tool call | Deny `Bash(rm -rf *)` |
| `PostToolUse` / `PostToolUseFailure` | Lint or log after a tool call succeeds / fails | Auto-run `eslint --fix` after `Edit` |
| `PostToolBatch` | React after a full parallel tool batch completes | Summarize a batch of file reads |
| `MessageDisplay` | Intercept or annotate a message before it is shown | Inject a reminder banner |
| `PreCompact` / `PostCompact` | Save state before / re-inject context after compaction | Checkpoint session notes |
| `WorktreeCreate` / `WorktreeRemove` | Set up / clean up a worktree | `npm ci` in the new branch |
| `Stop` / `StopFailure` | Cleanup when Claude finishes a turn / the turn ends on an API error | Persist session notes |
| `SessionEnd` | Release resources or save artifacts | Flush metrics |

The reference lists 33 events in total; others include `PermissionRequest`, `PermissionDenied`, `SubagentStart`, `SubagentStop`, `PreModelSwitch`, `PostModelSwitch`, `Elicitation`, `ElicitationResult`, `Notification`, `TaskCreated`, `TaskCompleted`, `ConfigChange`, `CwdChanged`, and `FileChanged`.

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of handlers. Handler `type` is `command`, `http`, `mcp_tool`, `prompt`, or `agent` (experimental). Common fields: `if` (permission-rule filter on tool events), `timeout` (seconds), `statusMessage`. `command` handlers also accept `args` (exec form, no shell). Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- `/reload-skills` — hot-reload skill/command files without restarting the session.
- `/cd <path>` — change the working directory for the current session.
- `/plugin list` — list installed plugins and their status.
- `/skill-doctor` — report each skill's context cost and usage.
- `/doctor` — setup checkup; `/doctor prompt-audit` audits instruction files (CLAUDE.md, rules, skills, subagents).
- CLI (not slash commands): `claude plugin init` scaffolds a plugin, `claude plugin validate` checks it, `claude plugin eval` measures skill effectiveness with and without it, `claude agents` lists named subagents.

## SKILL.md frontmatter fields

Only `description` is recommended. Unrecognized fields are ignored without error.

| Field | Purpose |
|---|---|
| `when_to_use` | Extra trigger phrases; combined with `description` it is truncated at 1,536 characters |
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `allowed-tools` / `disallowed-tools` | Tools pre-approved during the invoking turn / removed while the skill is active |
| `model` | Override model for this skill (accepts aliases: `fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | Effort-level override while the skill is active |
| `context: fork` | Run the skill in a subagent (isolated from main conversation); pair with `agent:` to pick the subagent type |
| `background` | With `context: fork`, `false` waits for the result (default `true`) |
| `hooks` | Hooks registered when the skill is invoked |
| `paths` | Glob list — limits automatic activation to matching files |
| `shell` | `bash` (default) or `powershell` for `` !`command` `` blocks |
| `disable-model-invocation` | `true` — Claude never loads the skill on its own; only the user can invoke it |
| `user-invocable` | `false` — hides the skill from the `/` menu; only Claude invokes it |

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`, `displayName`, `defaultEnabled`, `dependencies`.
  - `displayName` — human-readable name shown in the marketplace and `/plugin list`.
  - `defaultEnabled` — boolean; whether the plugin activates on install without user opt-in.
  - `dependencies` — list of other plugin names that must be installed for this plugin to function.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `settings.json`.
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
- Pin plugin versions in team repos; run `/reload-plugins` after edits instead of restarting. Namespace plugin skills.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not assume `AGENTS.md` loads alongside `CLAUDE.md` — by default it is read only when no `CLAUDE.md` exists. Import it from `CLAUDE.md` with `@AGENTS.md` when both are needed.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
