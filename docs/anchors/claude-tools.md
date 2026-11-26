---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-11-26
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

Claude Code supports 34 hook events. Commonly used ones:

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` / `Setup` | Load context on open; one-time prep with `--init-only` / `--init` | Inject current git branch |
| `UserPromptSubmit` / `UserPromptExpansion` | Validate prompts; block a command expansion | Block secret patterns |
| `PreSkillShellCommand` | Refuse a skill's injected inline shell command before it runs | Deny risky skill shell blocks |
| `PreToolUse` | Block or gate a tool call | Deny `Bash(rm -rf *)` |
| `PermissionRequest` / `PermissionDenied` | Decide permissions; `PermissionDenied` may set `retry: true` in auto mode | Auto-approve safe reads |
| `PostToolUse` / `PostToolUseFailure` | Lint or log after a tool succeeds / fails | `eslint --fix` after `Edit` |
| `PostToolBatch` | React after a parallel tool batch resolves | Summarize a batch of reads |
| `SubagentStart` / `SubagentStop` | Track subagent lifecycle | Log delegated work |
| `TaskCreated` / `TaskCompleted` | React to task-list changes | Notify on completion |
| `InstructionsLoaded` / `ConfigChange` / `FileChanged` / `CwdChanged` | Observe context and environment changes | Log loaded rules |
| `PreCompact` / `PostCompact` | Save / restore state around compaction | Checkpoint session notes |
| `PreModelSwitch` / `PostModelSwitch` | Gate or observe model changes | Block a switch to Fable |
| `Elicitation` / `ElicitationResult` | Intercept MCP user-input requests | Auto-answer known prompts |
| `WorktreeCreate` / `WorktreeRemove` | Set up / clean up worktrees | `npm ci` in the new branch |
| `Stop` / `StopFailure` / `SessionEnd` | Cleanup at turn end, API-error turn end, session end | Persist session notes |

Also: `Notification`, `MessageDisplay`, `TeammateIdle`, `DirectoryAdded`. Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, command }` entries; `command`, HTTP, and `mcp_tool` hooks accept `"onFailure": "block"` to refuse on error. Plugins ship hooks in `hooks/hooks.json` (event map wrapped in a top-level `"hooks"` key).

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
| `effort` | `low` / `normal` / `high` — hint to the model's thinking budget |
| `context: fork` | Run the skill in a forked context (isolated from main conversation) |
| `context: agent` | Run the skill as a full subagent turn |
| `paths` | Glob list — load this skill only when CWD matches |
| `disable-model-invocation` | `true` — skill runs its command without calling the model (pure automation) |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; only callable programmatically |

## Plugins

- Manifest: `.claude-plugin/plugin.json` (optional; `name` is the only required key) with `version`, `description`, `author`, `homepage`, `repository`, `license`, `keywords`, `displayName`, `defaultEnabled`, `dependencies`, `engines`, `userConfig`.
  - `displayName` — human-readable name shown in the marketplace and `/plugin list`.
  - `defaultEnabled` — boolean; whether the plugin activates on install without user opt-in.
  - `dependencies` — plugins that must be enabled; entries are `"name"`, `"name@marketplace"`, or `{name, marketplace, version}`. `optionalDependencies` marks plugins that install alongside but can be disabled independently.
  - `engines` — semver range under `claude-code` (e.g. `">=2.1.400"`); older Claude Code versions reject manifests containing it.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `workflows/`, `output-styles/`, `monitors/`, `settings.json`.
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
