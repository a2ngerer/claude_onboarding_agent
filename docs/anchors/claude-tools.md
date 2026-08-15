---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-08-15
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
- `AGENTS.md` — not read natively by Claude Code. If the repo needs both, `CLAUDE.md` imports it with `@AGENTS.md` (or symlink `CLAUDE.md` → `AGENTS.md` on non-Windows).
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 4 hops).

## Auto memory

Separate from CLAUDE.md, Claude writes its own persistent notes as it works — build commands, debugging insights, corrected preferences — without being asked. Stored per-repo at `~/.claude/projects/<project>/memory/`, indexed by `MEMORY.md` (loaded in full each session, capped at 200 lines / 25KB) plus on-demand topic files. On by default; toggle with `autoMemoryEnabled: false` or `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`. Subagents don't inherit it (forks excepted); a subagent gets its own via the `memory:` frontmatter field.

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `enforceAvailableModels`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — model to use when the primary `model` is unavailable or rate-limited.
- **`requiredMinimumVersion`** / **`requiredMaximumVersion`** — semver strings; Claude Code refuses to run if the installed version falls outside the range. Invalid values are stripped (fail-open) rather than enforced.
- **`enforceAvailableModels`** — boolean; when `true`, rejects model IDs not in the `availableModels` allowlist at startup rather than failing at runtime.
- **Recently added keys:** `sandbox.network.strictAllowlist`/`sandbox.filesystem.disabled` (sandbox controls), `modelOverrides` (map unrecognized model IDs to canonical ones), `workflowSizeGuideline` (`small`/`medium`/`large` scale hint for dynamic workflows), `crossSessionInbound` (`accept`/`hold`/`refuse` for cross-session messages).

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI environments or troubleshooting a broken config.

## Hooks

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` | Load context or env vars on session open | Inject current git branch |
| `InstructionsLoaded` | React to what triggered loading (new session, `/reload-skills`, plugin install); inspect `load_reason` | Log which skills were loaded |
| `UserPromptSubmit` | Validate or enrich the user prompt | Block secret patterns |
| `PreToolUse` | Block or gate a tool call | Deny `Bash(rm -rf *)` |
| `PostToolUse` | Lint or log after a tool runs | Auto-run `eslint --fix` after `Edit` |
| `PostToolBatch` | React after a full parallel tool batch completes | Summarize a batch of file reads |
| `MessageDisplay` | Intercept or annotate a message before it is shown | Inject a reminder banner |
| `PreCompact` | Save state before context compaction | Checkpoint session notes |
| `PostCompact` | Re-inject context after compaction | Reload pinned snippets |
| `WorktreeCreate` | Set up a fresh worktree (install deps, copy env) | `npm ci` in the new branch |
| `WorktreeRemove` | Clean up after a worktree is deleted | Remove temp build artifacts |
| `Stop` | Cleanup when Claude finishes a turn | Persist session notes |
| `SessionEnd` | Release resources or save artifacts | Flush metrics |
| `DirectoryAdded` | New working dir registered mid-session (`/add-dir`) | React to newly accessible files |
| `SubagentStart` / `SubagentStop` | Subagent spawned / finishes | Track subagent fan-out |

This is a curated subset — Claude Code also defines `Setup`, `UserPromptExpansion`, `StopFailure`, `PostToolUseFailure`, `PermissionRequest`, `PermissionDenied`, `TaskCreated`, `TaskCompleted`, `FileChanged`, `CwdChanged`, `ConfigChange`, `Notification`, `Elicitation`/`ElicitationResult` for finer-grained automation.

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, command }` entries. Plugins ship hooks in `hooks/hooks.json`; a skill or subagent can also scope its own hooks in frontmatter.

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

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`, `displayName` (marketplace display name), `defaultEnabled` (activates without opt-in), `dependencies` (other required plugin names).
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/` (legacy flat-file form — use `skills/` for new plugins), `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/` (executables added to the Bash tool's `PATH` while enabled), `settings.json`.
- A plugin's own `settings.json` can set default config for installers — currently only `agent` (activate one of the plugin's custom agents as the main-thread agent) and `subagentStatusLine`; unknown keys are ignored.
- Version every release; `/reload-plugins` picks up local edits and reloads skills, agents, hooks, plugin MCP servers, and plugin LSP servers.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
- Pin plugin versions in team repos, run `/reload-plugins` after edits, and namespace plugin skills — never rely on a collision-prone flat name.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md` so supporting files and frontmatter are available.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
