---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-08-02
sources:
  - https://docs.claude.com/en/docs/claude-code/hooks
  - https://docs.claude.com/en/docs/claude-code/settings
  - https://docs.claude.com/en/docs/claude-code/plugins
  - https://docs.claude.com/en/docs/claude-code/slash-commands
  - https://docs.claude.com/en/docs/claude-code/memory
version: 3
---

## Memory files

- `CLAUDE.md` — load order broadest-to-most-specific: managed policy (org-wide, IT-deployed) → user (`~/.claude/CLAUDE.md`) → project (`./CLAUDE.md` or `./.claude/CLAUDE.md`) → local (`./CLAUDE.local.md`). All are concatenated into context, not overridden.
- `CLAUDE.local.md` — personal project notes; gitignored, appended after `CLAUDE.md` at each directory level.
- `AGENTS.md` — not read natively by Claude Code. If the repo needs both, `CLAUDE.md` imports it with `@AGENTS.md`.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence; `/doctor` proposes trims.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 4 hops).
- **Auto memory** (new): Claude writes its own notes to `~/.claude/projects/<project>/memory/`, entry point `MEMORY.md` (first 200 lines / 25KB loaded every session), topic files loaded on demand. On by default; toggle with `autoMemoryEnabled`. This is the plugin's own memory system described elsewhere in this repo's CLAUDE.md.

## Settings

Top-level keys in `.claude/settings.json` (dozens exist; commonly used ones): `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `requiredMaximumVersion`, `enforceAvailableModels`, `availableModels`, `autoMemoryEnabled`, `disableBundledSkills`, `skillOverrides`. Permission rules resolve by precedence **deny > ask > allow** — if a permission matches both an allow and a deny rule, deny wins regardless of list order.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — chain of models to fall back to when the primary is unavailable; capped at 3 entries; does not merge across settings scopes (highest-precedence file supplies the whole chain).
- **`requiredMinimumVersion` / `requiredMaximumVersion`** — managed-settings-only semver bounds; fail open (invalid values are stripped, never block startup).
- **`enforceAvailableModels`** — with a non-empty `availableModels` allowlist, rejects model IDs outside it at startup rather than failing at runtime (v2.1.175+).
- **`sandbox`** — enforce sandbox isolation for tool execution; set via managed settings for org-wide enforcement.

## Hooks

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` | Load context or env vars on session open | Inject current git branch |
| `InstructionsLoaded` | React to what triggered loading (new session, plugin install); inspect `load_reason` | Log which skills were loaded |
| `UserPromptSubmit` | Validate or enrich the user prompt | Block secret patterns |
| `PreToolUse` | Block or gate a tool call | Deny `Bash(rm -rf *)` |
| `PostToolUse` | Lint or log after a tool runs | Auto-run `eslint --fix` after `Edit` |
| `PostToolBatch` | React after a full parallel tool batch completes | Summarize a batch of file reads |
| `SubagentStart` / `SubagentStop` | React to a subagent spawning or finishing | Log delegated work |
| `Notification` | React when Claude Code sends a notification (e.g. background agent needs input) | Forward to Slack |
| `MessageDisplay` | Intercept or annotate a message before it is shown | Inject a reminder banner |
| `PreCompact` / `PostCompact` | Save/restore state around context compaction | Checkpoint session notes |
| `WorktreeCreate` / `WorktreeRemove` | Set up or tear down a worktree | `npm ci` in the new branch |
| `Stop` / `SessionEnd` | Cleanup when a turn or session finishes | Persist session notes, flush metrics |

Around 32 hook events are documented in total (also includes `Setup`, `PermissionRequest`, `PermissionDenied`, `TaskCreated`/`TaskCompleted`, `ConfigChange`, `FileChanged`, `Elicitation`, and more) — see the hooks reference for the full list. Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, command }` entries. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills and custom commands are merged: `.claude/commands/<name>.md` and `.claude/skills/<name>/SKILL.md` both create `/<name>` and behave the same way; skills add supporting files and richer frontmatter.
- Locations: project `.claude/skills/<name>/SKILL.md`, personal `~/.claude/skills/<name>/SKILL.md`, plugin `<plugin>/skills/<name>/SKILL.md`. Nested `.claude/skills/` in subdirectories load on demand and get a directory-qualified name (`apps/web:deploy`) if it collides with the root one.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Standalone skills live-reload automatically when edited (no restart needed). Plugin components (hooks, MCP servers, agents) need `/reload-plugins`.
- `/cd <path>` — move the session to a new working directory (Tab-completes suggestions).
- `/plugin install <name>@<marketplace>`, `/plugin marketplace add <repo>` — install plugins and marketplaces.
- `claude plugin init` — scaffold a new plugin in the current directory (CLI, not a slash command).

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `description` | What the skill does and when to use it; Claude matches on this. Recommended on every skill. |
| `when_to_use` | Extra trigger phrases/examples, appended to `description` |
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `arguments` | Named positional args for `$name` substitution |
| `allowed-tools` / `disallowed-tools` | Grant or remove tools for the turn that invokes this skill |
| `model` | Override model for this skill (accepts aliases: `fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low` / `medium` / `high` / `xhigh` / `max` — thinking-budget hint |
| `context: fork` | Run the skill in a forked subagent context (background by default; `agent:` picks the subagent type) |
| `paths` | Glob list — auto-load this skill only when Claude works with matching files |
| `disable-model-invocation` | `true` — only the user can invoke it, not Claude |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; only Claude can invoke it |

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name` (required — also the skill namespace), `description`, optional `version` (semver; if omitted, the git commit SHA is used as the version), `author`, `homepage`, `repository`.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/` (legacy), `hooks/hooks.json`, `.mcp.json`, `.lsp.json` (LSP servers), `monitors/monitors.json` (background monitors), `bin/` (executables added to `PATH`), `settings.json` (default settings — only `agent` and `subagentStatusLine` keys supported).
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
