---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-05-21
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
- `AGENTS.md` — not read natively by Claude Code. If the repo needs both, `CLAUDE.md` imports it with `@AGENTS.md`.
- Size target: keep each `CLAUDE.md` under ~200 lines. Longer files reduce adherence.
- For modular rules, use `.claude/rules/*.md` with optional `paths:` frontmatter to scope by glob. Rules without `paths:` load unconditionally.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 5).

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `language`, `effortLevel`, `tui`, `autoMemoryEnabled`, `autoMemoryDirectory`, `plansDirectory`. Permission rules evaluate in order `deny → ask → allow`; first match wins. Notable recent additions: `worktree.baseRef` (`"fresh"` | `"head"`, v2.1.133), `worktree.bgIsolation` (`"worktree"` | `"none"`, v2.1.143), `sandbox.bwrapPath`/`sandbox.socatPath` (managed only, v2.1.135).

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

## Hooks

| Event | Typical use |
|---|---|
| `SessionStart` | Load context or env vars on session open |
| `Setup` | One-time init or maintenance tasks (`--init-only`) |
| `UserPromptSubmit` | Validate or enrich the user prompt |
| `UserPromptExpansion` | Intercept or gate slash command expansion |
| `PreToolUse` | Block or gate a tool call |
| `PostToolUse` | Lint or log after a tool runs |
| `PostToolBatch` | React after a complete batch of parallel tool calls |
| `SubagentStart` / `SubagentStop` | Observe or gate subagent lifecycle |
| `FileChanged` | React to watched file changes (register paths via `watchPaths`) |
| `WorktreeCreate` / `WorktreeRemove` | Observe worktree lifecycle |
| `PreCompact` / `PostCompact` | Hook around context compaction |
| `Notification` | Observe permission prompts and idle alerts |
| `Stop` | Cleanup when Claude finishes a turn |
| `SessionEnd` | Release resources or save artifacts |

New hook fields (2025–2026): `args: string[]` (exec form — avoids shell quoting issues, v2.1.139), `terminalSequence` (OSC 0/1/2/9/99/777 for desktop notifications, v2.1.141), `effort.level` in hook input (`$CLAUDE_EFFORT` env var, v2.1.133), `once: true` (run once per session), `continueOnBlock: true` on `PostToolUse` (feeds rejection back to Claude). `SubagentStop` input includes `background_tasks` and `session_crons` fields (v2.1.145).

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, command }` entries. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- Key built-in changes: `/code-review` replaced `/simplify` (v2.1.146, supports effort level arg); `/usage-credits` replaced `/extra-usage` (v2.1.144); new `/goal` sets completion condition (v2.1.139); new `/ultrareview` runs cloud multi-agent code review (v2.1.111).

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author` (object), `homepage`, `repository`.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `bin/`, `settings.json`.
- `monitors/monitors.json` — background monitors that stream stdout lines to Claude as notifications during the session.
- `bin/` — executables added to the Bash tool's `PATH` while the plugin is enabled.
- `settings.json` at plugin root — only `agent` and `subagentStatusLine` keys currently supported.
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
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md`.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
- Do not use `/simplify` (renamed `/code-review`) or `/extra-usage` (renamed `/usage-credits`).
