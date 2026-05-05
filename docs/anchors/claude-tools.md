---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-05-05
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
- For modular rules, use `.claude/rules/*.md`; add optional `paths:` frontmatter (YAML glob list) to load a rule only when Claude works with matching files. Rules without `paths:` load unconditionally.
- Auto memory: Claude writes `~/.claude/projects/<project>/memory/MEMORY.md` automatically. First 200 lines load every session; topic files load on demand. Toggle with `autoMemoryEnabled` in settings.
- Imports: `@path/to/file` inside `CLAUDE.md` pulls another file into context at launch (max depth 5).

## Settings

Top-level keys in `.claude/settings.json`: `permissions`, `env`, `hooks`, `mcpServers`, `model`, `agent`, `outputStyle`, `sandbox`, `claudeMdExcludes`, `effortLevel`, `autoMemoryEnabled`, `attribution`, `worktree`. Permission rules evaluate in order `deny → ask → allow`; first match wins. Arrays merge across scopes (user → project → local → managed).

```json
{
  "permissions": { "allow": ["Bash(npm run test *)"], "deny": ["Read(./.env)"] },
  "sandbox": { "network": { "deniedDomains": ["sensitive.internal.com"] } },
  "effortLevel": "high"
}
```

## Hooks

| Event | Typical use | Example |
|---|---|---|
| `SessionStart` | Load context or env vars on session open | Inject current git branch |
| `UserPromptSubmit` | Validate or enrich the user prompt | Block secret patterns |
| `PreToolUse` | Block or gate a tool call | Deny `Bash(rm -rf *)` |
| `PostToolUse` | Lint, log, or replace tool output | Auto-run `eslint --fix` after `Edit` |
| `PermissionDenied` | React to auto-mode denials | Log or retry with narrower scope |
| `PreCompact` | Before context compaction | Save summary to disk (block with exit 2) |
| `PostToolBatch` | After a parallel tool batch resolves | Aggregate lint results |
| `Stop` | Cleanup when Claude finishes a turn | Persist session notes |
| `SessionEnd` | Release resources or save artifacts | Flush metrics |

Handler types: `command` (shell), `http` (POST endpoint), `mcp_tool` (call an MCP tool directly), `prompt` (single-turn LLM eval), `agent` (subagent with tools). Add an `if` field (permission-rule syntax, e.g. `"Bash(git *)"`) to fire a handler conditionally. `PostToolUse` handlers can set `hookSpecificOutput.updatedToolOutput` to replace the tool result Claude sees. `PreToolUse` supports `permissionDecision: "defer"` to pause headless sessions for human review. Hook payloads include `duration_ms`.

Hooks live in `.claude/settings.json` under `hooks.<EventName>[]` with a `matcher` and a list of `{ type, command }` entries. Plugins ship hooks in `hooks/hooks.json`.

## Slash commands

- Skills and custom commands are merged. Project skills live at `.claude/skills/<name>/SKILL.md`; user skills at `~/.claude/skills/<name>/SKILL.md`. Legacy `.claude/commands/*.md` files still work.
- Plugin-provided skills are namespaced: `/<plugin-name>:<skill-name>` to prevent collisions.
- Key frontmatter fields: `disable-model-invocation: true` (manual-invoke only), `user-invocable: false` (hide from `/` menu), `context: fork` (run in isolated subagent), `paths:` (activate only for matching file globs), `allowed-tools:`, `effort:`, `model:`.
- Arguments: `$ARGUMENTS` (full string), `$0`/`$1`/… or `$ARGUMENTS[N]` (positional), named args via `arguments:` frontmatter. Also `${CLAUDE_SKILL_DIR}` (skill folder path), `${CLAUDE_EFFORT}` (active effort level), `${CLAUDE_SESSION_ID}`.
- Name slugs: lowercase letters, digits, hyphens only; max 64 chars.

## Plugins

- Manifest: `.claude-plugin/plugin.json` with `name`, `version` (semver), `description`, optional `author`, `homepage`, `repository`.
- Components at plugin root, not inside `.claude-plugin/`: `skills/`, `agents/`, `commands/`, `hooks/hooks.json`, `.mcp.json`, `.lsp.json`, `monitors/monitors.json` (background watch loops), `bin/` (executables added to Bash `PATH`), `settings.json`.
- Version every release; users update through the marketplace. `/reload-plugins` picks up local edits. `claude plugin prune` removes orphaned dependencies.

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
