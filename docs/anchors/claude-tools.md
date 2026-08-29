---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-08-29
sources:
  - https://docs.claude.com/en/docs/claude-code/hooks
  - https://docs.claude.com/en/docs/claude-code/settings
  - https://docs.claude.com/en/docs/claude-code/plugins
  - https://docs.claude.com/en/docs/claude-code/slash-commands
  - https://docs.claude.com/en/docs/claude-code/memory
version: 3
---

## Memory files

- `CLAUDE.md` — project instructions at `./CLAUDE.md` or `./.claude/CLAUDE.md`; user-level at `~/.claude/CLAUDE.md`; managed policy at `/etc/claude-code/CLAUDE.md` (Linux/WSL) or platform equivalent, or inline via managed-settings `claudeMd`. Loaded into every session.
- `CLAUDE.local.md` — personal project notes; gitignored, appended after `CLAUDE.md`.
- `AGENTS.md` — not read natively by Claude Code. If the repo needs both, `CLAUDE.md` imports it with `@AGENTS.md` (or a symlink on non-Windows).
- Size target: keep each `CLAUDE.md` under ~200 lines (hard cap 4 MiB); longer files reduce adherence. `/doctor` can propose trims.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally; rule files/dirs may be symlinks.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 4 hops).
- Auto memory: Claude also writes its own notes to `~/.claude/projects/<project>/memory/MEMORY.md` (+ topic files) from corrections/preferences; toggle with `autoMemoryEnabled`, relocate with `autoMemoryDirectory`.

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `enforceAvailableModels`, plus `autoMemoryEnabled`/`autoMemoryDirectory`, `skillOverrides` (hide/collapse a skill without editing its frontmatter), and managed-only `claudeMd` (inject org CLAUDE.md text directly). Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — model to use when the primary `model` is unavailable or rate-limited.
- **`requiredMinimumVersion`** — semver string; Claude Code refuses to run if the installed version is older.
- **`enforceAvailableModels`** — boolean; when `true`, rejects model IDs not available in the current account/tier at startup rather than failing at runtime.

**Safe mode:** `claude --safe-mode` (sets `CLAUDE_CODE_SAFE_MODE`) disables CLAUDE.md, skills, plugins, hooks, MCP servers, custom commands/agents, output styles, and auto memory — broader than just the four systems named above. Useful for security-sensitive CI or troubleshooting a broken config; auth, model selection, and built-in tools keep working.

## Hooks

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` | Load context or env vars on session open | Inject current git branch |
| `InstructionsLoaded` | React to what triggered loading (new session, `/reload-skills`, plugin install, lazy nested load); inspect `load_reason` | Log which skills were loaded |
| `UserPromptSubmit` | Validate or enrich the user prompt | Block secret patterns |
| `PreToolUse` | Block or gate a tool call | Deny `Bash(rm -rf *)` |
| `PermissionRequest` / `PermissionDenied` | Intercept a permission decision, or let auto mode retry after a denial | Custom approval logic |
| `PostToolUse` / `PostToolUseFailure` | Lint or log after a tool succeeds or fails | Auto-run `eslint --fix` after `Edit` |
| `PostToolBatch` | React after a full parallel tool batch completes | Summarize a batch of file reads |
| `MessageDisplay` | Intercept or annotate a message before it is shown | Inject a reminder banner |
| `SubagentStart` / `SubagentStop` | React to a subagent spawning or finishing | Log `agent_id`/`agent_type` |
| `PreCompact` / `PostCompact` | Save state before compaction / re-inject after | Checkpoint session notes |
| `WorktreeCreate` / `WorktreeRemove` | Set up or clean up a worktree | `npm ci` in the new branch |
| `Stop` / `StopFailure` | Cleanup when a turn ends normally or via API error | Persist session notes |
| `SessionEnd` | Release resources or save artifacts | Flush metrics |

Many more narrow events exist (`UserPromptExpansion`, `ConfigChange`, `TaskCreated`/`TaskCompleted`, `FileChanged`, `CwdChanged`, `DirectoryAdded`, `Elicitation`/`ElicitationResult`, `Notification`, `TeammateIdle`, `Setup`) — see `/hooks` in-session or the hooks doc for the full list. Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` as `{ matcher, hooks: [{ type, command, ... }] }`; beyond `type: "command"`, hooks can be `"http"`, `"mcp_tool"`, `"prompt"`, or `"agent"`. Plugins ship hooks in `hooks/hooks.json`; skills and subagents can also register hooks via a `hooks:` frontmatter field, scoped to when they're active.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (0-based positional), named args via `arguments:` frontmatter (`$name`).
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
| `arguments` | Named positional args for `$name` substitution |
| `allowed-tools` | Tool whitelist granted (no prompt) for the invoking turn only |
| `disallowed-tools` | Tools removed from the pool while the skill is active |
| `model` | Override model for this skill (accepts aliases: `fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low`/`medium`/`high`/`xhigh`/`max` — hint to the model's thinking budget |
| `context: fork` | Run the skill in a forked subagent context (isolated from main conversation) |
| `agent` | Which subagent type to use when `context: fork` is set — there is no `context: agent` |
| `background` | With `context: fork`, set `false` to block on the result instead of running in the background (default `true`) |
| `hooks` | Hooks registered while the skill is active (see Hooks above) |
| `paths` | Glob list — auto-load this skill only when Claude touches matching files (not CWD) |
| `disable-model-invocation` | `true` — skill only runs via explicit `/name`; hides it from Claude's own invocation |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; only callable by Claude |

## Plugins

- Manifest: `.claude-plugin/plugin.json`. Common fields: `name`, `version` (semver), `description`, `author`, `homepage`, `repository`, `license`, `displayName`, `defaultEnabled`, `dependencies`, `keywords`, `metadata`. Component-path fields (`skills`, `commands`, `agents`, `hooks`, `mcpServers`, `outputStyles`, `lspServers`, `workflows`) point the manifest at non-default locations; `skills` adds to the default `skills/` dir, the rest replace their default dir.
  - `displayName` — human-readable name shown in the marketplace and `/plugin list`.
  - `defaultEnabled` — boolean; whether the plugin activates on install without user opt-in.
  - `dependencies` — other plugin names (optionally with semver constraints) required for this plugin to function.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `settings.json`, `bin/` (executables added to Bash's `PATH` while the plugin is enabled).
- Version every release; users update through the marketplace. Run `/reload-plugins` after edits instead of restarting.

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
