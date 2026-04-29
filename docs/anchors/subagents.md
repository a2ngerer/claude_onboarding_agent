---
name: subagents
description: Subagent orchestration patterns for Claude Code — when to delegate, how to structure, and what to avoid
last_updated: 2026-04-29
sources:
  - https://docs.claude.com/en/docs/claude-code/sub-agents
  - https://www.anthropic.com/engineering/multi-agent-research-system
  - https://www.anthropic.com/engineering/claude-code-best-practices
version: 2
---

## Built-in subagents

Claude Code ships three built-in subagents invoked automatically:

- **Explore** (Haiku, read-only) — fast codebase search and file discovery; invoked with a thoroughness hint (`quick`, `medium`, `very thorough`).
- **Plan** (inherits model, read-only) — gathers codebase context during plan mode before presenting a plan. Cannot spawn further subagents (prevents infinite nesting).
- **general-purpose** (inherits model, all tools) — complex multi-step tasks requiring both exploration and changes.

## When to use a subagent

- A side task would flood the main context with file contents, search hits, or logs that are not referenced again.
- The work needs a different tool-set, a different model (e.g. Haiku for cheap scans), or a separate permission profile.
- The task is breadth-first: three or more independent queries that can run in parallel.
- Verification after implementation — a fresh context is less biased toward the code it just wrote.
- A repeated worker with the same instructions — formalize it as a named subagent under `.claude/agents/`.

## Delegation heuristics

- Prefer a direct tool call for one-shot reads (`Read`, `Grep` with a known path). Subagents add latency and tokens.
- Dispatch via the `Agent` tool when the investigation needs many reads, unbounded exploration, or its own filesystem/network permissions.
- Parallel vs. serial: run in parallel when subtasks are independent; serialize when a later task depends on the earlier result.
- Split research from implementation — one subagent explores and summarizes, the main agent (or another subagent) implements against that summary.
- Use `isolation: "worktree"` in frontmatter when the subagent benefits from an isolated file copy of the repo.

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

## Subagent frontmatter fields

Named subagents in `.claude/agents/<name>.md` support these frontmatter fields:

| Field | Purpose |
|---|---|
| `description` | Trigger hint — Claude reads this to decide when to delegate |
| `tools` | Comma-separated tool allowlist (omit for all tools) |
| `model` | Override model; `haiku` for cheap scans, `opus` for hard reasoning |
| `initialPrompt` | Auto-submits this text as the first turn when the subagent starts |
| `memory` | `"user"` or `"project"` — gives the subagent a persistent memory directory |
| `isolation` | `"worktree"` — subagent works on an isolated copy of the repo |
| `maxTurns` | Cap the number of turns before the subagent returns |
| `permissionMode` | Override permission mode for this subagent |

Manage subagents interactively with `/agents` (view, create, edit, delete). For session-scoped agents without saving to disk, use the `--agents` CLI flag with JSON.

## Recommendations

- Give each subagent a written objective, output contract, and length cap — vague prompts waste tokens.
- Parallelize independent investigations; serialize only on real dependencies.
- Scope tool access per subagent: read-only agents list only `Read, Grep, Glob, Bash`; write-capable agents require a deliberate carve-out.
- Route high-volume or low-stakes work to Haiku via the subagent's `model:` field.
- Use `memory: "user"` for subagents that should accumulate cross-session knowledge (e.g. recurring codebase patterns).
- Reuse frequently-spawned workers as named subagents in `.claude/agents/<name>.md` with a clear `description:` so the main agent picks them deterministically.

## Anti-patterns

- Subagents dispatching other subagents — nested fan-out blows up context and latency. Built-in subagents like Plan block this explicitly.
- The main agent narrating subagent work step-by-step instead of relaying the final summary.
- Dispatching a subagent for a task that is one tool call — the overhead dwarfs the work.
- Vague prompts like "research X" with no output format — produces redundant searches and unfocused summaries.
- Unbounded spawning — e.g. 50 subagents for a simple query; cap the fan-out in the orchestrator prompt.
- "Endless search" loops where the subagent scours for sources that do not exist; include a stop condition.
- Duplicate work from overlapping task boundaries — partition the problem space explicitly.
- Write-capable subagents invoked without parsing a contracted output — "run it and hope" corrupts state silently.
