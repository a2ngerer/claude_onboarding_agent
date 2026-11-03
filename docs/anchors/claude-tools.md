---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-11-03
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
- `AGENTS.md` — read as project instructions (v2.1.277+) only when no `CLAUDE.md` exists in or above the working directory; if a `CLAUDE.md` exists, only it loads. To use both, import with `@AGENTS.md`.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 5).

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `enforceAvailableModels`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — model to use when the primary `model` is unavailable or rate-limited.
- **`permissions.blockReadsOutsideWorkingDirectories` / `blockWritesOutsideWorkingDirectories`** — when `true` in any scope (even over managed), file tools cannot read/write outside the working directory (v2.1.257 / v2.1.314+).
- **`requiredMinimumVersion`** — semver string; Claude Code refuses to run if the installed version is older.
- **`enforceAvailableModels`** — boolean; when `true`, rejects model IDs not available in the current account/tier at startup rather than failing at runtime.

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI environments or troubleshooting a broken config.

## Hooks

| Event | Typical use |
|---|---|
| `SessionStart` / `Setup` / `SessionEnd` | Load context on open; init/maintenance runs; release resources on close |
| `UserPromptSubmit` / `UserPromptExpansion` | Validate or enrich a prompt; block a command expansion |
| `PreToolUse` / `PermissionRequest` / `PermissionDenied` | Gate a tool call (e.g. deny `Bash(rm -rf *)`); decide permissions; react to auto-mode denials |
| `PostToolUse` / `PostToolUseFailure` / `PostToolBatch` | Lint or log after a tool succeeds, fails, or a parallel batch resolves |
| `SubagentStart` / `SubagentStop` / `TaskCreated` / `TaskCompleted` | Track subagent and task lifecycle |
| `Stop` / `StopFailure` / `Notification` / `MessageDisplay` | Cleanup after a turn; handle API-error turn ends; annotate messages |
| `InstructionsLoaded` / `ConfigChange` / `CwdChanged` / `DirectoryAdded` / `FileChanged` | React to instruction loads, config edits, `cd`, `/add-dir`, watched files |
| `PreCompact` / `PostCompact` | Checkpoint before, re-inject after context compaction |
| `PreModelSwitch` / `PostModelSwitch` | Block or observe model changes |
| `WorktreeCreate` / `WorktreeRemove` | Set up or clean up worktrees |
| `Elicitation` / `ElicitationResult` | Handle MCP server requests for user input |

Handler `type`: `command`, `http`, `mcp_tool`, `prompt` (single-turn LLM check), `agent` (experimental). Optional `if` takes one permission rule (e.g. `"Bash(git *)"`) and applies only on tool events. `onFailure: "block"` (`command`/`http`, v2.1.295+) makes a failed or timed-out hook block the action instead of continuing.

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, command }` entries. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- `/reload-skills` — hot-reload newly created skill directories without restarting; `/skill-doctor` reports unused skills and their context cost.
- `/doctor prompt-audit` — audit CLAUDE.md, AGENTS.md, rules, skills, and subagents (v2.1.283+).
- `/cd <path>` — change the working directory for the current session.
- `/plugin list` — list installed plugins and their status.
- `claude plugin init` — scaffold a new plugin in the current directory (CLI, not a slash command).
- `claude agents` — list all available named subagents (CLI).

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `name` / `description` / `when_to_use` | Command name (defaults to dir name); what/when; extra trigger phrases (combined text truncated at 1,536 chars) |
| `argument-hint` / `arguments` | Autocomplete hint (e.g. `[branch]`); named positional args for `$name` substitution |
| `allowed-tools` / `disallowed-tools` | Tools granted without prompting for the turn / removed while the skill is active |
| `model` / `effort` | Model override (aliases or `inherit`); `low`, `medium`, `high`, `xhigh`, or `max` |
| `context: fork` + `agent` | Run in a forked subagent (e.g. `agent: Explore`); `background: false` waits for the result |
| `paths` | Glob list — limit automatic activation to matching files |
| `hooks` / `shell` | Hooks registered on invocation; `bash` (default) or `powershell` for `` !`cmd` `` injections |
| `disable-model-invocation` | `true` — only the user can invoke; Claude does not auto-load it |
| `user-invocable` | `false` — hidden from the `/` menu; only Claude can invoke |

Unrecognized fields are silently ignored.

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
- Pin plugin versions in team repos; run `/reload-plugins` after edits instead of restarting.
- Namespace plugin skills; never rely on a collision-prone flat name.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` loading when a `CLAUDE.md` also exists — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md` so supporting files and frontmatter are available.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
