---
name: subagents
description: Subagent orchestration patterns for Claude Code — when to delegate, how to structure, and what to avoid
last_updated: 2026-06-04
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

Note: **subagents** run inside the current session. For many independent sessions running in parallel, see background agents (`/agent-view`); for sessions that communicate, see agent teams.

## Defining named subagents

Store `.claude/agents/<name>.md` (project) or `~/.claude/agents/<name>.md` (user). Only `name` and `description` frontmatter fields are required.

Key frontmatter fields:

| Field | Purpose |
|---|---|
| `name` | Unique kebab-case identifier |
| `description` | When Claude should delegate here |
| `tools` | Comma-separated tool whitelist; inherits all if omitted |
| `disallowedTools` | Tools to deny from the inherited set |
| `model` | `sonnet`, `opus`, `haiku`, full model ID, or `inherit` (default) |
| `memory` | `user`, `project`, or `local` — enables persistent auto memory |
| `isolation` | `worktree` — runs in a temporary isolated git worktree |
| `maxTurns` | Cap on agentic turns |
| `effort` | Override session effort level (`low`/`medium`/`high`/`xhigh`/`max`) |
| `permissionMode` | `default`, `acceptEdits`, `auto`, `bypassPermissions`, `plan` |
| `hooks` | Lifecycle hooks scoped to this subagent |

Set `CLAUDE_CODE_SUBAGENT_MODEL` to override the model for all subagents in a session.

## Delegation heuristics

- Prefer a direct tool call for one-shot reads (`Read`, `Grep` with a known path). Subagents add latency and tokens.
- Dispatch via the `Agent` tool when the investigation needs many reads, unbounded exploration, or its own permissions.
- Parallel vs. serial: run in parallel when subtasks are independent; serialize when a later task depends on the earlier result.
- Split research from implementation — one subagent explores and summarizes, the main agent implements against that summary.

## Prompting a subagent

Every subagent prompt MUST contain:

1. Goal — one sentence naming the outcome.
2. Known context — files already read, decisions already made, constraints.
3. Output format — exact shape of the reply (fenced block, field names).
4. Length cap — "< 200 words" or "≤ 5 bullets" to prevent drift.
5. Stop conditions — when to return with partial results.

## Parallel dispatch

```
Agent(task="audit auth/ for JWT handling", ...)
Agent(task="audit api/ for rate-limit headers", ...)
```

The main agent waits once, then relays a consolidated summary.

## Recommendations

- Give each subagent a written objective, output contract, and length cap.
- Parallelize independent investigations; serialize only on real dependencies.
- Scope tools explicitly: read-only agents list only `Read, Grep, Glob, Bash`.
- Route high-volume or low-stakes work to Haiku via `model: haiku`.
- Enable `memory: user` for subagents that accumulate codebase knowledge across sessions.
- Use `isolation: worktree` for write-capable subagents doing parallel mutations.
- Use `SubagentStart` / `SubagentStop` hooks to log or gate subagent lifecycle events.

## Anti-patterns

- Subagents dispatching other subagents — nested fan-out blows up context and latency.
- The main agent narrating subagent work step-by-step instead of relaying the final summary.
- Dispatching a subagent for a task that is one tool call.
- Vague prompts with no output format — produces redundant searches and unfocused summaries.
- Unbounded spawning — cap the fan-out in the orchestrator prompt.
- "Endless search" loops without a stop condition.
- Write-capable subagents invoked without parsing a contracted output — "run it and hope" corrupts state silently.
