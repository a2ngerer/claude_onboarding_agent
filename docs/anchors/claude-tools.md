---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-04-24
sources:
  - https://docs.claude.com/en/docs/claude-code/hooks
  - https://docs.claude.com/en/docs/claude-code/settings
  - https://docs.claude.com/en/docs/claude-code/plugins
  - https://docs.claude.com/en/docs/claude-code/slash-commands
  - https://docs.claude.com/en/docs/claude-code/memory
version: 2
---

## Memory files

- `CLAUDE.md` — project instructions at `./CLAUDE.md` or `./.claude/CLAUDE.md`; user-level at `~/.claude/CLAUDE.md`; org-managed at `/etc/claude-code/CLAUDE.md`. Loaded into every session.
- `CLAUDE.local.md` — personal project notes; gitignored, appended after `CLAUDE.md`.
- `AGENTS.md` — not read natively by Claude Code. Import it from `CLAUDE.md` with `@AGENTS.md` if the repo needs both.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- Block-level HTML comments (`<!-- ... -->`) in `CLAUDE.md` are stripped before injection (saves tokens).
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- **Auto memory** — Claude accumulates learnings across sessions at `~/.claude/projects/<project>/memory/MEMORY.md`. Requires v2.1.59+. Toggle via `/memory` or `autoMemoryEnabled` setting.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 5).

## Settings

Top-level keys in `.claude/settings.json` include: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `autoMemoryEnabled`, `autoMemoryDirectory`, `attribution`, `alwaysThinkingEnabled`, `effortLevel`, `statusLine`, `language`, `prUrlTemplate`, `voice`, `worktree`, and many others. Permission rules evaluate in order `deny → ask → allow`; first match wins. Array keys (allow/deny lists) merge across scopes rather than replace.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

## Hooks

Five handler types: `command` (shell script), `http` (POST to URL), `mcp_tool` (MCP server tool), `prompt` (single-turn LLM), `agent` (subagent). `PostToolUse` and `PostToolUseFailure` inputs now include `duration_ms`.

| Event | Typical use |
|---|---|
| `SessionStart` / `SessionEnd` | Load context on open; release resources on close |
| `UserPromptSubmit` | Validate or enrich the user prompt before Claude sees it |
| `UserPromptExpansion` | When a slash command expands into a prompt |
| `PreToolUse` | Block or gate a tool call |
| `PermissionRequest` / `PermissionDenied` | React to permission dialogs or auto-mode denials |
| `PostToolUse` / `PostToolUseFailure` | Lint or log after a tool runs (includes `duration_ms`) |
| `PostToolBatch` | After all parallel tool calls in a batch resolve |
| `InstructionsLoaded` | When CLAUDE.md or `.claude/rules/*.md` loads |
| `ConfigChange` | When a config file changes during session |
| `SubagentStart` / `SubagentStop` | When a subagent spawns or finishes |
| `PreCompact` / `PostCompact` | Before/after context compaction |
| `FileChanged` | When a watched file changes on disk |
| `WorktreeCreate` / `WorktreeRemove` | Worktree lifecycle |
| `Elicitation` / `ElicitationResult` | MCP server user-input requests |
| `Stop` / `StopFailure` | Claude finishes a turn or ends due to API error |
| `Notification` | Claude Code sends a UI notification |

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and `hooks` list. Plugins ship hooks in `hooks/hooks.json`.

## Skills (slash commands)

Custom commands and skills are unified: `.claude/commands/deploy.md` and `.claude/skills/deploy/SKILL.md` both create `/deploy`. Skills (`SKILL.md`) are preferred for new work — they support supporting files and richer frontmatter.

Key frontmatter fields:
- `description` — when to use the skill; drives automatic model-invocation decisions
- `disable-model-invocation: true` — user-only invocation (hides skill from Claude's context entirely)
- `user-invocable: false` — model-only; hides from the `/` menu
- `allowed-tools` — pre-approve specific tools while the skill is active
- `context: fork` — run the skill in an isolated subagent context
- `paths` — glob patterns that limit when the skill activates automatically
- String substitutions: `$ARGUMENTS`, `$N` (positional), `${CLAUDE_SESSION_ID}`, `${CLAUDE_SKILL_DIR}`

Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>`. Bundled skills include `/simplify`, `/debug`, `/batch`, `/loop`, `/claude-api`.

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`.
- Components at plugin root (not inside `.claude-plugin/`): `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/`, `settings.json`.
- `bin/` executables are added to the Bash tool's `PATH` while the plugin is enabled.
- `monitors/monitors.json` — background watchers; each stdout line is delivered to Claude as a notification.
- Test locally with `claude --plugin-dir ./my-plugin`; `/reload-plugins` picks up edits without restart.
- Version every release; users update through the marketplace.

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands, deny reads of secrets.
- Use `paths:` frontmatter in `.claude/rules/` to load rules only for matching file types (saves context).
- Pin plugin versions in team repos; run `/reload-plugins` after edits.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md`.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
