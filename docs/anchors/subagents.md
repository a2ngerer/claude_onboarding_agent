---
name: subagents
description: Subagent orchestration patterns for Claude Code — when to delegate, how to structure, and what to avoid
last_updated: 2026-05-29
sources:
  - https://docs.claude.com/en/docs/claude-code/sub-agents
  - https://www.anthropic.com/engineering/multi-agent-research-system
  - https://www.anthropic.com/engineering/claude-code-best-practices
version: 2
---

## Built-in subagents

Claude Code ships three built-in subagents Claude uses automatically:

- **Explore** — fast read-only search and codebase analysis (Haiku model)
- **Plan** — read-only codebase research for plan-mode (inherits model)
- **general-purpose** — full-tool multi-step tasks (inherits model)

Use `/agents` to browse, create, edit, and delete custom subagents interactively.

## When to use a subagent

- A side task would flood the main context with file contents, search hits, or logs not referenced again.
- The work needs a different tool-set, a different model (e.g. Haiku for cheap scans), or a separate permission profile.
- The task is breadth-first: three or more independent queries that can run in parallel.
- Verification after implementation — a fresh context is less biased toward the code it just wrote.
- A repeated worker with the same instructions — formalize it as a named subagent under `.claude/agents/`.
- For many parallel independent sessions (not a single task), use **background agents** (`claude agents` dashboard) instead.

## Delegation heuristics

- Prefer a direct tool call for one-shot reads (`Read`, `Grep` with a known path). Subagents add latency and tokens.
- Dispatch via the `Agent` tool when the investigation needs many reads, unbounded exploration, or its own permissions.
- Parallel vs. serial: run in parallel when subtasks are independent; serialize when a later task depends on an earlier result.
- Split research from implementation — one subagent explores and summarizes, the main agent implements.
- Use `isolation: worktree` on a subagent when it needs its own isolated copy of the repository.

## Prompting a subagent

Every subagent prompt MUST contain:

1. Goal — one sentence naming the outcome.
2. Known context — files already read, decisions already made, constraints.
3. Output format — exact shape of the reply (bullet list, fenced block, field names).
4. Length cap — "< 200 words" or "≤ 5 bullets" to prevent drift.
5. Stop conditions — when to return with partial results.

## Parallel dispatch

Send multiple `Agent` calls in a single message for independent work:

```
Agent(task="audit auth/ for JWT handling", ...)
Agent(task="audit api/ for rate-limit headers", ...)
Agent(task="audit db/ for missing indexes", ...)
```

## Subagent frontmatter (key fields)

| Field | Purpose |
|---|---|
| `tools` | Allowlist of tools; inherits all if omitted |
| `disallowedTools` | Denylist applied before `tools` |
| `model` | `sonnet`, `opus`, `haiku`, a full model ID, or `inherit` |
| `isolation` | Set to `worktree` to give the subagent an isolated git worktree |
| `memory` | Set to `user`, `project`, or `local` to enable persistent cross-session memory |
| `background` | Set `true` to always run as a background task |
| `effort` | Effort level override: `low`, `medium`, `high`, `xhigh`, `max` |
| `maxTurns` | Cap on agentic turns before the subagent stops |
| `mcpServers` | MCP servers scoped to this subagent only |

Set `CLAUDE_CODE_SUBAGENT_MODEL` env var to override the model for all subagents in a session.

## Recommendations

- Give each subagent a written objective, output contract, and length cap.
- Parallelize independent investigations; serialize only on real dependencies.
- Scope tool access per subagent: read-only agents list only `Read, Grep, Glob, Bash`.
- Route high-volume or low-stakes work to Haiku via the `model:` field.
- Use `memory: user` on frequently-reused subagents so they accumulate project knowledge.
- Reuse frequently-spawned workers as named subagents in `.claude/agents/<name>.md`.

## Anti-patterns

- Subagents dispatching other subagents — nested fan-out blows up context and latency.
- The main agent narrating subagent work step-by-step instead of relaying the final summary.
- Dispatching a subagent for a task that is one tool call.
- Vague prompts like "research X" with no output format.
- Unbounded spawning — cap the fan-out in the orchestrator prompt.
- "Endless search" loops without a stop condition.
- Duplicate work from overlapping task boundaries.
- Write-capable subagents invoked without parsing a contracted output.
