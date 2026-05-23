---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-05-23
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

Top-level keys in `.claude/settings.json` (selected): `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `effortLevel`, `cleanupPeriodDays`, `worktree`. Permission rules evaluate in order `deny → ask → allow`; first match wins.

```json
{ "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] } }
```

Notable settings added in 2026:
- `effortLevel` — persist effort level: `"low"`, `"medium"`, `"high"`, `"xhigh"`
- `worktree.bgIsolation` — background session isolation: `"worktree"` (default) or `"none"` for direct working-copy edits without `EnterWorktree`
- `worktree.baseRef` — worktree branch source: `"fresh"` (from `origin/<default>`) or `"head"` (from local HEAD)
- `cleanupPeriodDays` — retention sweep for `~/.claude/tasks/`, `shell-snapshots/`, `backups/` (default: 30)
- `alwaysThinkingEnabled` — enable extended thinking by default

## Hooks

Hook handler types: `command`, `http`, `mcp_tool`, `prompt`, `agent`. Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of handler entries. Plugins ship hooks in `hooks/hooks.json`.

| Event | Typical use |
|---|---|
| `SessionStart` | Load context or env vars on session open |
| `Setup` | One-time dependency installation (`--init-only`, `--init`, `--maintenance`) |
| `UserPromptSubmit` | Validate or enrich the user prompt |
| `UserPromptExpansion` | Block or validate skill/command expansion |
| `PreToolUse` | Block or gate a tool call |
| `PermissionRequest` | Auto-approve or deny permission dialogs |
| `PermissionDenied` | React to auto-mode denials, allow retries |
| `PostToolUse` | Lint or log after a tool runs; `continueOnBlock` feeds rejection reason back to Claude |
| `PostToolUseFailure` | Handle failures, add debugging context |
| `PostToolBatch` | Process batch results before next model call |
| `SubagentStart` / `SubagentStop` | Initialize or clean up subagent lifecycle |
| `Stop` | Cleanup when Claude finishes a turn |
| `CwdChanged` | Reactive environment management (direnv, nvm) |
| `PreCompact` / `PostCompact` | Validate or react to context compaction |
| `WorktreeCreate` / `WorktreeRemove` | Custom worktree creation/cleanup logic |
| `Elicitation` / `ElicitationResult` | Accept/decline/override MCP input dialogs |
| `SessionEnd` | Release resources or save artifacts |

New hook output fields: `terminalSequence` (desktop notifications/bells without `/dev/tty`); `args: string[]` exec form (no shell tokenization, avoids quoting issues); `duration_ms` in `PostToolUse` inputs (tool execution time, excluding permission prompts).

## Slash commands

- Skills and custom commands are merged. Project skills at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. A root-level `SKILL.md` without a `skills/` subdirectory is also surfaced.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… (positional), named args via `arguments:` frontmatter.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.
- New built-in commands: `/goal` (work until a stated condition is met), `/code-review` (correctness bugs at chosen effort; `--comment` posts inline PR comments), `/usage` (merged `/cost` and `/stats`).

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`.
- Components sit at the plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, `.lsp.json`, `monitors/`, `settings.json`.
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits.
- `claude plugin prune` removes orphaned auto-installed dependencies; `claude plugin tag` creates release git tags with version validation.
- Plugins can now declare LSP servers (shown in `/plugin` details).

## Recommendations

- Point-don't-dump in `CLAUDE.md`: keep it short and reference detail files via `@imports` or `.claude/rules/`.
- Prefer skills (`SKILL.md`) over fat `CLAUDE.md` sections for anything longer than a few bullets or invoked only sometimes.
- Use a `PostToolUse` hook to run linters or formatters after `Write`/`Edit` instead of instructing Claude to do it.
- Scope permissions explicitly: allowlist safe commands (`Bash(npm run test *)`), deny reads of secrets (`Read(./.env)`).
- Pin plugin versions in team repos; run `/reload-plugins` after edits instead of restarting.

## Deprecated patterns

- Do not stuff templates, multi-step procedures, or tool references into `CLAUDE.md` — move them into `skills/` or `.claude/rules/`.
- Do not place `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`; only `plugin.json` belongs there.
- Do not rely on `AGENTS.md` being read directly by Claude Code — import it from `CLAUDE.md` with `@AGENTS.md`.
- Do not use legacy `.claude/commands/*.md` for new functionality — prefer `skills/<name>/SKILL.md`.
- Do not silently overwrite an existing `CLAUDE.md` — extend with a delimited, attributed section.
