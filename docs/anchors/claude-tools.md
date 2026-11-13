---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-11-13
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
- `AGENTS.md` — Claude Code can use a repository's `AGENTS.md` in place of `CLAUDE.md`; if the repo keeps both, `CLAUDE.md` should import it with `@AGENTS.md`.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 5).

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `enforceAvailableModels`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — model to use when the primary `model` is unavailable or rate-limited.
- **`requiredMinimumVersion`** — semver string; Claude Code refuses to run if the installed version is older.
- **`permissions.denyInsteadOfPrompting`** — when `true`, a tool call that would wait on a permission prompt is denied and the turn continues (useful for unattended runs).
- **`enforceAvailableModels`** — boolean; when `true`, rejects model IDs not available in the current account/tier at startup rather than failing at runtime.
- **`CLAUDE_CODE_SAFE_MODE=1`** (env) — disables CLAUDE.md, plugins, skills, hooks, and MCP servers; useful for CI or debugging a broken config.

## Hooks

Claude Code supports 33 hook events. Common ones:

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` / `SessionEnd` | Load context on open; release resources on close | Inject current git branch |
| `UserPromptSubmit` | Validate or enrich the user prompt | Block secret patterns |
| `PreToolUse` | Block or gate a tool call | Deny `Bash(rm -rf *)` |
| `PostToolUse` / `PostToolUseFailure` | Lint or log after a tool runs or fails | Auto-run `eslint --fix` after `Edit` |
| `PostToolBatch` | React after a full parallel tool batch | Summarize a batch of file reads |
| `PermissionRequest` / `PermissionDenied` | Observe or answer permission decisions | Audit-log denials |
| `SubagentStart` / `SubagentStop` | Track delegated work | Log subagent results |
| `Stop` / `StopFailure` | Cleanup when Claude finishes (or fails) a turn | Persist session notes |
| `PreCompact` / `PostCompact` | Save and restore state around compaction | Reload pinned snippets |
| `InstructionsLoaded` | React to what triggered loading; inspect `load_reason` | Log which skills were loaded |
| `PreModelSwitch` / `PostModelSwitch` | React to `/model` changes | Warn about cache re-read cost |
| `WorktreeCreate` / `WorktreeRemove` | Set up or clean a worktree | `npm ci` in the new branch |
| `ConfigChange`, `CwdChanged`, `FileChanged` | React to environment changes | Reload env on `.env` edit |

Others: `Setup`, `UserPromptExpansion`, `TaskCreated`, `TaskCompleted`, `TeammateIdle`, `Elicitation`, `ElicitationResult`, `DirectoryAdded`, `Notification`, `MessageDisplay`. Unknown event names produce a settings warning and are skipped.

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a nested `hooks` list of `{ type, command }` entries. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- `/reload-skills` — load skills after creating a top-level skills directory mid-session.
- `/cd <path>` — move the session to another directory (re-reads project settings and skills there).
- `/add-dir <path>` — add a directory and load its `.claude/skills/` immediately.
- `/plugin` — manage plugins; `/skill-doctor` — per-skill context cost and usage.

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `name` / `description` | Command name (defaults to directory) and when-to-use text; `description` is the one recommended field |
| `when_to_use` | Extra trigger context appended to `description` (combined text cut at 1,536 chars) |
| `argument-hint` / `arguments` | Autocomplete placeholder; named positional args (`arguments: [issue, branch]` → `$issue`) |
| `allowed-tools` / `disallowed-tools` | Tools pre-approved for, or removed during, the skill's turn |
| `model` / `effort` | Model alias or effort level for the turn |
| `context: fork` + `agent` | Run the skill in a forked subagent; `agent` picks the subagent type |
| `background` | With `context: fork`, `false` waits for the result in the current turn |
| `hooks` | Hooks registered when the skill is invoked |
| `paths` | Glob list — auto-load only when matching files are touched |
| `shell` | `bash` (default) or `powershell` for `` !`cmd` `` injection |
| `disable-model-invocation` | `true` — Claude never loads the skill on its own; user invokes it |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; only Claude can use it |

Unrecognized fields are silently ignored. Substitutions: `${CLAUDE_SKILL_DIR}`, `${CLAUDE_PROJECT_DIR}`, `${CLAUDE_SESSION_ID}`, `${CLAUDE_EFFORT}`; plugin skills also get `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_PLUGIN_DATA}`.

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`, `displayName`, `defaultEnabled`, `dependencies`, `engines`.
  - `engines["claude-code"]` — semver range (e.g. `">=2.1.323"`); blocks the plugin on out-of-range Claude Code versions.
  - `displayName` — human-readable name shown in the marketplace and `/plugin list`.
  - `defaultEnabled` — boolean; whether the plugin activates on install without user opt-in.
  - `dependencies` — list of other plugin names that must be installed for this plugin to function.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `settings.json`.
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits; `claude plugin disable` turns a plugin off without uninstalling.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md` so supporting files and frontmatter are available.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
