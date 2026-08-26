---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-08-26
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
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence; Claude Code skips files over 4 MiB entirely.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 4).
- **Auto memory** (separate from CLAUDE.md): Claude writes its own notes to `~/.claude/projects/<project>/memory/` — `user`, `feedback`, `project`, `reference` types. On by default; toggle with `/memory` or `autoMemoryEnabled` in settings.

## Settings

Top-level keys in `.claude/settings.json` include: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `enforceAvailableModels`, `modelPicker`, `autoMemoryEnabled`, `autoMemoryDirectory`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — ordered chain of models to use when the primary `model` is unavailable or rate-limited.
- **`modelPicker`** — curates the `/model` picker with a labeled, ordered list of models (v2.1.242+).
- **`requiredMinimumVersion`** — semver string; Claude Code refuses to run if the installed version is older.
- **`enforceAvailableModels`** — boolean; when `true`, rejects model IDs not available in the current account/tier at startup rather than failing at runtime.

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI environments or troubleshooting a broken config.

## Hooks

| Event | Typical use |
|---|---|
| `SessionStart` / `SessionEnd` | Load context on open / release resources on exit |
| `Setup` | One-time preparation (`--init-only`/`--init`/`--maintenance`) |
| `UserPromptSubmit` | Validate or enrich the user prompt; block secret patterns |
| `PreToolUse` / `PostToolUse` | Block a tool call before it runs / lint or log after it succeeds |
| `PostToolUseFailure` | React after a tool call fails |
| `PostToolBatch` | Summarize a full parallel tool batch after it resolves |
| `SubagentStart` / `SubagentStop` | React when a subagent is spawned / finishes |
| `DirectoryAdded` | Fires when a working directory is added mid-session (`/add-dir`) |
| `PreCompact` / `PostCompact` | Checkpoint state before compaction / re-inject pinned context after |
| `WorktreeCreate` / `WorktreeRemove` | Set up a fresh worktree (`npm ci`) / clean up on removal |
| `Stop` / `StopFailure` | Cleanup when Claude finishes a turn / handle a turn that ended in an API error |

This is not exhaustive — granular events also exist for permissions (`PermissionRequest`, `PermissionDenied`), MCP elicitation, file-watching, and config changes. See the hooks source for the full catalog.

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, command }` entries (`type` also accepts `http`, `mcp_tool`, `prompt`, or `agent`). Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), `$name` for named args declared via the `arguments:` frontmatter list.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- `/reload-skills` — hot-reload skill/command files without restarting the session.
- `/code-review` runs as a background subagent by default (v2.1.218+); `/review` is an alias for it.
- `claude plugin init` — scaffold a new plugin (CLI, not a slash command).

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `arguments` | Named positional arguments (space-separated string or YAML list) for `$name` substitution |
| `allowed-tools` | Tool whitelist usable without prompting during the invoking turn only |
| `disallowed-tools` | Tools removed from Claude's pool while the skill is active |
| `model` | Override model for this skill (accepts aliases or `inherit`) |
| `effort` | `low` / `medium` / `high` / `xhigh` / `max` — thinking-budget hint |
| `context: fork` | Run the skill in a forked subagent context; pair with `agent:` to pick the subagent type |
| `paths` | Glob list — load this skill only when CWD matches |
| `disable-model-invocation` | `true` — skill runs its command without calling the model (pure automation) |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; only callable programmatically |

Note: there is no `context: agent` value — use `context: fork` plus a separate `agent:` field to choose the subagent type.

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`, `displayName`, `defaultEnabled`, `dependencies`.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/` (executables added to Bash's `PATH`), `settings.json`.
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
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
