---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-08-05
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
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 5).

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `availableModels`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `requiredMaximumVersion`, `enforceAvailableModels`, `autoMemoryEnabled`, `autoMemoryDirectory`. Permission rules evaluate in order `deny → ask → allow`; first match wins. Across settings *files*, rules merge (both a user-level allow and a project-level allow apply) following scope precedence `managed → CLI args → local → project → user`.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — model(s) to try when the primary `model` is unavailable or rate-limited; chains cap at three entries and don't merge across settings files.
- **`requiredMinimumVersion` / `requiredMaximumVersion`** — managed-settings-only semver bounds; an invalid value fails open (stripped, not enforced) rather than blocking startup.
- **`enforceAvailableModels`** — boolean; with a non-empty `availableModels` allowlist, restricts the Default model option to that list.

There is no single "safe mode" variable. Disable individual subsystems instead: `CLAUDE_CODE_DISABLE_AUTO_MEMORY`, `CLAUDE_CODE_DISABLE_WORKFLOWS`, `CLAUDE_CODE_DISABLE_BUNDLED_SKILLS`, `CLAUDE_CODE_DISABLE_AGENT_VIEW`, `DISABLE_AUTO_COMPACT`.

## Hooks

Claude Code documents 30+ hook events across session lifecycle, per-turn, tool execution, subagent/batch, task, file/directory, config, and UI categories. Key events:

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` | Load context or env vars on session open | Inject current git branch |
| `InstructionsLoaded` | React to what triggered loading (new session, `/reload-skills`, plugin install); inspect `load_reason` | Log which skills were loaded |
| `UserPromptSubmit` | Validate or enrich the user prompt | Block secret patterns |
| `PreToolUse` / `PermissionRequest` | Block or gate a tool call before it runs | Deny `Bash(rm -rf *)` |
| `PostToolUse` / `PostToolUseFailure` | Lint or log after a tool succeeds or fails | Auto-run `eslint --fix` after `Edit` |
| `PostToolBatch` | React after a full parallel tool batch completes | Summarize a batch of file reads |
| `SubagentStart` / `SubagentStop` | React to subagent lifecycle | Log which subagent ran and its result |
| `TaskCreated` / `TaskCompleted` | React to `TaskCreate`/completion | Sync tasks to an external tracker |
| `PreCompact` / `PostCompact` | Save/restore state around context compaction | Checkpoint session notes |
| `WorktreeCreate` / `WorktreeRemove` | Set up or tear down a worktree | `npm ci` in the new branch |
| `Stop` / `SessionEnd` | Cleanup when a turn or session ends | Persist session notes |

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of handler entries. Handler `type` is one of `command` (shell), `http` (POST to an endpoint), `mcp_tool`, `prompt` (LLM yes/no), or `agent` (subagent verification). Plugins ship hooks in `hooks/hooks.json`; skills and agents can also scope hooks via frontmatter.

## Slash commands

- Custom commands have been merged into skills: `.claude/commands/deploy.md` and `.claude/skills/deploy/SKILL.md` both create `/deploy` and behave the same. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work but `skills/` is preferred for new work (supporting files, richer frontmatter).
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions. A nested project `.claude/skills/` directory is namespaced by path only when its skill name collides with another (e.g. `apps/web:deploy`).
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- `/reload-skills` — hot-reload skill/command files without restarting the session.
- `/cd <path>` — change the working directory for the current session.
- `/plugin list` — list installed plugins and their status.
- `claude plugin init` — scaffold a new plugin in the current directory (CLI, not a slash command).
- `claude agents` — list all available named subagents (CLI).

## SKILL.md frontmatter fields

Only `description` is recommended; all fields are optional. Boolean fields accept `yes`/`no`/`on`/`off`/`1`/`0` (case-insensitive) in addition to `true`/`false`.

| Field | Purpose |
|---|---|
| `when_to_use` | Trigger phrases/example requests, appended to `description` (combined cap: 1,536 chars) |
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `arguments` | Named positional args for `$name` substitution in the skill body |
| `allowed-tools` | Tools pre-approved for the turn that invokes this skill (clears next message) |
| `disallowed-tools` | Tools removed from the pool while this skill is active |
| `model` | Override model for this skill (accepts aliases: `fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low` / `medium` / `high` / `xhigh` / `max` — thinking-budget hint |
| `context: fork` | Run the skill in a forked subagent context; `agent:` picks which subagent type, `background: false` waits inline instead of backgrounding |
| `paths` | Glob list — load this skill only when Claude works with matching files |
| `hooks` | Hooks scoped to this skill's lifecycle |
| `shell` | `bash` (default) or `powershell` for inline `` !`command` `` blocks |
| `disable-model-invocation` | `true` — skill only runs via explicit `/name` (also blocks subagent preload and scheduled-task triggers) |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; only callable programmatically |

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `description`, `version` (semver, optional — falls back to git commit SHA), optional `author`, `homepage`, `repository`, `license`, `displayName` (marketplace label), `defaultEnabled` (activates without opt-in), `dependencies` (other required plugin names).
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/` (preferred), `commands/` (legacy flat files), `agents/`, `hooks/hooks.json`, `.mcp.json`, `.lsp.json` (language servers), `monitors/monitors.json` (background log/status watchers), `bin/` (executables added to Bash's `PATH`), `settings.json` (default settings on enable — currently supports `agent` and `subagentStatusLine` keys).
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
