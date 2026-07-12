---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-07-12
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
- `AGENTS.md` — not read natively by Claude Code. If the repo needs both, `CLAUDE.md` imports it with `@AGENTS.md` (or a symlink on non-Windows systems).
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth **4** hops).
- **Auto memory** — a separate, Claude-written mechanism (distinct from `CLAUDE.md`): notes Claude saves itself at `~/.claude/projects/<project>/memory/`, keyed off the git repo (shared across worktrees, not across machines). `MEMORY.md` is the index; only its first 200 lines / 25KB load at session start, topic files load on demand. Toggle with `autoMemoryEnabled`; relocate with `autoMemoryDirectory`.

## Settings

`.claude/settings.json` supports around 70 top-level keys; the common ones are `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`/`requiredMaximumVersion`, `enforceAvailableModels`, `plugins`, `pluginMarketplaces`, `autoMemoryEnabled`/`autoMemoryDirectory`, `disableAutoMode`, `dynamicWorkflowSize`. Permission rules evaluate in order `deny → ask → allow` (first match wins) and also support `Tool(param:value)` syntax, e.g. `Agent(model:opus)`.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — model(s) to use when the primary `model` is unavailable or rate-limited. Accepts an array of up to three IDs/aliases, tried in order.
- **`requiredMinimumVersion`** / **`requiredMaximumVersion`** — semver strings bounding the installed Claude Code version; invalid values are stripped rather than enforced (fail open).
- **`enforceAvailableModels`** — boolean; when `true` alongside a non-empty `availableModels` allowlist, constrains the default model to that list at startup rather than failing at runtime.
- **`disableAutoMode`** — prevents auto-mode activation (removes it from the `Shift+Tab` cycle, rejects `--permission-mode auto`).

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI environments or troubleshooting a broken config.

## Hooks

Claude Code has ~32 hook events total. The frequently used ones:

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` | Load context or env vars on session open | Inject current git branch |
| `InstructionsLoaded` | React to what triggered loading (new session, `/reload-skills`, plugin install); inspect `load_reason` | Log which skills were loaded |
| `UserPromptSubmit` | Validate or enrich the user prompt | Block secret patterns |
| `PreToolUse` | Block or gate a tool call | Deny `Bash(rm -rf *)` |
| `PostToolUse` / `PostToolBatch` | Lint or log after a tool call, or after a full parallel batch | Auto-run `eslint --fix` after `Edit` |
| `PermissionRequest` / `PermissionDenied` | React to a permission dialog or an auto-mode denial | Log denied commands |
| `SubagentStart` / `SubagentStop` | React to a subagent spawning or finishing | Track subagent usage |
| `TaskCreated` / `TaskCompleted` | React to `TaskCreate` / task completion | Sync tasks to an external tracker |
| `Notification` | React to a Claude Code notification (`agent_needs_input`, `agent_completed`) | Send a push notification |
| `MessageDisplay` | Intercept or annotate a message before it is shown | Inject a reminder banner |
| `PreCompact` / `PostCompact` | Save state before / re-inject context after compaction | Checkpoint session notes |
| `WorktreeCreate` / `WorktreeRemove` | Set up or clean up a worktree | `npm ci` in the new branch |
| `Stop` / `SessionEnd` | Cleanup when Claude finishes a turn / the session ends | Persist session notes |

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, command }` entries. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- **Custom commands have merged into skills.** `.claude/commands/deploy.md` and `.claude/skills/deploy/SKILL.md` both create `/deploy` and behave the same; existing `.claude/commands/*.md` files keep working, but skills add supporting-file directories and richer frontmatter. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), `$name` (named, via `arguments:` frontmatter), `${CLAUDE_SESSION_ID}`, `${CLAUDE_EFFORT}`, `${CLAUDE_SKILL_DIR}`, `${CLAUDE_PROJECT_DIR}`.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- `/reload-skills` — hot-reload skill/command files without restarting the session.
- `/cd <path>` — change the working directory for the current session.
- `/plugin list` — list installed plugins and their status.
- `claude plugin init` — scaffold a new plugin into `~/.claude/skills/<name>/` that auto-loads every session (CLI, not a slash command).
- `claude agents` — list all available named subagents (CLI).

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `description` / `when_to_use` | What the skill does / extra trigger context; combined text truncates at 1,536 chars in the skill listing |
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `arguments` | Named positional arguments for `$name` substitution |
| `allowed-tools` | Tool whitelist usable without asking while this skill is active |
| `disallowed-tools` | Tools removed from the pool while this skill is active |
| `model` | Override model for this skill (accepts aliases: `fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low` / `medium` / `high` / `xhigh` / `max` — hint to the model's thinking budget |
| `context: fork` | Run the skill in a forked context (isolated from main conversation) |
| `agent` | Which subagent type to use when `context: fork` is set |
| `hooks` | Hooks scoped to this skill's lifecycle |
| `paths` | Glob list — load this skill only when CWD matches |
| `shell` | `bash` (default) or `powershell` for inline `` !`command` `` execution |
| `disable-model-invocation` | `true` — skill runs its command without calling the model (pure automation) |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; only callable programmatically |

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author` (object, e.g. `{"name": "..."}`), `homepage`, `repository`, `displayName` (shown in the marketplace and `/plugin list`), `defaultEnabled` (boolean; activates without opt-in), `dependencies` (other required plugin names).
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/` (executables added to Bash's `PATH`), `settings.json` (only `agent` and `subagentStatusLine` keys supported here).
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
- Pin plugin versions in team repos; namespace plugin skills so names never collide.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md`.
- Prefer `skills/<name>/SKILL.md` over flat `.claude/commands/*.md` for new functionality — both still work and create the same command, but only the skill layout gets a supporting-file directory and the full frontmatter field set.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
