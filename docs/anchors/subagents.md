---
name: subagents
description: Subagent orchestration patterns for Claude Code — when to delegate, how to structure, and what to avoid
last_updated: 2026-05-18
sources:
  - https://docs.claude.com/en/docs/claude-code/sub-agents
  - https://www.anthropic.com/engineering/multi-agent-research-system
  - https://www.anthropic.com/engineering/claude-code-best-practices
version: 2
---

## Subagents vs background agents vs agent teams

**Subagents** run within a single session in their own context window; they cannot spawn other subagents. **Background agents** (`/agents` panel, `claude agents` CLI) run as separate parallel sessions monitored from one place. **Agent teams** extend background agents with cross-session communication. This page covers in-session subagents only.

## When to use a subagent

- A side task would flood the main context with file contents, search hits, or logs not referenced again.
- The work needs a different tool-set, model (e.g. Haiku for cheap scans), or separate permission profile.
- The task is breadth-first: three or more independent queries that can run in parallel.
- Verification after implementation — a fresh context is less biased toward the code it just wrote.
- A repeated worker with the same instructions — formalize it as a named subagent under `.claude/agents/`.

## Built-in subagents

| Agent | Model | Tools | When Claude uses it |
|---|---|---|---|
| Explore | Haiku | Read-only | Codebase search, file discovery |
| Plan | Inherits | Read-only | Research during plan mode |
| General-purpose | Inherits | All | Complex multi-step tasks |

## Named subagents

Define subagent files (`.md` with YAML frontmatter) at:
- `.claude/agents/` — project scope; check into version control for team sharing
- `~/.claude/agents/` — personal, available in all your projects
- Plugin `agents/` directory — distributed with plugins

Priority on name conflict: managed → `--agents` CLI flag → project → user → plugin.

Create and manage via `/agents` command (Running + Library tabs). For scripting, pass `--agents '<json>'` at startup for session-scoped definitions that aren't saved to disk.

Subagents can maintain **persistent memory**: opt in per subagent; learnings accumulate in `~/.claude/agent-memory/` across conversations.

## Delegation heuristics

- Prefer a direct tool call for one-shot reads (`Read`, `Grep` with a known path). Subagents add latency and tokens.
- Dispatch via the `Agent` tool when investigation needs many reads, unbounded exploration, or its own filesystem/network permissions.
- Parallel vs. serial: run in parallel when subtasks are independent; serialize when a later task depends on the earlier result.
- Split research from implementation — one subagent explores and summarizes, the main agent implements.
- Use `context: fork` on a skill's SKILL.md to run that skill in an isolated subagent context.

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
```

The main agent waits once, then relays a consolidated summary.

## Recommendations

- Give each subagent a written objective, output contract, and length cap.
- Parallelize independent investigations; serialize only on real dependencies.
- Scope tool access: read-only agents list only `Read, Grep, Glob, Bash`; write-capable require a deliberate carve-out.
- Route high-volume or low-stakes work to Haiku via the subagent's `model:` field.
- Preserve important facts by having subagents persist artifacts rather than stuffing them into main context.
- Reuse frequently-spawned workers as named subagents with a clear `description:` so Claude delegates deterministically.

## Anti-patterns

- Subagents dispatching other subagents — nested fan-out blows up context and latency.
- Narrating subagent work step-by-step instead of relaying the final summary.
- Dispatching a subagent for a task that is one tool call — overhead dwarfs the work.
- Vague prompts with no output format — produces redundant searches and unfocused summaries.
- Unbounded spawning — cap the fan-out in the orchestrator prompt.
- "Endless search" loops without a stop condition.
- Overlapping task boundaries — partition the problem space explicitly.
- Write-capable subagents invoked without parsing a contracted output — "run it and hope" corrupts state silently.
