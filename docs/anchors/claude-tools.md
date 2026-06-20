---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-06-20
sources:
  - https://docs.claude.com/en/docs/claude-code/hooks
  - https://docs.claude.com/en/docs/claude-code/settings
  - https://docs.claude.com/en/docs/claude-code/plugins
  - https://docs.claude.com/en/docs/claude-code/slash-commands
  - https://docs.claude.com/en/docs/claude-code/memory
version: 3
---

## Memory files

- `CLAUDE.md` — project at `./CLAUDE.md` or `./.claude/CLAUDE.md`; user at `~/.claude/CLAUDE.md`. Loaded every session.
- `CLAUDE.local.md` — personal project notes; gitignored, appended after `CLAUDE.md`.
- `AGENTS.md` — not read natively; import with `@AGENTS.md` in `CLAUDE.md` if both tools share a repo.
- Size target: under ~200 lines. Use `.claude/rules/*.md` with optional `paths:` frontmatter for scoped rules (no `paths:` → loads unconditionally). `@path/to/file` imports pull files into context (max depth 5).
- Auto memory — `~/.claude/projects/<repo>/memory/`; first 200 lines of `MEMORY.md` loaded each session. Toggle via `autoMemoryEnabled` in settings.

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `requiredMaximumVersion`, `enforceAvailableModels`.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — model chain tried in order when the primary is unavailable or rate-limited.
- **`requiredMinimumVersion` / `requiredMaximumVersion`** — Claude Code refuses to start outside the version range; omit either bound to leave it open.
- **`enforceAvailableModels`** — when `true`, rejects model IDs not on the account allowlist at startup rather than failing at runtime.

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers.

## Hooks

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` | Load context or env vars on session open | Inject current git branch |
| `InstructionsLoaded` | React to what triggered loading; inspect `load_reason` | Log which skills loaded |
| `UserPromptSubmit` | Validate or enrich the user prompt | Block secret patterns |
| `UserPromptExpansion` | Block or gate skill expansion before model call | Validate skill args |
| `PreToolUse` | Block or gate a tool call | Deny `Bash(rm -rf *)` |
| `PostToolUse` | Lint or log after a tool runs | Auto-run `eslint --fix` after `Edit` |
| `PostToolBatch` | React after a full parallel tool batch completes | Summarize batch reads |
| `SubagentStart` | Log or inject context when a subagent is spawned | Audit subagent launches |
| `SubagentStop` | Validate subagent completion | Require output contract |
| `MessageDisplay` | Transform displayed message text (screen only) | Inject reminder banner |
| `PreCompact` | Save state before context compaction | Checkpoint notes |
| `PostCompact` | Re-inject context after compaction | Reload pinned snippets |
| `WorktreeCreate` | Set up a fresh worktree | `npm ci` in new branch |
| `WorktreeRemove` | Clean up after worktree deleted | Remove temp artifacts |
| `Stop` | Cleanup when Claude finishes a turn | Persist session notes |
| `SessionEnd` | Release resources or save artifacts | Flush metrics |
| `TeammateIdle` | Prevent agent team teammate idle | Trigger continuation |

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, command }` entries. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills and custom commands are merged. Project skills: `.claude/skills/<name>/SKILL.md`; user: `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` still works.
- Plugin skills namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- `/reload-skills` — hot-reload skill/command files without restarting.
- `/cd <path>` — change the working directory for the current session.
- `/goal <condition>` — set completion condition; Claude keeps working with live progress overlay until met.
- `/config key=value` — set any setting from the prompt (e.g. `/config thinking=false`).
- `/code-review` — review the current diff for correctness bugs at configurable effort; `--comment` posts inline PR comments.
- `/plugin list` / `/plugin details` — list installed plugins; show component inventory and projected token cost.
- `claude plugin init` — scaffold a new plugin in the current directory (CLI). `claude agents` — list all named subagents (CLI).

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `allowed-tools` | Comma-separated tool whitelist for this skill's invocation |
| `disallowed-tools` | Comma-separated tools removed from Claude's toolset while this skill runs |
| `model` | Override model for this skill (accepts aliases: `fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low` / `normal` / `high` — hint to the model's thinking budget |
| `context: fork` | Run the skill in a forked context (isolated from main conversation) |
| `context: agent` | Run the skill as a full subagent turn |
| `paths` | Glob list — load this skill only when CWD matches |
| `disable-model-invocation` | `true` — skill runs its command without calling the model (pure automation) |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; only callable programmatically |

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`, `displayName`, `defaultEnabled`, `dependencies`.
- Components at the plugin root (not inside `.claude-plugin/`): `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/`, `settings.json`.
- `bin/` executables are added to Bash's `PATH` while the plugin is active.
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep short and reference detail via `@imports` or `.claude/rules/`.
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
