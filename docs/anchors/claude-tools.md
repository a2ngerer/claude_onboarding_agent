---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-08-03
sources:
  - https://docs.claude.com/en/docs/claude-code/hooks
  - https://docs.claude.com/en/docs/claude-code/settings
  - https://docs.claude.com/en/docs/claude-code/plugins
  - https://docs.claude.com/en/docs/claude-code/slash-commands
  - https://docs.claude.com/en/docs/claude-code/memory
version: 3
---

## Memory files

- `CLAUDE.md` — project instructions at `./CLAUDE.md` or `./.claude/CLAUDE.md`; user-level at `~/.claude/CLAUDE.md`; managed policy at `/etc/claude-code/CLAUDE.md` (Linux) or platform equivalent, or inline via the `claudeMd` key in managed settings. Loaded into every session.
- `CLAUDE.local.md` — personal project notes; gitignored, appended after `CLAUDE.md`.
- `AGENTS.md` — not read natively by Claude Code. Import it from `CLAUDE.md` with `@AGENTS.md`, or symlink `CLAUDE.md -> AGENTS.md` (requires admin/Developer Mode on Windows).
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence. `/doctor` proposes trims for a checked-in `CLAUDE.md`.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth **4 hops**, not 5).
- **Auto memory:** Claude writes its own notes (build commands, debugging insights, preferences) to `~/.claude/projects/<project>/memory/MEMORY.md` plus topic files, shared across worktrees of the same repo. On by default; toggle with `/memory` or `autoMemoryEnabled`. Only the first 200 lines / 25KB of `MEMORY.md` load at session start.

## Settings

Top-level keys in `.claude/settings.json` include: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `enforceAvailableModels`, `autoMemoryEnabled`, `autoMemoryDirectory`, `disableAutoMode`. Permission rules evaluate in order `deny → ask → allow`; first match wins. Settings themselves resolve managed → CLI args → local → project → user (highest to lowest), except permission rules, which merge across scopes instead of overriding.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — model(s) to use when the primary `model` is unavailable or rate-limited (capped at three; doesn't merge across settings files).
- **`requiredMinimumVersion`** — semver string; Claude Code refuses to run if the installed version is older. Fails open on an invalid value.
- **`enforceAvailableModels`** — boolean; when `true` with a non-empty `availableModels` allowlist, rejects model IDs not on the allowlist at startup rather than failing at runtime.
- **`sandbox.network.strictAllowlist`**, **`sandbox.filesystem.disabled`**, **`sandbox.credentials`** — managed-settings-only controls for network egress, filesystem access, and injecting credentials into the sandbox.
- **`disableAutoMode`** — removes `auto` from the permission-mode cycle and rejects `--permission-mode auto`.

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI environments or troubleshooting a broken config.

## Hooks

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` | Load context or env vars on session open | Inject current git branch |
| `InstructionsLoaded` | React to what triggered loading (new session, `/reload-skills`, plugin install) | Log which skills were loaded |
| `UserPromptSubmit` | Validate or enrich the user prompt | Block secret patterns |
| `PreToolUse` | Block or gate a tool call | Deny `Bash(rm -rf *)` |
| `PostToolUse` | Lint or log after a tool runs | Auto-run `eslint --fix` after `Edit` |
| `PostToolBatch` | React after a full parallel tool batch completes | Summarize a batch of file reads |
| `SubagentStart` / `SubagentStop` | React to a subagent beginning or finishing | Set up/tear down a scoped DB connection |
| `DirectoryAdded` | A working directory is added mid-session (`/add-dir`) | Load extra context for the new directory |
| `PreCompact` / `PostCompact` | Save/restore state around context compaction | Checkpoint and reload session notes |
| `WorktreeCreate` / `WorktreeRemove` | Set up or clean up a worktree | `npm ci` in the new branch |
| `Stop` / `SessionEnd` | Cleanup when Claude finishes a turn or session | Persist session notes; flush metrics |

Many more events exist (`Setup`, `PermissionRequest`, `TaskCreated`, `Elicitation`, etc.) — see the canonical hooks doc for the full list. Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of handler entries. Handler `type` is one of `command`, `http`, `mcp_tool`, `prompt`, or `agent` (experimental). Plugins ship hooks in `hooks/hooks.json`; subagents can define hooks scoped to themselves in their own frontmatter.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- `/reload-skills` — hot-reload skill/command files without restarting the session.
- `/rewind` — restore conversation and/or code to a prior checkpoint; `Esc` twice opens the same menu.
- `/doctor` — checkup command; proposes trims for an oversized checked-in `CLAUDE.md` and flags duplicate subagent names.
- `/cd <path>` — change the working directory for the current session.
- `/plugin list` — list installed plugins and their status.
- `claude plugin init` — scaffold a new plugin in the current directory (CLI, not a slash command).

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

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`, `displayName`, `defaultEnabled`, `dependencies`.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/`, `settings.json`.
  - `bin/` — executables added to the Bash tool's `PATH` while the plugin is enabled.
  - Plugin-root `settings.json` currently supports only `agent` (activate a bundled subagent as the main thread) and `subagentStatusLine`.
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits to skills, agents, hooks, and plugin MCP/LSP servers.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
- Pin plugin versions in team repos; run `/reload-plugins` after edits instead of restarting.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md` or symlink it.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
