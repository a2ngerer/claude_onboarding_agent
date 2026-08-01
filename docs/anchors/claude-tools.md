---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-08-01
sources:
  - https://docs.claude.com/en/docs/claude-code/hooks
  - https://docs.claude.com/en/docs/claude-code/settings
  - https://docs.claude.com/en/docs/claude-code/plugins
  - https://docs.claude.com/en/docs/claude-code/slash-commands
  - https://docs.claude.com/en/docs/claude-code/memory
version: 3
---

## Memory files

- `CLAUDE.md` — project instructions at `./CLAUDE.md` or `./.claude/CLAUDE.md`; user-level at `~/.claude/CLAUDE.md`; managed policy at `/etc/claude-code/CLAUDE.md` (Linux) or the platform equivalent. Loaded into every session.
- `CLAUDE.local.md` — personal project notes; gitignored, appended after `CLAUDE.md`.
- `AGENTS.md` — not read natively by Claude Code. If the repo needs both, `CLAUDE.md` imports it with `@AGENTS.md`.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 4).
- **Auto memory** (new) — separate from `CLAUDE.md`: Claude writes its own notes to `~/.claude/projects/<project>/memory/MEMORY.md` (+ topic files) based on corrections and preferences it observes. On by default; toggle with `autoMemoryEnabled`. `MEMORY.md` loads in full each session (first 200 lines / 25KB); topic files load on demand.

## Settings

Notable top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `enforceAvailableModels`, `availableModels`, `autoMemoryEnabled`, `disableBundledSkills`, `workflowSizeGuideline`, `skillOverrides`. Permission rules within `permissions` evaluate `deny → ask → allow`, first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **Scope precedence** (highest to lowest): Managed policy → CLI args → `.claude/settings.local.json` → `.claude/settings.json` → `~/.claude/settings.json`. Permission rules merge across scopes rather than override.
- **`fallbackModel`** — model (or ordered list) to use when the primary `model` is unavailable or rate-limited.
- **`requiredMinimumVersion`** — semver string; Claude Code refuses to run if the installed version is older.
- **`enforceAvailableModels`** / **`availableModels`** — restrict which model IDs/aliases users can select; rejects disallowed picks at startup.
- **`sandbox.network.strictAllowlist`** — deny non-allowlisted hosts for sandboxed commands without prompting.

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` in the environment to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI environments or troubleshooting a broken config.

## Hooks

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` | Load context or env vars on session open | Inject current git branch |
| `InstructionsLoaded` | React to what triggered loading (new session, plugin install); inspect `load_reason` | Log which skills were loaded |
| `UserPromptSubmit` | Validate or enrich the user prompt | Block secret patterns |
| `PreToolUse` | Block or gate a tool call | Deny `Bash(rm -rf *)` |
| `PostToolUse` | Lint or log after a tool runs | Auto-run `eslint --fix` after `Edit` |
| `PostToolBatch` | React after a full parallel tool batch completes | Summarize a batch of file reads |
| `PermissionRequest` | Auto-approve or gate a pending permission decision | Approve safe read-only commands |
| `SubagentStart` / `SubagentStop` | React to subagent lifecycle | Log delegated task start/end |
| `Notification` | React to background-agent notifications | `agent_needs_input` / `agent_completed` |
| `DirectoryAdded` | Fires after `/add-dir` registers a new working directory mid-session | Load extra env for the new dir |
| `MessageDisplay` | Intercept or annotate a message before it is shown | Inject a reminder banner |
| `PreCompact` / `PostCompact` | Save/restore state around context compaction | Checkpoint and reload session notes |
| `WorktreeCreate` / `WorktreeRemove` | Set up or clean up a worktree | `npm ci` in the new branch |
| `Stop` / `SessionEnd` | Cleanup when a turn or session finishes | Persist session notes, flush metrics |

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, command }` entries (`type` also accepts `http`, `mcp_tool`, `prompt`, `agent`). Plugins ship hooks in `hooks/hooks.json`. This is a subset — more granular events exist (`PostToolUseFailure`, `PermissionDenied`, `TaskCreated`/`TaskCompleted`, `FileChanged`, `CwdChanged`, `ConfigChange`, `Elicitation`/`ElicitationResult`, `TeammateIdle`); see the docs for the full reference.

## Slash commands

- Custom commands merged into skills: `.claude/commands/x.md` and `.claude/skills/x/SKILL.md` both create `/x` and behave the same; skills add supporting-file directories and richer frontmatter. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), `$name` (named, via `arguments:` frontmatter).
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- Claude Code watches skill directories and picks up `SKILL.md` edits live within the session — no reload command needed. `/reload-plugins` is still required for plugin-level changes (hooks, MCP servers, agents, output styles).
- `/cd <path>` — change the working directory for the current session.
- `/plugin list` — list installed plugins and their status.
- `claude plugin init` — scaffold a lightweight skill under `~/.claude/skills/<name>/` that auto-loads without a marketplace.
- `claude agents` — list all available named subagents (CLI).
- Bundled skills ship in every session (`/doctor`, `/code-review`, `/debug`, `/loop`, `/run`, `/verify`, …); disable with `disableBundledSkills`.

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `description` | What the skill does and when to use it — the primary signal Claude uses to auto-invoke |
| `when_to_use` | Extra trigger phrases/examples, appended to `description` |
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `arguments` | Named positional args for `$name` substitution |
| `allowed-tools` / `disallowed-tools` | Tool whitelist / removal for the invoking turn |
| `model` | Override model for this skill (accepts aliases: `fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low` / `medium` / `high` / `xhigh` / `max` — thinking-budget hint |
| `context: fork` | Run the skill in a forked subagent context; pair with `agent:` to pick the subagent type |
| `background` | With `context: fork`, run in background (default) or `false` to block for the result |
| `paths` | Glob list — auto-load this skill only when CWD/files match |
| `disable-model-invocation` | `true` — skill only runs when a user types it, never auto-invoked |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; only Claude can invoke it |

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `description`, optional `version` (semver — if omitted, the git commit SHA is used as the version on git-distributed plugins), `author`, `homepage`, `repository`, `displayName`, `defaultEnabled`, `dependencies`.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/` (executables added to `PATH`), `settings.json` (default settings — currently only `agent` and `subagentStatusLine` keys are honored).
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits (skills, agents, hooks, MCP, LSP).

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
- Pin plugin versions in team repos; run `/reload-plugins` after non-skill edits (skills reload live automatically).
- Namespace plugin skills; never rely on a collision-prone flat name.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md` so supporting files and frontmatter are available.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
