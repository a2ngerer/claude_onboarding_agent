---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-10-29
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
- `AGENTS.md` — read as project instructions only when no `CLAUDE.md`/`CLAUDE.local.md` exists in the working directory or above (v2.1.277+). If both exist, only `CLAUDE.md` is read; to share one file with other tools, `CLAUDE.md` imports it with `@AGENTS.md`.
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
- **`enforceAvailableModels`** — boolean; when `true`, rejects model IDs not available in the current account/tier at startup rather than failing at runtime.

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI environments or troubleshooting a broken config.

## Hooks

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` | Load context or env vars on session open | Inject current git branch |
| `InstructionsLoaded` | React when a CLAUDE.md or `.claude/rules/*.md` file loads; inspect `load_reason` | Log which rules were loaded |
| `UserPromptSubmit` | Validate or enrich the user prompt (runs before a skill/command expands) | Block secret patterns |
| `UserPromptExpansion` | Run when a typed command expands into a prompt; can block it | Gate expensive commands |
| `PreToolUse` | Block or gate a tool call | Deny `Bash(rm -rf *)` |
| `PermissionRequest` / `PermissionDenied` | Decide or react to permission outcomes (incl. auto-mode denials) | Auto-approve a safe command |
| `PostToolUse` / `PostToolUseFailure` | Lint or log after a tool succeeds / fails | Auto-run `eslint --fix` after `Edit` |
| `PostToolBatch` | React after a full parallel tool batch completes | Summarize a batch of file reads |
| `SubagentStart` / `SubagentStop` | Track subagent lifecycle | Log subagent results |
| `PreCompact` / `PostCompact` | Save state before / re-inject context after compaction | Checkpoint session notes |
| `ConfigChange` / `CwdChanged` / `DirectoryAdded` / `FileChanged` | React to config, directory, or watched-file changes | Reload env on `cd` |
| `PreModelSwitch` / `PostModelSwitch` | Gate or react to model changes | Block switching to a costly model |
| `WorktreeCreate` / `WorktreeRemove` | Set up / clean up a worktree | `npm ci` in the new branch |
| `Stop` / `StopFailure` | Cleanup when Claude finishes a turn / a turn ends on an API error | Persist session notes |
| `SessionEnd` | Release resources or save artifacts | Flush metrics |

Other events: `Setup`, `Notification`, `TaskCreated`/`TaskCompleted`, `MessageDisplay`, `Elicitation`/`ElicitationResult`, `TeammateIdle`. Prompt/agent hooks are capped at 12 concurrent per event; `updatedInput` from `PreToolUse`/`PermissionRequest` hooks is validated like Claude's own tool input.

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, command }` entries. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- `/reload-skills` — hot-reload skill/command files without restarting the session (sends only new or changed skills).
- `/skill-doctor` — shows each skill's context cost and usage so unused ones can be turned off.
- `/cd <path>` — change the working directory for the current session.
- `/plugin list` — list installed plugins and their status.
- `claude plugin init` — scaffold a new plugin in the current directory (CLI, not a slash command).
- `claude agents` — list all available named subagents (CLI).

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `description` / `when_to_use` | What the skill does and trigger phrases; combined text is truncated at 1,536 chars, so lead with the key use case |
| `argument-hint` / `arguments` | Autocomplete placeholder (e.g. `[branch]`) / named positional arguments |
| `allowed-tools` | Tools usable without prompting while the skill runs |
| `disallowed-tools` | Tools removed from the pool while the skill is active |
| `model` | Override model for the rest of the turn (aliases: `fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low` to `max` — effort level while the skill is active |
| `context: fork` | Run the skill in a forked subagent context; `agent` picks the subagent type, `background: false` waits for the result |
| `hooks` / `shell` | Hooks registered when the skill is invoked / `bash` (default) or `powershell` for `` !`command` `` injection |
| `paths` | Glob list — limits when Claude loads the skill automatically |
| `disable-model-invocation` | `true` — Claude never auto-loads the skill; use for side-effect workflows like deploys |
| `user-invocable` | `false` — hides the skill from the `/` menu; only Claude can invoke it |

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`, `displayName` (shown in marketplace and `/plugin list`), `defaultEnabled` (activate on install without opt-in), `dependencies` (other plugins required).
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `settings.json`. A plugin with a JavaScript hooks module (hooks as functions that can draw panes and add commands) is called a mod.
- Enabled plugins keep skill/agent descriptions in context every turn; prune unused ones with `claude plugin disable`.
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
- Pin plugin versions in team repos and namespace plugin skills; run `/reload-plugins` after edits.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not expect `AGENTS.md` to load alongside an existing `CLAUDE.md` — Claude reads it only when no `CLAUDE.md` is present; import it with `@AGENTS.md` to share one file.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md` so supporting files and frontmatter are available.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
