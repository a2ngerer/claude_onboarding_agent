---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-07-29
sources:
  - https://docs.claude.com/en/docs/claude-code/hooks
  - https://docs.claude.com/en/docs/claude-code/settings
  - https://docs.claude.com/en/docs/claude-code/plugins
  - https://docs.claude.com/en/docs/claude-code/slash-commands
  - https://docs.claude.com/en/docs/claude-code/memory
version: 3
---

## Memory files

- `CLAUDE.md` — project instructions at `./CLAUDE.md` or `./.claude/CLAUDE.md`; user-level at `~/.claude/CLAUDE.md`; managed/org-wide at a fixed OS path (e.g. `/etc/claude-code/CLAUDE.md` on Linux). Loaded into every session.
- `CLAUDE.local.md` — personal project notes; gitignored, appended after `CLAUDE.md`.
- `AGENTS.md` — not read natively by Claude Code. If the repo needs both, `CLAUDE.md` imports it with `@AGENTS.md`.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 4 hops).
- **Auto memory** — Claude writes its own learnings to `~/.claude/projects/<project>/memory/MEMORY.md` (first 200 lines / 25KB loaded every session) plus on-demand topic files. Toggle with `autoMemoryEnabled`; browse with `/memory`.

## Settings

Dozens of top-level keys exist in `.claude/settings.json`; frequently used ones: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `enforceAvailableModels`, `availableModels`, `autoMemoryEnabled`, `skillOverrides`, `disableBundledSkills`, `effortLevel`, `autoMode`. Permission rules evaluate deny → ask → allow (deny always wins); scope precedence is managed → local → project → user, and rules merge across scopes rather than override.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — model(s) to try in order when the primary `model` is unavailable or rate-limited (max 3).
- **`requiredMinimumVersion`** — semver string; Claude Code refuses to run if the installed version is older.
- **`enforceAvailableModels`** — boolean; extends the `availableModels` allowlist to the Default model rather than only rejecting at runtime.
- **`skillOverrides`** — per-skill visibility control (`on` / `name-only` / `user-invocable-only` / `off`) from settings instead of frontmatter.

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI environments or troubleshooting a broken config.

## Hooks

Claude Code supports ~30 hook events across five phases: session lifecycle (`SessionStart`, `Setup`, `SessionEnd`, `InstructionsLoaded`, `ConfigChange`, `CwdChanged`, `FileChanged`), prompt/tool flow (`UserPromptSubmit`, `UserPromptExpansion`, `PreToolUse`, `PermissionRequest`, `PermissionDenied`, `PostToolUse`, `PostToolUseFailure`, `PostToolBatch`), subagents/tasks (`SubagentStart`, `SubagentStop`, `TaskCreated`, `TaskCompleted`, `TeammateIdle`), display/notification (`Notification`, `MessageDisplay`, `Elicitation`, `ElicitationResult`), and compaction/worktrees (`PreCompact`, `PostCompact`, `WorktreeCreate`, `WorktreeRemove`), plus `Stop` / `StopFailure`. Most commonly used:

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` | Load context or env vars on session open | Inject current git branch |
| `UserPromptSubmit` | Validate or enrich the user prompt | Block secret patterns |
| `PreToolUse` | Block or gate a tool call | Deny `Bash(rm -rf *)` |
| `PostToolUse` | Lint or log after a tool runs | Auto-run `eslint --fix` after `Edit` |
| `PostToolBatch` | React after a full parallel tool batch completes | Summarize a batch of file reads |
| `Notification` | Background-agent state change | React to `agent_needs_input` / `agent_completed` |
| `PreCompact` / `PostCompact` | Save/restore state across context compaction | Checkpoint session notes |
| `Stop` / `SessionEnd` | Cleanup when Claude finishes a turn or session | Persist session notes, flush metrics |

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of handler entries (`type: command | http | mcp_tool | prompt | agent`). Plugins ship hooks in `hooks/hooks.json`. Run `/hooks` to inspect what's configured.

## Slash commands & skills

- **Custom commands are now a subset of skills.** `.claude/commands/<name>.md` and `.claude/skills/<name>/SKILL.md` both create `/<name>` and work the same way; skills add supporting files, invocation-control frontmatter, and subagent execution. Prefer `skills/` for new work.
- Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`; plugin skills are namespaced `/<plugin-name>:<skill-name>`.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/…/`$ARGUMENTS[N]` (positional), `$name` via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only.
- `/reload-skills` / `/reload-plugins` — hot-reload skill/command/plugin files without restarting the session.
- `/cd <path>` — change the working directory for the current session.
- `/plugin list` — list installed plugins and their status.
- `claude plugin init` — scaffold a new plugin in the current directory (CLI, not a slash command).
- `claude agents` — list all available named subagents (CLI).

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `description` | What the skill does/when to use it — the main signal for auto-invocation |
| `when_to_use` | Extra trigger phrases, appended to `description` (combined cap: 1,536 chars) |
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `arguments` | Named positional args for `$name` substitution |
| `allowed-tools` / `disallowed-tools` | Per-invocation tool whitelist / blacklist (clears on next message) |
| `model` / `effort` | Override model or reasoning-effort budget for this skill's turn (accepts aliases, `inherit`) |
| `context: fork` | Run the skill in a forked subagent context (background by default; `background: false` to block) |
| `agent` | Which subagent type to use with `context: fork` |
| `paths` | Glob list — auto-load this skill only when CWD/files match |
| `disable-model-invocation` | `true` — skill only runs via explicit `/name` invocation |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; only callable by Claude |
| `hooks` | Hooks scoped to this skill's lifecycle |

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `description`, `version` (semver, optional — falls back to commit SHA), optional `author`, `homepage`, `repository`, `license`.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/`, `settings.json`.
- `settings.json` at plugin root currently supports only `agent` and `subagentStatusLine` keys; it applies when the plugin is enabled.
- Test locally with `claude --plugin-dir ./my-plugin` (or `--plugin-url` for a hosted `.zip`); run `/reload-plugins` after edits instead of restarting.
- Two public marketplaces: `claude-plugins-official` (curated by Anthropic) and `claude-community` (reviewed third-party submissions).

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
- `.claude/commands/*.md` still works but is legacy — prefer `skills/<name>/SKILL.md` for new functionality so supporting files and full frontmatter are available.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
