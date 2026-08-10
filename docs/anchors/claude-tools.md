---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-08-10
sources:
  - https://docs.claude.com/en/docs/claude-code/hooks
  - https://docs.claude.com/en/docs/claude-code/settings
  - https://docs.claude.com/en/docs/claude-code/plugins
  - https://docs.claude.com/en/docs/claude-code/slash-commands
  - https://docs.claude.com/en/docs/claude-code/memory
version: 3
---

## Memory files

- `CLAUDE.md` — project instructions at `./CLAUDE.md` or `./.claude/CLAUDE.md`; user-level at `~/.claude/CLAUDE.md`; org-wide managed policy at a platform-specific path (e.g. `/etc/claude-code/CLAUDE.md` on Linux). Loaded into every session.
- `CLAUDE.local.md` — personal project notes; gitignored, appended after `CLAUDE.md`.
- `AGENTS.md` — not read natively by Claude Code. If the repo needs both, `CLAUDE.md` imports it with `@AGENTS.md` (or symlinks to it on non-Windows platforms).
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally; nested and symlinked rule directories are supported.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 4 hops).
- **Auto memory** — a separate, Claude-written system distinct from `CLAUDE.md`: notes accumulate at `~/.claude/projects/<project>/memory/`, indexed by `MEMORY.md` (only its first 200 lines / 25KB load each session). Toggle with `autoMemoryEnabled`; browse and edit with `/memory`.

## Settings

Top-level keys in `.claude/settings.json` (non-exhaustive): `permissions`, `env`, `hooks`, `mcpServers`, `model`, `advisorModel`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `requiredMaximumVersion`, `enforceAvailableModels`, `autoMode`, `autoMemoryEnabled`, `autoMemoryDirectory`.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

Permission rules merge across scopes rather than following one flat list. Precedence, highest to lowest: managed policy → CLI flags → `.claude/settings.local.json` → `.claude/settings.json` (project) → `~/.claude/settings.json` (user). Allow/deny/ask rules of the same kind merge across scopes; a `deny` from a more restrictive scope overrides an `allow` from a higher-precedence one.

- **`fallbackModel`** — ordered chain (max 3) tried when the primary model is unavailable or rate-limited, e.g. `["claude-sonnet-5", "claude-haiku-4-5"]`. Does not merge across settings files — the highest-precedence file supplies the whole chain.
- **`requiredMinimumVersion`** / **`requiredMaximumVersion`** — semver bounds; Claude Code refuses to start outside the range. Invalid values are stripped rather than enforced (fails open).
- **`enforceAvailableModels`** — boolean; when `true`, constrains the Default model option to the `availableModels` allowlist instead of only rejecting unavailable IDs at runtime.
- **`autoMode`** — configures the auto-mode permission classifier (`environment`, `allow`, `soft_deny`, `hard_deny` lists; `"$defaults"` inherits the built-ins). `autoMode.classifyAllShell: true` routes all Bash/PowerShell through the classifier.

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI environments or troubleshooting a broken config.

## Hooks

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` | Load context or env vars on session open | Inject current git branch |
| `InstructionsLoaded` | React to what triggered loading (new session, `/reload-skills`, plugin install) | Log which skills were loaded |
| `UserPromptSubmit` | Validate or enrich the user prompt | Block secret patterns |
| `PreToolUse` | Block or gate a tool call | Deny `Bash(rm -rf *)` |
| `PostToolUse` / `PostToolUseFailure` | Lint or log after a tool call succeeds/fails | Auto-run `eslint --fix` after `Edit` |
| `PostToolBatch` | React after a full parallel tool batch resolves | Summarize a batch of file reads |
| `SubagentStart` / `SubagentStop` | Track subagent lifecycle | Log spawned subagent tasks |
| `MessageDisplay` | Intercept or annotate a message before it is shown | Inject a reminder banner |
| `PreCompact` / `PostCompact` | Save/restore state around context compaction | Checkpoint and reload session notes |
| `WorktreeCreate` / `WorktreeRemove` | Set up or clean up a worktree | `npm ci` in the new branch |
| `Stop` / `StopFailure` | Cleanup when a turn ends (normally or via API error) | Persist session notes |
| `SessionEnd` | Release resources or save artifacts | Flush metrics |

Claude Code ships 31 hook events in total (also including `Setup`, `PermissionRequest`, `TaskCreated`/`TaskCompleted`, `DirectoryAdded`, and others) — see the hooks reference for the full list. They live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, command }` entries. Plugins ship hooks in `hooks/hooks.json`; skills and agents can scope hooks to their own lifecycle via a `hooks:` frontmatter field.

## Slash commands

- Skills and custom commands are merged: `.claude/commands/deploy.md` and `.claude/skills/deploy/SKILL.md` both create `/deploy`. Legacy `.claude/commands/*.md` files keep working; skills are recommended going forward since they support supporting files, `paths:` scoping, and richer frontmatter.
- Locations, broadest to narrowest precedence: enterprise (managed) > personal (`~/.claude/skills/`) > project (`.claude/skills/`). Plugin skills are namespaced (`/plugin-name:skill-name`) so they never collide with the others; if a project skill and a command share a name, the skill wins.
- Nested `.claude/skills/` directories in subdirectories load on demand and get a directory-qualified name (`apps/web:deploy`) if it collides with the root skill.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), `$name` for named args declared via `arguments:` frontmatter.
- `/reload-skills` — hot-reload skill/command files without restarting the session.
- `/cd <path>` — change the working directory for the current session.
- `/plugin list` — list installed plugins and their status.
- `claude plugin init` — scaffold a new plugin in the current directory (CLI, not a slash command).
- `claude agents` — list all available named subagents (CLI).
- Bundled skills (`/doctor`, `/code-review`, `/batch`, `/debug`, `/loop`, `/claude-api`, …) ship with Claude Code and are prompt-based; disable them with the `disableBundledSkills` setting.

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `description` / `when_to_use` | What the skill does and when to use it (recommended on every skill) |
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `arguments` | Named positional arguments for `$name` substitution |
| `allowed-tools` / `disallowed-tools` | Per-invocation tool allow/deny list; clears on the next message |
| `model` | Override model for this skill (accepts aliases: `fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low` / `medium` / `high` / `xhigh` / `max` — thinking-budget hint |
| `context: fork` | Run the skill in a forked subagent context (`agent:` picks the subagent type; `background: false` waits for it) |
| `paths` | Glob list — load this skill only when Claude is working with matching files |
| `disable-model-invocation` / `user-invocable` | `true`/`false` — restrict a skill to user-only or Claude-only invocation |
| `hooks` | Hooks scoped to this skill's own lifecycle |

Keep `SKILL.md` itself under 500 lines; push detail into supporting files the skill references on demand.

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `description`, optional `version` (semver — updates only ship when bumped), `author` (string or `{name, email, url}`), `homepage`, `repository`, `license`, `displayName` (marketplace/`/plugin list` label), `defaultEnabled` (activates without opt-in), `dependencies` (other required plugin names).
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `settings.json`, `bin/` (executables added to the Bash tool's `PATH` while the plugin is enabled).
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits. `claude plugin validate <dir>` checks a plugin before submitting it to a marketplace.

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
