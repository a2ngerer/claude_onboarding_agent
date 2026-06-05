---
name: subagents
description: Subagent orchestration patterns for Claude Code — when to delegate, how to structure, and what to avoid
last_updated: 2026-06-05
sources:
  - https://docs.claude.com/en/docs/claude-code/sub-agents
  - https://www.anthropic.com/engineering/multi-agent-research-system
  - https://www.anthropic.com/engineering/claude-code-best-practices
version: 2
---

## Three agent models

- **Subagents** — run within a single session; delegate a bounded task and return a summary.
- **Background agents** (`claude agents` CLI / agent view) — independent sessions running in parallel; monitor from one place.
- **Agent teams** — multiple sessions that communicate and share tasks via a team-lead session.

Use subagents for context isolation within a task. Use background agents or teams for parallel, long-horizon work.

## Built-in subagents

| Subagent | Model | Purpose |
|---|---|---|
| **Explore** | Haiku | Read-only codebase search; skips CLAUDE.md for speed |
| **Plan** | Inherited | Research during plan mode; read-only |
| **General-purpose** | Inherited | Complex multi-step tasks needing exploration + action |

Invoke built-ins explicitly: `"Use the Explore agent to find all usages of X."`

## When to use a subagent

- A side task would flood the main context with file contents, logs, or search hits not referenced again.
- The work needs a different tool-set, a different model, or a separate permission profile.
- Three or more independent queries that can run in parallel.
- Verification after implementation — a fresh context is less biased toward the code it just wrote.
- A repeated worker with the same instructions — formalize as a named subagent in `.claude/agents/`.

## Delegation heuristics

- Prefer a direct tool call for one-shot reads (`Read`, `Grep` with a known path). Subagents add latency and tokens.
- Dispatch via the `Agent` tool when the investigation needs many reads, unbounded exploration, or its own permissions.
- Parallel vs. serial: run in parallel when subtasks are independent; serialize when a later task depends on earlier results.
- Split research from implementation — one subagent explores and summarizes, the main agent (or another) implements.

## Prompting a subagent

Every subagent prompt MUST contain:

1. Goal — one sentence naming the outcome.
2. Known context — files already read, decisions already made, constraints.
3. Output format — exact shape of the reply (bullet list, fenced block, field names).
4. Length cap — "< 200 words" or "≤ 5 bullets" to prevent drift.
5. Stop conditions — when to return with partial results.

## Named subagents

Store in `.claude/agents/<name>.md` (project, priority 3) or `~/.claude/agents/<name>.md` (user, priority 4). Both directories are scanned recursively; subdirectories do not affect identity (identity comes from the `name` frontmatter field). Plugin agents are scoped as `<plugin>:<path>:<name>`.

Create and manage via `/agents` (interactive UI with guided setup or Claude generation) or directly as Markdown files with YAML frontmatter.
- Add `model:` to route to a specific tier.
- Add `memory: user` to enable persistent memory at `~/.claude/agent-memory/` for accumulating insights across sessions.

## Parallel dispatch

Send multiple `Agent` calls in a single message for independent work:

```
Agent(task="audit auth/ for JWT handling", ...)
Agent(task="audit api/ for rate-limit headers", ...)
```

The main agent waits once, then relays a consolidated summary — it does not narrate each subagent's progress.

## Recommendations

- Give each subagent a written objective, output contract, and length cap.
- Parallelize independent investigations; serialize only on real dependencies.
- Scope tool access per subagent: read-only agents list only `Read, Grep, Glob, Bash`.
- Route high-volume or low-stakes work to Haiku via the subagent's `model:` field.
- Have subagents persist artifacts (files, memory) rather than stuffing results back into main context.
- Reuse frequently-spawned workers as named subagents with clear `description:` fields so Claude delegates deterministically.

## Anti-patterns

- Subagents dispatching other subagents — nested fan-out blows up context and latency.
- The main agent narrating subagent work step-by-step instead of relaying the final summary.
- Dispatching a subagent for a task that is one tool call — overhead dwarfs the work.
- Vague prompts like "research X" with no output format — produces redundant searches and unfocused summaries.
- Unbounded spawning without a fan-out cap.
- "Endless search" loops where the subagent scours for sources that don't exist; include a stop condition.
- Write-capable subagents invoked without parsing a contracted output — "run it and hope" corrupts state silently.
