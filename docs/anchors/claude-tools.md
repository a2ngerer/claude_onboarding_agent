---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-11-16
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
- `AGENTS.md` — read natively (v2.1.277+) only when no `CLAUDE.md`/`CLAUDE.local.md` exists in or above the working directory; otherwise `CLAUDE.md` wins. To use both, have `CLAUDE.md` import it with `@AGENTS.md`.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 5).

## Settings

Files: `~/.claude/settings.json` (user), `.claude/settings.json` (shared), `.claude/settings.local.json` (personal, untracked). Precedence: managed > `--settings` > local > shared > user; list keys like `permissions.allow` merge. Top-level keys include `permissions`, `env`, `hooks`, `model`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `availableModels`, `requiredMinimumVersion`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — model used when the primary is unavailable; **`requiredMinimumVersion`** — semver floor for Claude Code.
- **`availableModels` / `deniedModels`** — allow/deny lists for model selection; a managed `availableModels` list is applied as-is.
- **`permissions.denyInsteadOfPrompting`** — a call that would wait on a permission prompt is denied and the turn continues (v2.1.319+).
- **`permissions.blockWritesOutsideWorkingDirectories`** — Write/Edit/NotebookEdit refuse paths outside working directories (v2.1.314+).
- **`sandbox.autoAllowBashIfSandboxed`** — run sandboxed Bash without prompts (v2.1.325+).

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI environments or troubleshooting a broken config.

## Hooks

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` | Load context or env vars on session open | Inject current git branch |
| `Setup` | Run on `--init-only`, or `--init` / `--maintenance` in `-p` mode | Bootstrap a CI checkout |
| `InstructionsLoaded` | React to a CLAUDE.md or `.claude/rules/*.md` file loading; inspect `load_reason` | Log which rules were loaded |
| `UserPromptSubmit` | Validate or enrich the user prompt | Block secret patterns |
| `PreToolUse` | Block or gate a tool call | Deny `Bash(rm -rf *)` |
| `PostToolUse` | Lint or log after a tool runs | Auto-run `eslint --fix` after `Edit` |
| `PostToolUseFailure` | React when a tool call fails | Log failures |
| `PermissionRequest` / `PermissionDenied` | Decide or audit permission outcomes; `PermissionDenied` can set `retry: true` | Auto-approve a safe command |
| `PostToolBatch` | React after a full parallel tool batch completes | Summarize a batch of file reads |
| `SubagentStart` / `SubagentStop` | Track subagent lifecycle | Log subagent runs |
| `ConfigChange` / `CwdChanged` / `FileChanged` | React to settings edits, `cd`, or watched-file changes | Reload env on `.envrc` change |
| `PreModelSwitch` / `PostModelSwitch` | Gate or log model changes | Block switching to a costly model |
| `Elicitation` / `ElicitationResult` | Intercept MCP requests for user input | Auto-answer a known form |
| `MessageDisplay` | Intercept or annotate a message before it is shown | Inject a reminder banner |
| `PreCompact` | Save state before context compaction | Checkpoint session notes |
| `PostCompact` | Re-inject context after compaction | Reload pinned snippets |
| `WorktreeCreate` | Set up a fresh worktree (install deps, copy env) | `npm ci` in the new branch |
| `WorktreeRemove` | Clean up after a worktree is deleted | Remove temp build artifacts |
| `Stop` | Cleanup when Claude finishes a turn | Persist session notes |
| `SessionEnd` | Release resources or save artifacts | Flush metrics |

The page documents 33 events in total; the table lists the common ones. Also available: `UserPromptExpansion`, `Notification`, `TaskCreated`, `TaskCompleted`, `StopFailure`, `TeammateIdle`, `DirectoryAdded`. Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, command }` entries. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- `/reload-skills` — hot-reload skill/command files without restarting the session.
- `/cd <path>` — change the working directory for the current session.
- Bundled skills: `/doctor` (`/doctor prompt-audit` audits instructions), `/run`, `/verify`, `/claude-api`, `/skill-doctor` (unused skills and context cost).
- `claude plugin init` — scaffold a new plugin in the current directory (CLI, not a slash command).

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `allowed-tools` | Comma-separated tool whitelist for this skill's invocation |
| `model` | Override model for this skill (accepts aliases: `fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low` / `medium` / `high` / `xhigh` / `max` — effort level for the turn |
| `context: fork` | Run the skill in a subagent (isolated from main conversation); pair with `agent:` to pick the subagent type |
| `when_to_use` | Extra trigger phrases appended to `description` (combined text truncated at 1,536 chars) |
| `disallowed-tools` | Tools removed from the pool while the skill is active |
| `paths` | Glob list — load this skill only when CWD matches |
| `disable-model-invocation` | `true` — Claude never loads the skill on its own; use for side-effect workflows like `/deploy` |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; only callable programmatically |

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`, `displayName`, `defaultEnabled`, `dependencies`, `engines`.
  - `displayName` — human-readable name shown in the marketplace and `/plugin list`.
  - `defaultEnabled` — boolean; whether the plugin activates on install without user opt-in.
  - `dependencies` — list of other plugin names that must be installed for this plugin to function.
  - `engines["claude-code"]` — version range; plugins outside it are not installed, updated, or loaded (v2.1.323+).
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `settings.json`.
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not assume `AGENTS.md` loads alongside `CLAUDE.md` — it is read by default only when no `CLAUDE.md` exists; import it with `@AGENTS.md` to use both.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md` so supporting files and frontmatter are available.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
