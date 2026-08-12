---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-08-12
sources:
  - https://docs.claude.com/en/docs/claude-code/hooks
  - https://docs.claude.com/en/docs/claude-code/settings
  - https://docs.claude.com/en/docs/claude-code/plugins
  - https://docs.claude.com/en/docs/claude-code/slash-commands
  - https://docs.claude.com/en/docs/claude-code/memory
version: 3
---

## Memory files

- `CLAUDE.md` — project instructions at `./CLAUDE.md` or `./.claude/CLAUDE.md`; user-level at `~/.claude/CLAUDE.md`; org-wide managed policy files also exist (e.g. `/etc/claude-code/CLAUDE.md` on Linux). Loaded into every session.
- `CLAUDE.local.md` — personal project notes; gitignored, appended after `CLAUDE.md`.
- `AGENTS.md` — not read natively by Claude Code. Import it with `@AGENTS.md` in `CLAUDE.md`, or symlink `CLAUDE.md -> AGENTS.md` (non-Windows) if no Claude-specific content is needed.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 4 hops).
- **Auto memory** (separate mechanism): Claude self-writes learnings per repo at `~/.claude/projects/<project>/memory/`, indexed by `MEMORY.md` (first 200 lines / 25KB load every session) plus on-demand topic files. You write CLAUDE.md; Claude writes auto memory. Toggle with `autoMemoryEnabled`; browse/edit via `/memory`.

## Settings

Top-level keys in `.claude/settings.json` include `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `fallbackModel`, `requiredMinimumVersion`, `enforceAvailableModels`, `workflowSizeGuideline`, `crossSessionInbound`.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

- **`fallbackModel`** — ordered list (max 3) to try when the primary model is unavailable or rate-limited; does not merge across settings scopes — the highest-precedence file supplies the whole chain.
- **`requiredMinimumVersion`** — semver string; Claude Code refuses to run if the installed version is older.
- **`enforceAvailableModels`** — boolean (v2.1.175+); when `true`, folds the Default model option into the `availableModels` allowlist instead of only rejecting explicit off-list IDs.
- **`sandbox`** (managed settings) — credential masking (regex `extract` + `mode: "mask"`, or `"deny"`) plus filesystem/network isolation.
- **`workflowSizeGuideline`** — `"small"` / `"medium"` / `"large"`; advises Claude on Workflow-tool fan-out scope.
- **`crossSessionInbound`** — `"accept"` / `"hold"` / `"refuse"` (v2.1.224+); controls inbound cross-session `SendMessage` delivery.

**Permission evaluation:** rules merge across scopes (managed, CLI args, local, project, user all combine) rather than the highest scope overriding lower ones. Within the merged set: any `deny` match blocks the action regardless of `allow`; a matching `allow` auto-approves; otherwise Claude asks.

**Safe mode:** Set `CLAUDE_CODE_SAFE_MODE=1` to disable CLAUDE.md loading, plugins, skills, hooks, and MCP servers. Useful for security-sensitive CI or troubleshooting a broken config.

## Hooks

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` | Load context or env vars on session open | Inject current git branch |
| `InstructionsLoaded` | React to what triggered loading (new session, `/reload-skills`, plugin install) | Log which skills were loaded |
| `UserPromptSubmit` | Validate or enrich the user prompt | Block secret patterns |
| `PreToolUse` / `PostToolUse` | Gate a tool call / lint or log after it runs | Deny `Bash(rm -rf *)`; auto-run `eslint --fix` after `Edit` |
| `PostToolBatch` | React after a full parallel tool batch completes | Summarize a batch of file reads |
| `Notification` | React to permission prompts, auth events, background-agent status | Forward `agent_needs_input`/`agent_completed` |
| `DirectoryAdded` | Fires after `/add-dir` or SDK `register_repo_root` mid-session | Load extra context for the new directory |
| `MessageDisplay` | Intercept or annotate a message before it is shown | Inject a reminder banner |
| `PreCompact` / `PostCompact` | Save/reload state around context compaction | Checkpoint or reload session notes |
| `WorktreeCreate` / `WorktreeRemove` | Set up or clean a worktree | `npm ci` in the new branch |
| `SubagentStart` / `SubagentStop` | React to subagent lifecycle | Log dispatch/completion |
| `Stop` / `SessionEnd` | Cleanup when a turn / session finishes | Persist session notes, flush metrics |

Curated subset — the full catalog also covers failure variants, task-management events (`TaskCreated`, `TaskCompleted`), and MCP elicitation events. Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and `{ type, command }` entries. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills and custom commands are the same mechanism: `.claude/commands/deploy.md` and `.claude/skills/deploy/SKILL.md` both create `/deploy`. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/…/`$ARGUMENTS[N]` (positional), or named via `arguments:` frontmatter (`$name`).
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- `/reload-skills`, `/reload-plugins` — hot-reload skill/command/plugin files without restarting.
- `/cd <path>` — change the working directory for the current session.
- `/subtask` runs a forked subagent in-session; `/fork` copies the whole conversation into a new background session.
- `/plugin list` — list installed plugins and their status; `claude plugin init` scaffolds a new plugin (CLI).

## SKILL.md frontmatter fields

| Field | Purpose |
|---|---|
| `argument-hint` | Short placeholder shown in autocomplete (e.g. `[branch]`) |
| `arguments` | Named positional arguments (string or YAML list) for `$name` substitution |
| `allowed-tools` | Comma-separated tool whitelist for this skill's invocation |
| `model` | Override model for this skill (`fable`, `opus`, `sonnet`, `haiku`, `inherit`) |
| `effort` | `low` / `normal` / `high` — hint to the model's thinking budget |
| `context: fork` / `context: agent` | Run in a forked context / as a full subagent turn |
| `paths` | Glob list — load this skill only when CWD matches |
| `disable-model-invocation` | `true` — skill runs only via explicit `/name`, never auto-invoked |
| `user-invocable` | `false` — hides the skill from `/` autocomplete; callable only programmatically |

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`, `displayName`, `defaultEnabled`, `dependencies`.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/` (executables added to Bash's `PATH`), `settings.json` (only `agent` and `subagentStatusLine` keys are supported there).
- Local testing: `--plugin-dir` accepts a directory or `.zip`; `--plugin-url` fetches and loads a hosted `.zip` for that session only.
- An `archive` marketplace source installs a plugin from a zip over HTTPS without git/npm, optionally SHA-256-pinned. `strictKnownMarketplaces`/`blockedMarketplaces` accept `"owner/*"` wildcards for GitHub org-wide rules.
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands, deny reads of secrets (`Read(./.env)`).
- Pin plugin versions in team repos; run `/reload-plugins` after edits instead of restarting.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly — import it from `CLAUDE.md` with `@AGENTS.md` or symlink it.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md`.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
