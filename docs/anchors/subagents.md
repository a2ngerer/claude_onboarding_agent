---
name: subagents
description: Subagent orchestration patterns for Claude Code — when to delegate, how to structure, and what to avoid
last_updated: 2026-08-02
sources:
  - https://docs.claude.com/en/docs/claude-code/sub-agents
  - https://www.anthropic.com/engineering/multi-agent-research-system
  - https://www.anthropic.com/engineering/claude-code-best-practices
version: 3
---

## Named subagent frontmatter fields

Named subagents live at `.claude/agents/<name>.md` with YAML frontmatter. Available fields:

| Field | Purpose |
|---|---|
| `model` | Model to run this agent on. Accepts aliases (`fable`, `opus`, `sonnet`, `haiku`) or full IDs. Defaults to `inherit` (uses the invoking context's model). |
| `disallowedTools` | Comma-separated list of tools the subagent cannot call, even if its `tools:` whitelist includes them. |
| `maxTurns` | Maximum number of agentic turns before the subagent is forced to return. Prevents runaway loops. |
| `skills` | Comma-separated skill slugs to preload into the subagent's context. |
| `memory` | `true` / `false` — whether the subagent has access to the user's memory files. Default: `false` for read-only agents. |
| `effort` | `low` / `medium` / `high` / `xhigh` / `max` — thinking budget hint passed to the model; available levels depend on the model. |
| `isolation` | `worktree` — run the subagent in a temporary git worktree; branch and path returned to the caller on exit. |
| `background` | As of v2.1.198, subagents run in the background **by default** — Claude keeps working and is notified on completion. Set `background: true` to force it always; Claude otherwise chooses based on whether it needs the result immediately. Background subagents get a narrower built-in tool set (no `Agent`, `AskUserQuestion`, etc. — MCP tools are unaffected) and surface permission prompts in the main session. |

## Model tiering for subagents

- **Haiku** (`haiku`) — read-only scans, grep/glob searches, file counts, cheap classification. Fastest and cheapest.
- **Sonnet** (`sonnet`) — default worker for most implementation, review, and analysis tasks. Good balance of cost and capability.
- **Opus** (`opus`) — complex multi-step reasoning, architectural decisions, tasks that must get it right the first time.
- **Fable** (`fable`) — maximum capability; reserve for the hardest reasoning tasks where cost is secondary to quality.

Set `model: haiku` on read-only scanner agents; let implementation agents default to `sonnet` via `inherit`. Bump to `opus` or `fable` only when the task demonstrably needs it.

## When to use a subagent

- A side task would flood the main context with file contents, search hits, or logs that are not referenced again.
- The work needs a different tool-set, a different model (e.g. Haiku for cheap scans), or a separate permission profile.
- The task is breadth-first: three or more independent queries that can run in parallel.
- Verification after implementation — a fresh context is less biased toward the code it just wrote; a reviewer that only sees the diff and the criteria, not the reasoning that produced it, judges the result on its own terms.
- A repeated worker with the same instructions — formalize it as a named subagent under `.claude/agents/`.
- Weigh the cost: multi-agent orchestration runs roughly 15x the tokens of a single-agent chat (Anthropic's internal research-system benchmark), so reserve heavy fan-out for tasks valuable enough to justify it — most coding tasks have fewer truly parallelizable subtasks than research does.

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

Since subagents run in the background by default, the main agent doesn't necessarily block on them — it can keep working and picks up each result as a completion notification in a later turn, then relays a consolidated summary. It does not narrate each subagent's progress step-by-step.

## Recommendations

- Give each subagent a written objective, output contract, and length cap — vague prompts waste tokens.
- Parallelize independent investigations; serialize only on real dependencies.
- Scope tool access per subagent: read-only agents list only `Read, Grep, Glob, Bash`; write-capable agents require a deliberate carve-out.
- Route high-volume or low-stakes work to Haiku via the subagent's `model:` field.
- Preserve important facts by having subagents persist artifacts (files, memory) rather than stuffing them back into the main context.
- Reuse frequently-spawned workers as named subagents in `.claude/agents/<name>.md` with a clear `description:` so the main agent picks them deterministically.

## Anti-patterns

- Subagents dispatching other subagents — nesting is supported by default up to 3 layers below the main conversation (tune with `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`, `1` disables it) but remains strongly discouraged; nested fan-out multiplies context cost and latency unpredictably. At the depth limit Claude Code withholds the `Agent` tool so the deepest subagent must finish the work itself.
- The main agent narrating subagent work step-by-step instead of relaying the final summary.
- Dispatching a subagent for a task that is one tool call — the overhead dwarfs the work.
- Vague prompts like "research X" with no output format — produces redundant searches and unfocused summaries.
- Unbounded spawning — e.g. 50 subagents for a simple query; cap the fan-out in the orchestrator prompt. Claude Code also enforces session-level total and concurrent subagent limits as a backstop, but don't rely on the platform ceiling instead of a scoped prompt.
- "Endless search" loops where the subagent scours for sources that do not exist; include a stop condition.
- Duplicate work from overlapping task boundaries — partition the problem space explicitly.
- Write-capable subagents invoked without parsing a contracted output — "run it and hope" corrupts state silently.
