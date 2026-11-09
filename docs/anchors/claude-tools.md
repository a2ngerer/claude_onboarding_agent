---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-11-09
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
- `AGENTS.md` — Claude Code can read a repository's `AGENTS.md` in place of `CLAUDE.md`. If the repo keeps both, have `CLAUDE.md` import it with `@AGENTS.md` to avoid drift.
- Auto memory — notes Claude writes itself (first 200 lines / 25KB loaded each session); complements, not replaces, `CLAUDE.md`. Memory is context, not enforcement: block actions with a `PreToolUse` hook.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 5).

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `enforceAvailableModels`, `availableModels`, `deniedMcpServers`. Permission rules evaluate in order `deny → ask → allow`; first match wins. Add `"$schema": "https://json.schemastore.org/claude-code-settings.json"` for editor validation. Run `/status` to see loaded sources and `claude doctor` for rejected entries.

Precedence (highest first): managed → `--settings` → `.claude/settings.local.json` → `.claude/settings.json` → `~/.claude/settings.json`. List keys such as `permissions.allow` merge across files.

- **`fallbackModel`** — model to use when the primary `model` is unavailable or rate-limited.
- **`requiredMinimumVersion`** — semver string; Claude Code refuses to run if the installed version is older.
- **`enforceAvailableModels`** — boolean; when `true`, rejects model IDs not available in the current account/tier at startup rather than failing at runtime.
- **`permissions.block{Reads,Writes}OutsideWorkingDirectories`** — `true` makes file tools refuse paths outside the working directories in every permission mode.
- **`permissions.denyInsteadOfPrompting`** — a call that would wait on a permission prompt is denied and the turn continues (unattended runs). **`deniedMcpServers`** blocks MCP servers by name or URL.

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI environments or troubleshooting a broken config.

## Hooks

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` | Load context or env vars on session open | Inject current git branch |
| `InstructionsLoaded` | React when a `CLAUDE.md` or `.claude/rules/*.md` file loads | Log which rules were loaded |
| `UserPromptSubmit` / `UserPromptExpansion` | Validate or enrich a prompt; gate a command expansion | Block secret patterns |
| `PreToolUse` | Block or gate a tool call | Deny `Bash(rm -rf *)` |
| `PermissionRequest` / `PermissionDenied` | Decide or react to a permission outcome | Auto-answer known-safe requests |
| `PostToolUse` / `PostToolUseFailure` | Lint or log after a tool succeeds or fails | Auto-run `eslint --fix` after `Edit` |
| `PostToolBatch` | React after a parallel tool batch resolves | Summarize a batch of file reads |
| `SubagentStart` / `SubagentStop` | Track subagent lifecycle | Log delegated work |
| `ConfigChange` / `CwdChanged` / `FileChanged` | React to config, directory, or watched-file changes | Reload env on `cd` |
| `MessageDisplay` | Intercept or annotate a message before it is shown | Inject a reminder banner |
| `PreCompact` / `PostCompact` | Save state before, re-inject after compaction | Reload pinned snippets |
| `WorktreeCreate` / `WorktreeRemove` | Set up or clean up a worktree | `npm ci` in the new branch |
| `Stop` / `StopFailure` | Cleanup when a turn finishes or ends on an API error | Persist session notes |
| `SessionEnd` | Release resources or save artifacts | Flush metrics |

Also available: `PreModelSwitch`/`PostModelSwitch`, `Elicitation`/`ElicitationResult`, `TaskCreated`/`TaskCompleted`, `Setup`, `Notification`, `TeammateIdle`, `DirectoryAdded`. Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, command }` entries. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- `/reload-skills` — hot-reload skill/command files without restarting the session.
- `/cd <path>` changes the session's working directory; `/plugin` manages plugins, `/reload-plugins` picks up local edits.
- `/doctor` (setup checkup; `/doctor prompt-audit`) and `/skill-doctor` (unused skills and their context cost).
- Bundled skills: `/code-review`, `/batch`, `/debug`, `/loop`, `/simplify`, `/run`, `/verify`, `/claude-api`. Disable via `disableBundledSkills` or `skillOverrides` set to `"off"`.
- CLI: `claude plugin init` scaffolds a plugin; `claude agents` lists named subagents.

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `description` / `when_to_use` | What the skill does and trigger phrases; combined text is truncated at 1,536 chars in the listing |
| `argument-hint` / `arguments` | Autocomplete hint (e.g. `[branch]`); named positional args for `$name` substitution |
| `allowed-tools` / `disallowed-tools` | Tools usable without prompting / removed while the skill is active |
| `model` | Override model for the turn (aliases: `fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low` / `medium` / `high` / `xhigh` / `max` — effort level for the turn |
| `context: fork` + `agent` | Run the skill in a forked subagent; `agent` picks the type (e.g. `Explore`) |
| `paths` | Glob list — auto-load this skill only for matching files |
| `hooks` / `shell` | Hooks registered on invocation; `bash` (default) or `powershell` for `` !`cmd` `` injection |
| `disable-model-invocation` | `true` — only the user can invoke; Claude will not auto-load it |
| `user-invocable` | `false` — hidden from the `/` menu; only Claude invokes it |

Unrecognized fields are silently ignored.

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`, `displayName`, `defaultEnabled`, `dependencies`.
  - `displayName` — human-readable name shown in the marketplace and `/plugin list`.
  - `defaultEnabled` — boolean; whether the plugin activates on install without user opt-in.
  - `dependencies` — list of other plugin names that must be installed for this plugin to function.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `settings.json`. A plugin with a JavaScript hooks module is a "mod".
- Every enabled plugin's skill/agent names and descriptions sit in context each turn; check cost in `/plugin` and disable unused ones.
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
- Do not maintain duplicate `AGENTS.md` and `CLAUDE.md` content — keep one source and import it with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md` so supporting files and frontmatter are available.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
