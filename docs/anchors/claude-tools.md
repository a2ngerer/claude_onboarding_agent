---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-09-02
sources:
  - https://docs.claude.com/en/docs/claude-code/hooks
  - https://docs.claude.com/en/docs/claude-code/settings
  - https://docs.claude.com/en/docs/claude-code/plugins
  - https://docs.claude.com/en/docs/claude-code/slash-commands
  - https://docs.claude.com/en/docs/claude-code/memory
version: 3
---

## Memory files

- `CLAUDE.md` — project instructions at `./CLAUDE.md` or `./.claude/CLAUDE.md`; user-level at `~/.claude/CLAUDE.md`; org-wide via a managed policy CLAUDE.md. Loaded into every session.
- `CLAUDE.local.md` — personal project notes; gitignored, appended after `CLAUDE.md`.
- `AGENTS.md` — not read natively by Claude Code. If the repo needs both, `CLAUDE.md` imports it with `@AGENTS.md` (or symlink `CLAUDE.md` → `AGENTS.md` on non-Windows).
- Size target: keep each `CLAUDE.md` under ~200 lines; Claude Code loads files up to 4 MiB but shorter files get better adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 4).
- **Auto memory** — Claude writes its own notes (`user`/`feedback`/`project`/`reference` types) to `~/.claude/projects/<repo>/memory/`, on by default. `MEMORY.md` is the index (first 200 lines / 25KB load at session start); topic files load on demand. Toggle with `/memory` or the `autoMemoryEnabled` setting; relocate with `autoMemoryDirectory`.

## Settings

Top-level keys in `.claude/settings.json` include `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `enforceAvailableModels`, `autoMemoryEnabled`/`autoMemoryDirectory`, `modelPicker`, `timeFormat`/`timeZone`. Permission rules evaluate in order `deny → ask → allow`; first match wins. Precedence across files, highest first: managed settings → CLI `--settings` → `.claude/settings.local.json` → `.claude/settings.json` → `~/.claude/settings.json`. Add `"$schema": "https://json.schemastore.org/claude-code-settings.json"` for editor autocomplete.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — model to use when the primary `model` is unavailable or rate-limited.
- **`requiredMinimumVersion`** — semver string; Claude Code refuses to run if the installed version is older.
- **`enforceAvailableModels`** — boolean; when `true`, rejects model IDs not available in the current account/tier at startup rather than failing at runtime.
- **`permissions.blockReadsOutsideWorkingDirectories`** — one-time prompt before the first read outside the working directory.

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI environments or troubleshooting a broken config.

## Hooks

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` | Load context or env vars on session open | Inject current git branch |
| `InstructionsLoaded` | React to what triggered loading (new session, `/reload-skills`, plugin install) | Log which skills were loaded |
| `UserPromptSubmit` | Validate or enrich the user prompt | Block secret patterns |
| `PreToolUse` / `PermissionRequest` | Block, gate, or auto-decide a tool call | Deny `Bash(rm -rf *)` |
| `PostToolUse` / `PostToolUseFailure` | Lint or log after a tool runs (or fails) | Auto-run `eslint --fix` after `Edit` |
| `PostToolBatch` | React after a full parallel tool batch completes | Summarize a batch of file reads |
| `PreModelSwitch` / `PostModelSwitch` | Block, confirm, or annotate a model switch | Warn before switching off Opus |
| `SubagentStart` / `SubagentStop` | React to a subagent spawning or finishing | Log subagent dispatch |
| `PreCompact` / `PostCompact` | Save/restore state around context compaction | Checkpoint session notes |
| `WorktreeCreate` / `WorktreeRemove` | Set up or clean up a worktree | `npm ci` in the new branch |
| `Stop` / `SessionEnd` | Cleanup when Claude finishes a turn or session ends | Persist session notes |

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of handlers. A handler's `type` is `command` (shell), `http` (POST to a URL), `mcp_tool`, `prompt`, or `agent` (spawn a subagent). Plugins ship hooks in `hooks/hooks.json`; skills and subagents can also register hooks in their own frontmatter, active only while they run.

## Slash commands

- Custom commands have been merged into skills: `.claude/commands/deploy.md` and `.claude/skills/deploy/SKILL.md` both create `/deploy`. Prefer `skills/<name>/SKILL.md` for new work — it supports supporting files and full frontmatter.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only.
- `/reload-skills` — hot-reload skill/command files without restarting the session.
- `/cd <path>` / `/add-dir <path>` — change or add a working directory for the current session.
- `/rewind` — restore a previous conversation/code checkpoint; `/doctor` — checkup that flags config problems.
- `/plugin list` — list installed plugins and their status.
- `claude plugin init` / `claude agents` — scaffold a plugin / list available named subagents (CLI, not slash commands).

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `allowed-tools` | Tool whitelist granted for the turn that invokes this skill |
| `model` | Override model for this skill (accepts aliases: `fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low`/`medium`/`high`/`xhigh`/`max` — thinking budget hint |
| `context: fork` | Run the skill in a forked subagent context (isolated from main conversation) |
| `paths` | Glob list — load this skill only when Claude works with matching files |
| `disable-model-invocation` | `true` — skill runs its command without calling the model (pure automation) |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; only callable by Claude |

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`, `license`, `displayName`, `defaultEnabled`, `dependencies`.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `settings.json`, `bin/` (executables added to Bash's `PATH` while the plugin is enabled).
- A plugin's own `settings.json` currently only applies its `agent` and `subagentStatusLine` keys as defaults when the plugin is enabled.
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits without a restart.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
- Namespace plugin skills; never rely on a collision-prone flat name.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
