---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-08-22
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
- **Auto memory:** Claude also writes its own notes to `~/.claude/projects/<project>/memory/` (a `MEMORY.md` index plus topic files), recording `user`/`feedback`/`project`/`reference` facts it isn't told to forget. Toggle with the `autoMemoryEnabled` setting or `/memory`.

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `enforceAvailableModels`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **Precedence (highest first):** Managed settings → command line (`--settings`) → project local (`.claude/settings.local.json`) → shared project (`.claude/settings.json`) → user (`~/.claude/settings.json`). List keys like `permissions.allow` merge across files instead of overriding.
- **`fallbackModel`** — model to use when the primary `model` is unavailable or rate-limited.
- **`requiredMinimumVersion`** — semver string; Claude Code refuses to run if the installed version is older.
- **`enforceAvailableModels`** — boolean; when `true`, rejects model IDs not available in the current account/tier at startup rather than failing at runtime.

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI environments or troubleshooting a broken config.

## Hooks

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` | Load context or env vars on session open | Inject current git branch |
| `InstructionsLoaded` | React to what triggered loading (new session, `/reload-skills`, plugin install) | Log which skills were loaded |
| `UserPromptSubmit` | Validate or enrich the user prompt | Block secret patterns |
| `PreToolUse` / `PostToolUse` | Gate or lint around a tool call | Deny `Bash(rm -rf *)`; auto-run `eslint --fix` |
| `PostToolBatch` | React after a full parallel tool batch completes | Summarize a batch of file reads |
| `SubagentStart` / `SubagentStop` | React when a subagent spawns or finishes | Log subagent fan-out |
| `DirectoryAdded` | Fires when `/add-dir` or SDK `register_repo_root` adds a working directory | Load extra project context |
| `ConfigChange` | Fires when a settings file changes mid-session | Re-validate policy |
| `Elicitation` / `ElicitationResult` | An MCP server requests/receives user input | Audit MCP prompts |
| `PreCompact` / `PostCompact` | Save/restore state around context compaction | Checkpoint session notes |
| `WorktreeCreate` / `WorktreeRemove` | Set up or clean up a worktree | `npm ci` in the new branch |
| `Stop` / `SessionEnd` | Cleanup when a turn or session ends | Persist session notes; flush metrics |

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, command }` entries. Plugins ship hooks in `hooks/hooks.json`. This is a representative subset — Claude Code now defines 30+ hook events; consult `/hooks` in-session for the full list.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work; a skill of the same name takes precedence.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter (maps names to positions).
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- `/reload-skills`, `/reload-plugins` — hot-reload skill/plugin files without restarting the session.
- `/cd <path>` — change the working directory for the current session.
- `claude plugin init` — scaffold a new plugin (CLI, not a slash command); can also scaffold a skills-directory plugin auto-loaded from `~/.claude/skills/`.

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `argument-hint` / `arguments` | Autocomplete placeholder / named positional args for `$name` substitution |
| `allowed-tools` / `disallowed-tools` | Per-turn tool allow/deny list for this skill's invocation |
| `model` / `effort` | Override model (aliases or `inherit`) / thinking-budget hint for this skill |
| `context: fork` (+ `agent`, `background`) | Run the skill in a forked subagent; pick the agent type; foreground/background |
| `paths` | Glob list — auto-load this skill only when Claude works with matching files |
| `disable-model-invocation` / `user-invocable` | Restrict to manual-only / hide from `/` autocomplete |
| `hooks` | Lifecycle hooks registered while this skill is active |
| `metadata` / `license` / `compatibility` | Free-form data / license / environment requirements (Agent Skills spec fields) |

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `description`, `version` (semver), optional `author`, `homepage`, `repository`, `license`.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json` (LSP servers), `monitors/monitors.json` (background monitors), `bin/` (executables added to Bash's `PATH`), `settings.json` (default `agent`/`subagentStatusLine` only).
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits, including MCP/LSP servers.

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
