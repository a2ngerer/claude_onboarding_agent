---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-07-16
sources:
  - https://docs.claude.com/en/docs/claude-code/hooks
  - https://docs.claude.com/en/docs/claude-code/settings
  - https://docs.claude.com/en/docs/claude-code/plugins
  - https://docs.claude.com/en/docs/claude-code/slash-commands
  - https://docs.claude.com/en/docs/claude-code/memory
version: 3
---

## Memory files

- `CLAUDE.md` — project instructions at `./CLAUDE.md` or `./.claude/CLAUDE.md`; user-level at `~/.claude/CLAUDE.md`. Loaded into every session. Block-level HTML comments are stripped before injection — safe for maintainer-only notes.
- `CLAUDE.local.md` — personal project notes; gitignored, appended after `CLAUDE.md`.
- `AGENTS.md` — not read natively by Claude Code. If the repo needs both, `CLAUDE.md` imports it with `@AGENTS.md` (or symlinks `CLAUDE.md -> AGENTS.md` on non-Windows).
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally; `.claude/rules/` supports symlinks for sharing rules across projects.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 4 hops).
- **Auto memory** — Claude also writes its own notes to `~/.claude/projects/<project>/memory/` (this repo's own mechanism, described in the project's system-reminder). `MEMORY.md` is the index (first 200 lines / 25KB loaded every session); topic files load on demand. Machine-local, shared across worktrees of the same repo. Toggle with `autoMemoryEnabled`.

## Settings

Top-level keys in `.claude/settings.json` (curated subset — the full schema has dozens more): `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `requiredMaximumVersion`, `enforceAvailableModels`, `availableModels`, `autoMemoryEnabled`, `autoMemoryDirectory`, `allowedMcpServers`, `deniedMcpServers`, `disableAllHooks`.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — model to use when the primary `model` is unavailable or rate-limited; capped at 3 models, does not merge across settings files (highest-precedence file supplies the whole chain).
- **`requiredMinimumVersion`** / **`requiredMaximumVersion`** — semver strings; Claude Code refuses to run outside this range. Both fail open (invalid values are stripped, not enforced).
- **`enforceAvailableModels`** — boolean; when `true`, rejects model IDs not available in the current account/tier at startup rather than failing at runtime.
- **Scope precedence** (file location): Managed > CLI args > Local (`settings.local.json`) > Project (`settings.json`) > User (`~/.claude/settings.json`) — except `permissions.allow`/`deny`, which merge across scopes and evaluate `deny → ask → allow` (first match wins) rather than overriding.

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI environments or troubleshooting a broken config.

## Hooks

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` | Load context or env vars on session open | Inject current git branch |
| `InstructionsLoaded` | React to what triggered loading (new session, plugin install); inspect `load_reason` | Log which skills were loaded |
| `UserPromptSubmit` | Validate or enrich the user prompt | Block secret patterns |
| `PreToolUse` | Block or gate a tool call | Deny `Bash(rm -rf *)` |
| `PostToolUse` | Lint or log after a tool runs | Auto-run `eslint --fix` after `Edit` |
| `PostToolBatch` | React after a full parallel tool batch completes | Summarize a batch of file reads |
| `PermissionRequest` / `PermissionDenied` | React to a permission dialog or an auto-mode denial | Log denied commands |
| `SubagentStart` / `SubagentStop` | React to a subagent spawning or finishing | Track subagent fan-out |
| `MessageDisplay` | Intercept or annotate a message before it is shown | Inject a reminder banner |
| `PreCompact` | Save state before context compaction | Checkpoint session notes |
| `PostCompact` | Re-inject context after compaction | Reload pinned snippets |
| `WorktreeCreate` | Set up a fresh worktree (install deps, copy env) | `npm ci` in the new branch |
| `WorktreeRemove` | Clean up after a worktree is deleted | Remove temp build artifacts |
| `Stop` | Cleanup when Claude finishes a turn | Persist session notes |
| `SessionEnd` | Release resources or save artifacts | Flush metrics |

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of hook entries. Plugins ship hooks in `hooks/hooks.json`. Handler `type` is one of `command` (shell, JSON on stdin), `http` (POST to a URL), `mcp_tool`, `prompt` (single-turn yes/no), or `agent` (spawns a subagent to decide).

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work identically.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- Editing a standalone `SKILL.md`'s text is picked up live within a few seconds — no reload needed. Use `/reload-plugins` after editing a plugin's `hooks/`, `.mcp.json`, `agents/`, or `output-styles/`, or after installing/updating a plugin.
- `/cd <path>` — change the working directory for the current session (supports path autocomplete).
- `/plugin list` — list installed plugins and their status (`--enabled`/`--disabled` filters).
- `claude plugin init` — scaffold a new plugin in the current directory (CLI, not a slash command).
- `claude agents` — list all available named subagents (CLI).

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `arguments` | Named positional arguments for `$name` substitution; space-separated string or YAML list |
| `allowed-tools` | Tools Claude can use without asking while this skill is active (does not restrict other tools) |
| `disallowed-tools` | Tools removed from Claude's available pool while this skill is active |
| `model` | Override model for this skill (accepts aliases: `fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low` / `normal` / `high` — hint to the model's thinking budget |
| `context: fork` | Run the skill in a forked context (isolated from main conversation) |
| `context: agent` | Run the skill as a full subagent turn |
| `paths` | Glob list — load this skill only when CWD matches |
| `disable-model-invocation` | `true` — skill only runs when explicitly invoked with `/name`, never auto-triggered |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; only callable by Claude |

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`, `displayName` (marketplace/`/plugin list` name), `defaultEnabled` (activates without opt-in), `dependencies` (other required plugin names).
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/` (executables added to Bash's `PATH`), `settings.json`.
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
