---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-07-18
sources:
  - https://docs.claude.com/en/docs/claude-code/hooks
  - https://docs.claude.com/en/docs/claude-code/settings
  - https://docs.claude.com/en/docs/claude-code/plugins
  - https://docs.claude.com/en/docs/claude-code/slash-commands
  - https://docs.claude.com/en/docs/claude-code/memory
version: 3
---

## Memory files

Two systems combine at session start: **CLAUDE.md** (you write it) and **auto memory** (Claude writes it).

- `CLAUDE.md` — project instructions at `./CLAUDE.md` or `./.claude/CLAUDE.md`; user-level at `~/.claude/CLAUDE.md`. Loaded into every session in full, regardless of length.
- `CLAUDE.local.md` — personal project notes; gitignored, appended after `CLAUDE.md`.
- `AGENTS.md` — not read natively by Claude Code. If the repo needs both, `CLAUDE.md` imports it with `@AGENTS.md`.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 4).
- **Auto memory** — Claude saves its own notes (build commands, debugging insights, preferences it discovers) to `~/.claude/projects/<project>/memory/MEMORY.md` plus topic files. Only the first 200 lines / 25KB of `MEMORY.md` load per session; topic files load on demand. Toggle with `autoMemoryEnabled` (settings) or `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` (env). Browse/edit via `/memory`. Relocate with `autoMemoryDirectory`.

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `requiredMaximumVersion`, `enforceAvailableModels`, `autoMemoryEnabled`, `autoMemoryDirectory`, `disableBundledSkills`, `claudeMd`. Permission rules evaluate in order `deny → ask → allow`; first match wins. **Note:** `mcpServers` is not a settings.json key — MCP servers are configured per scope in `.mcp.json` (project) or `~/.claude.json` (user/local).

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — model to use when the primary `model` is unavailable or rate-limited.
- **`requiredMinimumVersion` / `requiredMaximumVersion`** — semver bounds; both fail open (an invalid value is stripped, never enforced), so a bad policy push can't block startup.
- **`enforceAvailableModels`** — boolean; when `true`, rejects model IDs not available in the current account/tier.
- **`claudeMd`** — put managed CLAUDE.md content directly in `managed-settings.json` instead of a separate file (managed/policy scope only).

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers.

## Hooks

29 documented events now exist. Key ones:

| Event | Typical use |
|---|---|
| `SessionStart` / `SessionEnd` | Load/release context on session open/close |
| `Setup` | Fires under `--init-only` or maintenance mode |
| `UserPromptSubmit` | Validate or enrich the user prompt |
| `PreToolUse` / `PostToolUse` / `PostToolUseFailure` | Gate, lint, or log around a tool call |
| `PermissionRequest` / `PermissionDenied` | React to permission dialogs / auto-mode denials |
| `SubagentStart` / `SubagentStop` | React to subagent lifecycle |
| `TaskCreated` / `TaskCompleted` | React to task tracker events |
| `FileChanged` | A watched file changes on disk |
| `PreCompact` / `PostCompact` | Save/reload state around compaction |
| `Stop` / `StopFailure` | Turn ends normally / via API error |
| `WorktreeCreate` / `WorktreeRemove` | Set up/tear down a worktree |
| `Elicitation` / `ElicitationResult` | An MCP server requests user input |

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of handlers. Handler `type` is one of `command`, `http`, `mcp_tool`, `prompt`, or `agent` (not just shell commands). Plugins ship hooks in `hooks/hooks.json`.

## Slash commands / Skills

- Custom commands and skills are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$ARGUMENTS[N]`/`$N` (positional), `$name` (named, via `arguments:` frontmatter).
- SKILL.md text changes are picked up live in-session — no reload command needed. `/reload-plugins` is only for plugin-only components (`hooks/`, `.mcp.json`, `agents/`, `output-styles/`).
- `/cd <path>` — change the working directory for the current session.
- `/config key=value` — set any setting from the prompt.
- `/plugin list` — list installed plugins and their status.
- `claude plugin init` — scaffold a new plugin (CLI, not a slash command).

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `when_to_use` | Extra trigger phrases appended to `description` (shares a 1,536-char cap) |
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `arguments` | Named positional args for `$name` substitution |
| `allowed-tools` / `disallowed-tools` | Grant or remove tools for the invoking turn only |
| `model` | Override model for this skill (`inherit` keeps the active model) |
| `effort` | `low`/`medium`/`high`/`xhigh`/`max` — thinking-budget hint |
| `context: fork` | Run in a forked subagent; pair with `agent:` to pick the subagent type |
| `hooks` | Hooks scoped to this skill's lifecycle |
| `paths` | Glob list — auto-load this skill only when CWD/file matches |
| `disable-model-invocation` | `true` — only user-invocable, never auto-loaded |
| `user-invocable` | `false` — hidden from `/` menu, Claude-only |

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`, `license`, `displayName`, `defaultEnabled`, `dependencies`.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/` (executables added to Bash `PATH`), `settings.json` (currently only `agent`/`subagentStatusLine` keys honored).
- A plugin folder with a `.claude-plugin/plugin.json` inside `~/.claude/skills/` or a project's `.claude/skills/` auto-loads as a "skills-directory plugin" (`<name>@skills-dir`) — no marketplace step needed.
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Let auto memory handle transient learnings; reserve `CLAUDE.md` for durable, team-shared instructions.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
- Pin plugin versions in team repos; run `/reload-plugins` after edits to plugin-only components (skill text reloads live).

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md` so supporting files and frontmatter are available.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
- Do not tell users to run `/reload-skills` — it is no longer documented; SKILL.md edits apply live.
