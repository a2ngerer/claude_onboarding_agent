---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-07-19
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
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 4).

## Auto memory

- Claude also maintains its own notes at `~/.claude/projects/<project>/memory/`, separate from CLAUDE.md. `MEMORY.md` is the index (first 200 lines / 25KB load at session start); topic files load on demand. Enabled by default; toggle with `autoMemoryEnabled` or via `/memory`.
- Subagents don't see the main conversation's auto memory; give one its own via the subagent `memory` field.

## Settings

Top-level keys in `.claude/settings.json` include `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `enforceAvailableModels`, `autoMemoryEnabled`, `autoMemoryDirectory`, `disableBundledSkills`, `skillOverrides`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — model to use when the primary `model` is unavailable or rate-limited.
- **`requiredMinimumVersion`** — semver string; Claude Code refuses to run if the installed version is older.
- **`enforceAvailableModels`** — boolean; when `true`, rejects model IDs not available in the current account/tier at startup rather than failing at runtime.
- **`sandbox.credentials`** / **`sandbox.allowAppleEvents`** — scope which credential files/env vars and macOS automation events a sandboxed command can touch.

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI environments or troubleshooting a broken config.

## Hooks

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` | Load context or env vars on session open | Inject current git branch |
| `InstructionsLoaded` | React to what triggered loading (new session, `/reload-skills`, plugin install); inspect `load_reason` | Log which skills were loaded |
| `UserPromptSubmit` | Validate or enrich the user prompt | Block secret patterns |
| `PreToolUse` | Block or gate a tool call | Deny `Bash(rm -rf *)` |
| `PostToolUse` | Lint or log after a tool runs | Auto-run `eslint --fix` after `Edit` |
| `SubagentStart` / `SubagentStop` | React to a subagent's lifecycle by agent type | Set up/tear down a DB connection for `db-agent` |
| `Notification` | Fires on `agent_needs_input` / `agent_completed` for background agents | Push a desktop notification |
| `MessageDisplay` | Intercept or annotate a message before it is shown | Inject a reminder banner |
| `PreCompact` | Save state before context compaction | Checkpoint session notes |
| `PostCompact` | Re-inject context after compaction | Reload pinned snippets |
| `WorktreeCreate` | Set up a fresh worktree (install deps, copy env) | `npm ci` in the new branch |
| `WorktreeRemove` | Clean up after a worktree is deleted | Remove temp build artifacts |
| `Stop` | Cleanup when Claude finishes a turn | Persist session notes |
| `SessionEnd` | Release resources or save artifacts | Flush metrics |

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, command }` entries. Plugins ship hooks in `hooks/hooks.json`. Subagent frontmatter can also scope `PreToolUse`/`PostToolUse`/`Stop` hooks to just that agent.

## Slash commands

- Custom commands are merged into skills: `.claude/commands/deploy.md` and `.claude/skills/deploy/SKILL.md` both create `/deploy`. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- `/reload-skills` — hot-reload skill/command files without restarting the session.
- `/cd <path>` — change the working directory for the current session.
- `/doctor` — full setup checkup; the one bundled skill that stays typable even when `disableBundledSkills` is on.
- `/subtask` — run a forked subagent that inherits the conversation (was `/fork` before v2.1.212).
- `/config key=value` — set any setting from the prompt without editing `settings.json`.
- `claude mcp login <name>` / `claude mcp logout <name>` — authenticate or clear credentials for a configured MCP server from the shell.
- `/plugin list` — list installed plugins and their status.

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `when_to_use` | Extra trigger phrases appended to `description` for model-invocation matching |
| `allowed-tools` | Tools pre-approved for the turn that invokes this skill (comma-separated) |
| `disallowed-tools` | Tools removed from the pool while this skill is active |
| `model` | Override model for this skill (accepts aliases: `fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low` / `medium` / `high` / `xhigh` / `max` — hint to the model's thinking budget |
| `context: fork` / `agent` | Run the skill in a forked context; `agent` picks which subagent type executes it |
| `disable-model-invocation` | `true` — skill runs its command without calling the model (pure automation) |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; only callable programmatically |

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`, `displayName` (shown in the marketplace/`/plugin list`), `defaultEnabled` (activates without opt-in), `dependencies` (other required plugin names).
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/` (executables added to the Bash tool's `PATH`), `settings.json`.
- Two public marketplaces exist: `claude-plugins-official` (curated by Anthropic) and `claude-community` (reviewed third-party submissions). Run `claude plugin validate` before submitting.
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
- Namespace plugin skills; never rely on a collision-prone flat name.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md` so supporting files and frontmatter are available.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
