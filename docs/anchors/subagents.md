---
name: subagents
description: Subagent orchestration patterns for Claude Code — when to delegate, how to structure, and what to avoid
last_updated: 2026-07-18
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
| `model` | Model to run this agent on. Accepts aliases (`fable`, `opus`, `sonnet`, `haiku`), a full model ID, or `inherit` (default) — uses the invoking context's model. |
| `disallowedTools` | Tools the subagent cannot call, even if `tools:` includes them. Accepts MCP server patterns (`mcp__server`, `mcp__*`). |
| `maxTurns` | Maximum agentic turns before the subagent is forced to return. |
| `skills` | Skill slugs to preload (full content, not just description) into the subagent's context at startup. |
| `memory` | `user` / `project` / `local` — persistent memory scope surviving across conversations. Omit for no persistent memory. |
| `effort` | `low` / `medium` / `high` / `xhigh` / `max` — thinking budget hint. Defaults to session effort. |
| `isolation` | `worktree` — run in a temporary git worktree; auto-cleaned up if no changes are made. |
| `background` | `true` forces background execution always. Subagents run in the background by default; Claude only foregrounds one when it needs the result immediately. |
| `permissionMode` | `default` / `acceptEdits` / `auto` / `dontAsk` / `bypassPermissions` / `plan` — overrides how the subagent handles permission prompts (a stricter parent mode still takes precedence). |
| `mcpServers` | MCP servers scoped to just this subagent, kept out of the main conversation's context. |
| `hooks` | Lifecycle hooks (`PreToolUse`, `PostToolUse`, `Stop`) scoped only to this subagent's run. |
| `color` | Display color in the task list/transcript panel. |
| `initialPrompt` | Auto-submitted first user turn when this agent runs as the main session (via `--agent`). |

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
- Verification after implementation — a fresh context is less biased toward the code it just wrote.
- A repeated worker with the same instructions — formalize it as a named subagent under `.claude/agents/`.
- A side task needs the *existing* conversation's full context rather than a summary — fork the conversation instead of dispatching a named subagent; a fork inherits history and shares the parent's prompt cache, so it is cheaper than re-explaining context.
- Work needs sustained parallelism across sessions that message each other — use agent teams, not in-session subagents.

## Delegation heuristics

- Prefer a direct tool call for one-shot reads (`Read`, `Grep` with a known path). Subagents add latency and tokens.
- Dispatch via the `Agent` tool when the investigation needs many reads, unbounded exploration, or its own filesystem/network permissions.
- Parallel vs. serial: run in parallel when subtasks are independent; serialize when a later task depends on the earlier result.
- Split research from implementation — one subagent explores and summarizes, the main agent (or another subagent) implements against that summary.
- Use `context: fork` on a skill when the skill itself is the task and it benefits from isolation.
- To resume or redirect a running or completed named subagent, message it directly using its agent ID or name — the same mechanism agent-team teammates use to communicate.

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
- Nested dispatch (a subagent spawning its own subagent, up to depth 5) is a supported and sometimes recommended pattern — e.g. a reviewer subagent dispatching a verifier per finding — but still budget for the added cost and latency.

## Anti-patterns

- The main agent narrating subagent work step-by-step instead of relaying the final summary.
- Dispatching a subagent for a task that is one tool call — the overhead dwarfs the work.
- Vague prompts like "research X" with no output format — produces redundant searches and unfocused summaries.
- Unbounded spawning — e.g. 50 subagents for a simple query; cap the fan-out in the orchestrator prompt. The harness also enforces a hard session-wide subagent cap as a backstop, but don't rely on that instead of scoping the task.
- "Endless search" loops where the subagent scours for sources that do not exist; include a stop condition.
- Duplicate work from overlapping task boundaries — partition the problem space explicitly.
- Write-capable subagents invoked without parsing a contracted output — "run it and hope" corrupts state silently.
