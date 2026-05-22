---
name: subagents
description: Subagent orchestration patterns for Claude Code — when to delegate, how to structure, and what to avoid
last_updated: 2026-05-22
sources:
  - https://docs.claude.com/en/docs/claude-code/sub-agents
  - https://www.anthropic.com/engineering/multi-agent-research-system
  - https://www.anthropic.com/engineering/claude-code-best-practices
version: 2
---

## Built-in subagents

Claude Code ships three built-in subagents that Claude selects automatically:

| Subagent | Model | Tools | Purpose |
|---|---|---|---|
| `Explore` | Haiku | Read-only | Fast codebase search; skips CLAUDE.md for speed |
| `Plan` | Inherits | Read-only | Codebase research during plan mode |
| `general-purpose` | Inherits | All | Complex multi-step tasks needing both reads and writes |

Use `subagent_type` to dispatch a named subagent via the `Agent` tool. Matching is **case- and separator-insensitive** (`"Code Reviewer"` → `code-reviewer`) as of v2.1.140.

## When to use a subagent

- A side task would flood the main context with file contents, search hits, or logs that are not referenced again.
- The work needs a different tool-set, a different model (e.g. Haiku for cheap scans), or a separate permission profile.
- The task is breadth-first: three or more independent queries that can run in parallel.
- Verification after implementation — a fresh context is less biased toward the code it just wrote.
- A repeated worker with the same instructions — formalize it as a named subagent under `.claude/agents/`.

Note: for many independent **sessions** running in parallel with a shared overview, use background agents (`claude agents`) rather than subagents. Subagents run within a single session.

## Delegation heuristics

- Prefer a direct tool call for one-shot reads (`Read`, `Grep` with a known path). Subagents add latency and tokens.
- Dispatch via the `Agent` tool when the investigation needs many reads, unbounded exploration, or its own filesystem/network permissions.
- Parallel vs. serial: run in parallel when subtasks are independent; serialize when a later task depends on the earlier result.
- Split research from implementation — one subagent explores and summarizes, the main agent (or another subagent) implements against that summary.

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

The main agent waits once, then relays a consolidated summary.

## Named subagent frontmatter

File: `.claude/agents/<name>.md`. Key frontmatter fields:

| Field | Purpose |
|---|---|
| `name` | Unique kebab-case identifier; `hooks` receive it as `agent_type` |
| `description` | When Claude should delegate here |
| `tools` | Allowlist; inherits all if omitted. Use `disallowedTools` for a denylist |
| `model` | `sonnet`, `opus`, `haiku`, full ID, or `inherit` (default) |
| `permissionMode` | `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, `plan` |
| `effort` | Effort level override: `low`, `medium`, `high`, `xhigh`, `max` |
| `memory` | Persistent memory scope: `user`, `project`, or `local` |
| `background` | `true` to always run as a background task |
| `isolation` | `worktree` to run in a temporary git worktree (auto-cleaned if no changes) |
| `mcpServers` | MCP servers scoped to this subagent only |
| `hooks` | Lifecycle hooks scoped to this subagent |
| `skills` | Skills to preload into the subagent's context at startup |
| `maxTurns` | Cap on agentic turns |

## Recommendations

- Give each subagent a written objective, output contract, and length cap — vague prompts waste tokens.
- Parallelize independent investigations; serialize only on real dependencies.
- Scope tool access per subagent: read-only agents list only `Read, Grep, Glob, Bash`; write-capable agents require a deliberate carve-out.
- Route high-volume or low-stakes work to Haiku via the subagent's `model:` field.
- For subagents that accumulate project-specific knowledge, set `memory: project` so learnings persist across conversations.
- Reuse frequently-spawned workers as named subagents in `.claude/agents/<name>.md` with a clear `description:` so the main agent picks them deterministically.

## Anti-patterns

- Subagents dispatching other subagents — nested dispatch blows up context and latency; it is also blocked by the runtime.
- The main agent narrating subagent work step-by-step instead of relaying the final summary.
- Dispatching a subagent for a task that is one tool call — the overhead dwarfs the work.
- Vague prompts like "research X" with no output format — produces redundant searches and unfocused summaries.
- Unbounded spawning — cap the fan-out in the orchestrator prompt.
- "Endless search" loops where the subagent scours for sources that do not exist; include a stop condition.
- Duplicate work from overlapping task boundaries — partition the problem space explicitly.
- Write-capable subagents invoked without parsing a contracted output — "run it and hope" corrupts state silently.
