---
name: subagents
description: Subagent orchestration patterns for Claude Code — when to delegate, how to structure, and what to avoid
last_updated: 2026-05-02
sources:
  - https://docs.claude.com/en/docs/claude-code/sub-agents
  - https://www.anthropic.com/engineering/multi-agent-research-system
  - https://www.anthropic.com/engineering/claude-code-best-practices
version: 2
---

## When to use a subagent

- A side task would flood the main context with file contents, search hits, or logs that are not referenced again.
- The work needs a different tool-set, a different model (e.g. Haiku for cheap scans), or a separate permission profile.
- The task is breadth-first: three or more independent queries that can run in parallel.
- Verification after implementation — a fresh context is less biased toward the code it just wrote.
- A repeated worker with the same instructions — formalize it as a named subagent under `.claude/agents/`.

## Built-in subagents

Claude Code ships three built-in subagents that Claude invokes automatically:

| Name | Model | Tools | When used |
|---|---|---|---|
| Explore | Haiku | Read-only | Codebase search and file discovery |
| Plan | Inherits | Read-only | Research phase inside plan mode |
| General-purpose | Inherits | All | Complex multi-step tasks requiring both read and write |

Subagents cannot spawn other subagents. For multiple agents communicating across independent sessions, see `agent-teams`.

## Creating named subagents

**Interactive:** `/agents` opens a tabbed UI to create, edit, and delete subagents with guided setup or Claude generation. `claude agents` (CLI, no session) lists all configured agents.

**Manual files:** Markdown with YAML frontmatter stored at:
- `.claude/agents/<name>.md` — project scope (check into git for team sharing)
- `~/.claude/agents/<name>.md` — user scope (available in all projects)

Named subagents appear in `@` mention typeahead and are selected by Claude via their `description:` field.

**Session-only:** pass `--agents '{"<name>": {...}}'` when launching Claude Code; not saved to disk.

## Key frontmatter fields

`description`, `model`, `tools`, `disallowedTools`, `permissionMode`, `maxTurns`, `isolation`, `memory`, `skills`, `hooks`, `mcpServers`, `effort`, `color`, `background`, `initialPrompt`.

- `isolation: "worktree"` — run in an isolated git worktree; cleaned up automatically if no files changed.
- `memory: "user"` or `"project"` — enable persistent memory at `~/.claude/agent-memory/` across conversations.

## Delegation heuristics

- Prefer a direct tool call for one-shot reads (`Read`, `Grep` with a known path). Subagents add latency and tokens.
- Dispatch via the `Agent` tool when the investigation needs many reads, unbounded exploration, or its own permissions.
- Parallel vs. serial: run in parallel when subtasks are independent; serialize when a later task depends on the earlier result.
- Split research from implementation — one subagent explores and summarizes, the main agent implements against that summary.

## Prompting a subagent

Every subagent prompt MUST contain:

1. Goal — one sentence naming the outcome.
2. Known context — files already read, decisions already made, constraints.
3. Output format — exact shape of the reply (bullet list, fenced block, field names).
4. Length cap — "< 200 words" or "≤ 5 bullets" to prevent drift.
5. Stop conditions — when to return with partial results (e.g. "if no matches in 3 globs, report empty").

## Parallel dispatch

Send multiple `Agent` calls in a single message for independent work:

```
Agent(task="audit auth/ for JWT handling", ...)
Agent(task="audit api/ for rate-limit headers", ...)
Agent(task="audit db/ for missing indexes", ...)
```

The main agent waits once, then relays a consolidated summary — it does not narrate each subagent's progress.

## Recommendations

- Give each subagent a written objective, output contract, and length cap — vague prompts waste tokens.
- Parallelize independent investigations; serialize only on real dependencies.
- Scope tool access per subagent: read-only agents list only `Read, Grep, Glob, Bash`; write-capable agents require a deliberate carve-out.
- Route high-volume or low-stakes work to Haiku via the subagent's `model:` field.
- Preserve important facts by having subagents persist artifacts (files, memory) rather than stuffing them into the main context.
- Reuse frequently-spawned workers as named subagents with a clear `description:` so Claude picks them deterministically.

## Anti-patterns

- Subagents dispatching other subagents without bounds — nested fan-out blows up context and latency.
- The main agent narrating subagent work step-by-step instead of relaying the final summary.
- Dispatching a subagent for a task that is one tool call — the overhead dwarfs the work.
- Vague prompts like "research X" with no output format — produces redundant searches and unfocused summaries.
- Unbounded spawning — e.g. 50 subagents for a simple query; cap the fan-out in the orchestrator prompt.
- "Endless search" loops where the subagent scours for sources that do not exist; include a stop condition.
- Duplicate work from overlapping task boundaries — partition the problem space explicitly.
- Write-capable subagents invoked without parsing a contracted output — "run it and hope" corrupts state silently.
