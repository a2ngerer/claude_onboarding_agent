---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-08-04
sources:
  - https://docs.claude.com/en/docs/claude-code/hooks
  - https://docs.claude.com/en/docs/claude-code/settings
  - https://docs.claude.com/en/docs/claude-code/plugins
  - https://docs.claude.com/en/docs/claude-code/slash-commands
  - https://docs.claude.com/en/docs/claude-code/memory
version: 3
---

## Memory files

- `CLAUDE.md` — project instructions at `./CLAUDE.md` or `./.claude/CLAUDE.md`; user-level at `~/.claude/CLAUDE.md`; org-wide managed policy files also exist (e.g. `/etc/claude-code/CLAUDE.md` on Linux). Loaded into every session.
- `CLAUDE.local.md` — personal project notes; gitignored, appended after `CLAUDE.md`.
- `AGENTS.md` — not read natively by Claude Code. If the repo needs both, `CLAUDE.md` imports it with `@AGENTS.md`.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth **4** hops, not 5).
- **Auto memory** (separate from CLAUDE.md): Claude writes its own notes to `~/.claude/projects/<project>/memory/MEMORY.md` plus topic files, on by default. Only the first 200 lines / 25KB of `MEMORY.md` load per session; this plugin's own memory system (see this repo's guidance above) follows the same pattern.

## Settings

Top-level keys in `.claude/settings.json` include: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `enforceAvailableModels`, plus many more (UI, auto-mode, credentials). Permission rules evaluate `deny → ask → allow` (first match wins) and merge across scopes rather than override.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — chain of fallback models when the primary is unavailable or rate-limited, capped at 3 models.
- **`requiredMinimumVersion`** / **`requiredMaximumVersion`** — semver bounds on the Claude Code version; **managed-settings only**, not settable at project/user scope.
- **`enforceAvailableModels`** — boolean; when `true`, rejects model IDs not available in the current account/tier at startup rather than failing at runtime.
- Settings precedence (highest first): Managed → CLI flags → Local (`settings.local.json`) → Project (`settings.json`) → User (`~/.claude/settings.json`).

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI environments or troubleshooting a broken config.

## Hooks

Claude Code supports a much larger hook-event surface than session/tool lifecycle alone — session (`SessionStart`, `Setup`, `SessionEnd`), per-turn (`UserPromptSubmit`, `UserPromptExpansion`, `Stop`, `StopFailure`), tool execution (`PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PostToolBatch`, `PermissionRequest`, `PermissionDenied`), agent/task (`SubagentStart`, `SubagentStop`, `TaskCreated`, `TaskCompleted`, `TeammateIdle`), file/config (`FileChanged`, `CwdChanged`, `DirectoryAdded`, `InstructionsLoaded`, `ConfigChange`), compaction (`PreCompact`, `PostCompact`), worktrees (`WorktreeCreate`, `WorktreeRemove`), and MCP/display (`Elicitation`, `ElicitationResult`, `Notification`, `MessageDisplay`). Run `/hooks` in-session for the authoritative, versioned list.

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` | Load context or env vars on session open | Inject current git branch |
| `InstructionsLoaded` | React to what triggered loading (new session, plugin install); inspect `load_reason` | Log which skills were loaded |
| `PreToolUse` | Block or gate a tool call | Deny `Bash(rm -rf *)` |
| `PostToolUse` | Lint or log after a tool runs | Auto-run `eslint --fix` after `Edit` |
| `Notification` | React to background-agent state (`agent_needs_input`, `agent_completed`) | Ping a channel when a background agent needs input |
| `DirectoryAdded` | Fires after `/add-dir` adds a working directory | Load extra context for the new dir |
| `Stop` | Cleanup when Claude finishes a turn | Persist session notes |
| `SessionEnd` | Release resources or save artifacts | Flush metrics |

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of handler entries. Handler `type` is one of `command`, `http`, `mcp_tool`, `prompt`, or `agent` (not just shell commands). Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work; if a skill and a command share a name, the skill wins.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), or `$<name>` for named positional args declared in the `arguments:` frontmatter list (names map to argument positions in order).
- Name slugs: lowercase letters, digits, hyphens only.
- Live change detection auto-reloads edited `SKILL.md` text within a session; plugin-bundled `hooks/`, `.mcp.json`, `agents/`, and `output-styles/` still need `/reload-plugins`.
- `/cd <path>` — change the working directory for the current session, preserving prompt cache.
- `/plugin` — interactive plugin manager (install/enable/disable/list); `claude plugin list` is the CLI equivalent.
- `claude plugin init <name>` — scaffold a new plugin at `~/.claude/skills/<name>/` (not the current directory), auto-loaded next session.
- `claude agents` — open agent view to monitor and dispatch parallel **background** sessions; it is not a subagent-listing command.

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `description` | What the skill does and when to use it; Claude uses this to decide when to auto-load it |
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `arguments` | Named positional arguments for `$name` substitution |
| `allowed-tools` / `disallowed-tools` | Tool allow/deny list scoped to this skill's invocation |
| `model` | Override model for this skill (accepts aliases: `fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low` / `medium` / `high` / `xhigh` / `max` — thinking-budget hint |
| `context: fork` | Run the skill in a forked subagent context (background by default; `background: false` to wait) |
| `agent` | Which subagent type to use when `context: fork` is set |
| `paths` | Glob list — load this skill only when CWD matches |
| `disable-model-invocation` | `true` — skill runs its command without Claude auto-triggering it |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; only callable programmatically |
| `hooks` | Hooks scoped to this skill's own lifecycle |

## Plugins

- Manifest: `.claude-plugin/plugin.json`; only `name` is required. Common fields: `version`, `description`, `author`, `homepage`, `repository`, `license`, `keywords`, `displayName`, `defaultEnabled`, `dependencies` (strings or `{name, version}` objects). Unrecognized fields are ignored, not errors.
  - `displayName` — human-readable name shown in the `/plugin` picker.
  - `defaultEnabled` — boolean (default `true`); ships a plugin disabled until the user opts in.
  - `dependencies` — other plugins that must be installed/active for this plugin to function.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `settings.json`, `bin/`.
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits (hooks, MCP/LSP servers, agents); plain `SKILL.md` text edits apply live without it.

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
