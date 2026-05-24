---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-05-24
sources:
  - https://docs.claude.com/en/docs/claude-code/hooks
  - https://docs.claude.com/en/docs/claude-code/settings
  - https://docs.claude.com/en/docs/claude-code/plugins
  - https://docs.claude.com/en/docs/claude-code/slash-commands
  - https://docs.claude.com/en/docs/claude-code/memory
version: 2
---

## Memory files

- `CLAUDE.md` — project instructions at `./CLAUDE.md` or `./.claude/CLAUDE.md`; user-level at `~/.claude/CLAUDE.md`. Loaded into every session.
- `CLAUDE.local.md` — personal project notes; gitignored, appended after `CLAUDE.md`.
- `AGENTS.md` — not read natively by Claude Code. Import it from `CLAUDE.md` with `@AGENTS.md`.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 5).
- HTML comments (`<!-- ... -->`) in `CLAUDE.md` are stripped before injection — use them for maintainer notes without spending tokens.

## Auto memory

Claude writes its own notes to `~/.claude/projects/<project>/memory/MEMORY.md` (first 200 lines or 25 KB loaded per session). Toggle with `autoMemoryEnabled` in settings or `/memory` command. Set `autoMemoryDirectory` to relocate. Subagents can maintain their own auto memory.

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `effortLevel`, `worktree`, `skillOverrides`, `parentSettingsBehavior`, `autoMemoryEnabled`, `autoMemoryDirectory`. Permission rules evaluate `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

New settings (post-April 2026):
- `effortLevel` — persist effort level (`low`/`medium`/`high`/`xhigh`/`max`) across sessions.
- `worktree.baseRef` — `"fresh"` (branch from `origin/<default>`) or `"head"` (local HEAD).
- `skillOverrides` — per-skill visibility (`on`/`name-only`/`user-invocable-only`/`off`).
- `parentSettingsBehavior` — SDK managed-settings merge policy (`"first-wins"` | `"merge"`).
- `sandbox.bwrapPath` / `sandbox.socatPath` — custom binary paths for Linux/WSL (managed-only).

## Hooks

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and `{ type, command, args? }` entries. The `args: string[]` exec form prevents shell quoting issues. Available env var in hook commands: `$CLAUDE_EFFORT`.

| Group | Events |
|---|---|
| Session | `SessionStart`, `Setup`, `SessionEnd` |
| Turn | `UserPromptSubmit`, `UserPromptExpansion`, `Stop`, `StopFailure` |
| Tools | `PreToolUse`, `PermissionRequest`, `PermissionDenied`, `PostToolUse`, `PostToolUseFailure`, `PostToolBatch` |
| Background | `SubagentStart`, `SubagentStop`, `InstructionsLoaded`, `CwdChanged`, `FileChanged`, `WorktreeCreate`, `WorktreeRemove`, `PreCompact`, `PostCompact`, `Notification`, `TeammateIdle` |

Plugins ship hooks in `hooks/hooks.json`. Hook handler `type` options: `command`, `http`, `mcp_tool`, `prompt`, `agent`.

## Slash commands

- Skills live at `.claude/skills/<name>/SKILL.md` (project) or `~/.claude/skills/<name>/SKILL.md` (user). Legacy `.claude/commands/*.md` files still work.
- Plugin skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… (positional), named args via `arguments:` frontmatter.
- Bundled skills include `/code-review` (correctness bugs at chosen effort, optional inline PR comments), `/goal` (completion condition with live token overlay), `/ultrareview` (cloud-based multi-agent review), `/less-permission-prompts` (scan transcripts and propose read-only allowlist).

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`.
- Components at plugin root: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `settings.json`.
- Dependency enforcement: `claude plugin disable` refuses when another plugin depends on it; `enable` auto-enables transitive dependencies.
- `claude plugin prune` — remove orphaned auto-installed dependencies.
- `claude plugin tag` — create release git tags with version validation.
- `blockedMarketplaces` / `strictKnownMarketplaces` enforced on install, update, and auto-update.

## Recommendations

- Keep `CLAUDE.md` short; reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything invoked only sometimes.
- Use a `PostToolUse` hook to run linters after `Write`/`Edit`; use the `args:` exec form to avoid path quoting bugs.
- Scope permissions explicitly: allowlist safe commands, deny reads of secrets.
- Pin plugin versions in team repos; run `/reload-plugins` after edits.

## Deprecated patterns

- Do not stuff templates or multi-step procedures into `CLAUDE.md` — move them to `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md`.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
