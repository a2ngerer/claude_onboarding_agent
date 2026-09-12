---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-09-12
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
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 4 hops).
- **Auto memory:** Claude also writes its own notes to `~/.claude/projects/<project>/memory/` (types: `user`, `feedback`, `project`, `reference`), indexed by `MEMORY.md` (first 200 lines / 25KB loaded every session). Toggle with `autoMemoryEnabled`; relocate with `autoMemoryDirectory`.

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `enforceAvailableModels`, `maxEffortLevel`, `skillOverrides`, `autoMemoryEnabled`, `autoMemoryDirectory`, `timeFormat`, `timeZone`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — model to use when the primary `model` is unavailable or rate-limited.
- **`requiredMinimumVersion`** — semver string; Claude Code refuses to run if the installed version is older.
- **`enforceAvailableModels`** — boolean; when `true`, rejects model IDs not available in the current account/tier at startup rather than failing at runtime.
- **`maxEffortLevel`** — caps the effort level allowed on every provider; the lowest cap from any scope (including `--settings`) applies, even under a higher managed cap.
- **`managedMcpServers`** — managed-settings-only; organization-provisioned MCP servers, ranked above user-configured servers.
- **`skillOverrides`** — per-skill visibility (`on` / `name-only` / `user-invocable-only` / `off`) without editing the skill file.

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI environments or troubleshooting a broken config.

## Hooks

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` / `SessionEnd` | Load or release context at session boundaries | Inject current git branch |
| `InstructionsLoaded` | React to what triggered loading (new session, `/reload-skills`, plugin install) | Log which skills were loaded |
| `UserPromptSubmit` / `UserPromptExpansion` | Validate/enrich a prompt, or react to a slash-command expanding into one | Block secret patterns |
| `PreToolUse` / `PostToolUse` / `PostToolUseFailure` | Gate, lint, or log around a tool call | Deny `Bash(rm -rf *)` |
| `PostToolBatch` | React after a full parallel tool batch resolves | Summarize a batch of file reads |
| `PermissionRequest` / `PermissionDenied` | React to a permission decision, or an auto-mode denial | Log denied actions |
| `SubagentStart` / `SubagentStop` | React to subagent lifecycle | Track subagent spend |
| `PreModelSwitch` / `PostModelSwitch` | Block, confirm, or annotate a model switch | Warn before switching to a costlier model |
| `PreCompact` / `PostCompact` | Save state before compaction / re-inject after | Checkpoint session notes |
| `WorktreeCreate` / `WorktreeRemove` | Set up or clean up a worktree | `npm ci` in the new branch |
| `Stop` / `StopFailure` | Cleanup when a turn ends normally or via API error | Persist session notes |
| `MessageDisplay` / `Notification` / `Elicitation` | Annotate a displayed message, notification, or MCP input request | Inject a reminder banner |

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of handler entries. Plugins ship hooks in `hooks/hooks.json`. Handler `type`: `command` (shell, JSON on stdin), `http`, `mcp_tool`, `prompt`, or `agent` (spawn a subagent for verification).

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… (positional), named args via `arguments:` frontmatter; built-ins like `${CLAUDE_SESSION_ID}`, `${CLAUDE_SKILL_DIR}`, `${CLAUDE_PROJECT_DIR}` are also available.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- `/reload-skills` — hot-reload skill/command files without restarting the session.
- `/reload-plugins` — reload plugins, skills, agents, and hooks after edits; now also works in headless sessions.
- `/skill-doctor` — show which loaded skills go unused and their context cost.
- `/focus` — narrow the view to just your prompt, a one-line work summary, and the response.
- `/output-style [name]` — list and switch output styles.
- `/cd <path>` — change the working directory for the current session.
- `/plugin list` — list installed plugins and their status.
- `claude plugin init <name>` — scaffold a skills-directory plugin at `~/.claude/skills/<name>/` that auto-loads next session (no marketplace or install step).
- `claude agents` — list all available named subagents (CLI).

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `allowed-tools` | Comma-separated tool whitelist for this skill's invocation |
| `disallowed-tools` | Tools removed from Claude's pool while this skill is active |
| `model` | Override model for this skill (accepts aliases: `fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low` / `medium` / `high` / `xhigh` / `max` — hint to the model's thinking budget |
| `context: fork` | Run the skill in a forked context (isolated subagent); pair with `agent:` to pick the subagent type |
| `background` | With `context: fork`, set `false` to wait for the result instead of running in the background (default `true`) |
| `paths` | Glob list — load this skill only when CWD matches |
| `disable-model-invocation` | `true` — skill runs its command without calling the model (pure automation) |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; only callable programmatically |

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`, `displayName` (shown in the marketplace and `/plugin list`), `defaultEnabled` (activates on install without opt-in), `dependencies` (other required plugin names).
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/` (legacy flat files), `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/` (executables added to the Bash tool's `PATH`), `settings.json` (default `agent` / `subagentStatusLine`).
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits, including in headless sessions.

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
