---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-07-07
sources:
  - https://docs.claude.com/en/docs/claude-code/hooks
  - https://docs.claude.com/en/docs/claude-code/settings
  - https://docs.claude.com/en/docs/claude-code/plugins
  - https://docs.claude.com/en/docs/claude-code/slash-commands
  - https://docs.claude.com/en/docs/claude-code/memory
version: 3
---

## Memory files

- `CLAUDE.md` — project instructions at `./CLAUDE.md` or `./.claude/CLAUDE.md`; user-level at `~/.claude/CLAUDE.md`; org-wide managed policy file (e.g. `/etc/claude-code/CLAUDE.md`). All loaded into every session, concatenated root-to-leaf.
- `CLAUDE.local.md` — personal project notes; gitignored, appended after `CLAUDE.md`.
- `AGENTS.md` — not read natively by Claude Code. If the repo needs both, `CLAUDE.md` imports it with `@AGENTS.md` (or a symlink on non-Windows).
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` (also `~/.claude/rules/` user-level) with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally. Supports symlinks.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 4 hops).
- **Auto memory** — Claude writes its own notes to `~/.claude/projects/<project>/memory/MEMORY.md` (+ topic files) as it works; the first 200 lines/25KB of `MEMORY.md` load every session. Toggle with `autoMemoryEnabled`. Distinct from CLAUDE.md, which only you write.

## Settings

Top-level keys in `.claude/settings.json` include: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `requiredMaximumVersion`, `enforceAvailableModels`, `autoMemoryEnabled`, `autoMemoryDirectory`, `disableBundledSkills`, `skillOverrides`, `attribution`. Permission rules combine across scopes; `deny` beats `ask` beats `allow` (most-restrictive match wins, not array order).

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — ordered fallback model(s) to use when the primary `model` is unavailable or rate-limited.
- **`requiredMinimumVersion` / `requiredMaximumVersion`** — semver floor/ceiling; Claude Code refuses to run outside the range.
- **`enforceAvailableModels`** — boolean; when `true`, rejects model IDs not available in the current account/tier at startup rather than failing at runtime.
- **`sandbox`** — container isolation; `sandbox.credentials.{files,envVars}` exposes specific secrets into the sandbox, `sandbox.allowAppleEvents` opts into AppleScript on macOS.

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI environments or troubleshooting a broken config.

## Hooks

Grouped by lifecycle phase — `.claude/settings.json` supports far more events than the handful most setups use:

- **Session** — `SessionStart`, `Setup` (`--init`/`--maintenance` one-time prep), `SessionEnd`
- **Turn** — `UserPromptSubmit`, `UserPromptExpansion`, `Stop`, `StopFailure`
- **Tool execution** — `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PostToolBatch`, `PermissionRequest`, `PermissionDenied`
- **Subagents** — `SubagentStart`, `SubagentStop`, `TeammateIdle`
- **Tasks** — `TaskCreated`, `TaskCompleted`
- **Files/config** — `FileChanged`, `CwdChanged`, `InstructionsLoaded` (inspect `load_reason`), `ConfigChange`
- **Context/display** — `PreCompact`, `PostCompact`, `MessageDisplay`, `Notification`
- **Worktrees** — `WorktreeCreate`, `WorktreeRemove`
- **MCP** — `Elicitation`, `ElicitationResult`

Hooks live under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, command }` entries (`type`: `command`, `http`, `mcp_tool`, `prompt`, or `agent`). Plugins ship hooks in `hooks/hooks.json`; skills/agents can scope hooks in their own frontmatter `hooks:` block.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions. Nested monorepo skills use a directory-qualified name, e.g. `/apps/web:deploy`.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter, plus `${CLAUDE_SESSION_ID}`, `${CLAUDE_EFFORT}`, `${CLAUDE_SKILL_DIR}`, `${CLAUDE_PROJECT_DIR}` substitutions.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- `/reload-skills` — hot-reload skill/command files without restarting the session.
- `/cd <path>` — change the working directory for the current session.
- `/config key=value` — set a configuration value directly from the prompt.
- `/plugin list` — list installed plugins and their status.
- `claude plugin init` — scaffold a new plugin (in `~/.claude/skills/` by default so it auto-loads).
- `claude agents` — list all available named subagents (CLI).

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `arguments` | Named positional arguments (space-separated string or YAML list) for `$name` substitution |
| `allowed-tools` | Tools Claude can use without asking while this skill is active |
| `disallowed-tools` | Tools removed from Claude's pool while this skill is active (clears next message) |
| `model` | Override model for this skill (accepts aliases: `fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low` / `medium` / `high` / `xhigh` / `max` — hint to the model's thinking budget |
| `context: fork` | Run the skill in a forked subagent context (isolated from main conversation) |
| `agent` | Which subagent type to use when `context: fork` is set (default `general-purpose`) |
| `paths` | Glob list — load this skill only when CWD/file matches |
| `disable-model-invocation` | `true` — only a human can invoke via `/name`; hides description from Claude |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; only callable by Claude |
| `hooks` | Hooks scoped to this skill's lifecycle only |

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`, `displayName`, `defaultEnabled`, `dependencies`.
  - `displayName` — human-readable name shown in the marketplace and `/plugin list`.
  - `defaultEnabled` — boolean; whether the plugin activates on install without user opt-in.
  - `dependencies` — list of other plugin names that must be installed for this plugin to function.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/` (added to Bash `PATH`), `settings.json` (only `agent`/`subagentStatusLine` keys supported there).
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
