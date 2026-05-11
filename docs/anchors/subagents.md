---
name: subagents
description: Subagent orchestration patterns for Claude Code — when to delegate, how to structure, and what to avoid
last_updated: 2026-05-11
sources:
  - https://docs.claude.com/en/docs/claude-code/sub-agents
  - https://www.anthropic.com/engineering/multi-agent-research-system
  - https://www.anthropic.com/engineering/claude-code-best-practices
version: 2
---

## Subagents vs. agent teams

**Subagents** run within a single session and cannot communicate with each other. Use one when a side task would flood the main context window. **Agent teams** coordinate multiple sessions running in parallel and communicating — use them for truly parallel, cross-session workflows (`/agent-teams` or the Teams API).

## Built-in subagents

Claude Code ships three built-in subagents invoked automatically: **Explore** (Haiku, read-only, codebase search), **Plan** (inherits model, read-only, planning research), and **general-purpose** (inherits model, all tools, multi-step tasks). Additional helpers include `statusline-setup` (Sonnet) and `claude-code-guide` (Haiku).

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
- Use `context: fork` on a skill when the skill itself is the task and it benefits from isolation.

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
- Preserve important facts by having subagents persist artifacts (files, memory) rather than stuffing them back into the main context.
- Reuse frequently-spawned workers as named subagents in `.claude/agents/<name>.md` with a clear `description:` so the main agent picks them deterministically.
- Create and manage subagents interactively with the `/agents` command (Library tab → Create new agent).
- Enable persistent memory for a subagent by setting memory scope to `user` — the subagent accumulates insights in `~/.claude/agent-memory/` across sessions.
- Set `worktree.baseRef` to `"head"` in `settings.json` when worktree subagents must see unpushed commits; the default `"fresh"` branches from `origin/<default>` instead.

## Anti-patterns

- Subagents dispatching other subagents without bounds — nested fan-out blows up context and latency.
- The main agent narrating subagent work step-by-step instead of relaying the final summary.
- Dispatching a subagent for a task that is one tool call — the overhead dwarfs the work.
- Vague prompts like "research X" with no output format — produces redundant searches and unfocused summaries.
- Unbounded spawning — e.g. 50 subagents for a simple query; cap the fan-out in the orchestrator prompt.
- "Endless search" loops where the subagent scours for sources that do not exist; include a stop condition.
- Duplicate work from overlapping task boundaries — partition the problem space explicitly.
- Write-capable subagents invoked without parsing a contracted output — "run it and hope" corrupts state silently.
