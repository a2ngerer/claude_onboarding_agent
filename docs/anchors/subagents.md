---
name: subagents
description: Subagent orchestration patterns for Claude Code — when to delegate, how to structure, and what to avoid
last_updated: 2026-08-04
sources:
  - https://docs.claude.com/en/docs/claude-code/sub-agents
  - https://www.anthropic.com/engineering/multi-agent-research-system
  - https://www.anthropic.com/engineering/claude-code-best-practices
version: 3
---

## Named subagent frontmatter fields

Named subagents live at `.claude/agents/<name>.md` with YAML frontmatter. Only `name` and `description` are required. Available fields:

| Field | Purpose |
|---|---|
| `model` | Model to run this agent on. Accepts aliases (`fable`, `opus`, `sonnet`, `haiku`), a full model ID (e.g. `claude-opus-5`), or `inherit` (default). |
| `disallowedTools` | Tools to deny, removed from the inherited or specified `tools` list. Applied before `tools` is resolved. |
| `maxTurns` | Maximum number of agentic turns before the subagent is forced to return. Prevents runaway loops. |
| `skills` | Skills to preload (full content injected) into the subagent's context at startup. Subagents can still invoke unlisted skills via the Skill tool regardless of this field. |
| `memory` | Persistent memory scope: `user`, `project`, or `local`. Enables cross-session learning for this subagent. Not a boolean. |
| `effort` | `low` / `medium` / `high` / `xhigh` / `max` — thinking budget hint; overrides session effort. |
| `isolation` | `worktree` — run the subagent in a temporary git worktree; branch and path returned to the caller on exit. |
| `background` | `true` — always run this subagent in the background even if Claude needs the result immediately. When unset, Claude decides — and as of v2.1.198, subagents run in the background **by default**. |
| `permissionMode` | `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, or `plan`. Ignored for plugin subagents. |
| `mcpServers` | MCP servers available to this subagent — a configured server name or an inline server config. |
| `color` | Display color in the task list/transcript (`red`, `blue`, `green`, etc.). |

## Model tiering for subagents

- **Haiku** (`haiku`) — read-only scans, grep/glob searches, file counts, cheap classification. Fastest and cheapest.
- **Sonnet** (`sonnet`) — default worker for most implementation, review, and analysis tasks. Good balance of cost and capability.
- **Opus** (`opus`) — complex multi-step reasoning, architectural decisions, tasks that must get it right the first time.
- **Fable** (`fable`) — maximum capability; reserve for the hardest reasoning tasks where cost is secondary to quality.

Set `model: haiku` on read-only scanner agents; let implementation agents default to `sonnet` via `inherit`. Bump to `opus` or `fable` only when the task demonstrably needs it.

Community practice (not yet in official docs): for open-ended orchestration, prefer delegating smaller subtasks to lower-capability models based on the orchestrator's own judgment at dispatch time rather than hard-coding a tier per task type — this preserves high-tier token budget for the work that actually needs it.

## Nesting, concurrency, and spawn limits

Three independent limits govern subagent fan-out, each with its own env var override:

- **Depth** — a subagent can spawn its own subagents up to **3 layers** below the main conversation by default (`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`). At the limit, the `Agent` tool is withheld so the subagent finishes the work itself and returns a summary.
- **Concurrency** — at most **20** subagents run at once by default (`CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`); spawning past that fails with a non-retryable error until the count drops. Sessions with ultracode active are exempt.
- **Per-session total** — at most **200** subagent spawns per session by default (`CLAUDE_CODE_MAX_SUBAGENTS_PER_SESSION`); no upper bound if raised, but the cap can't be disabled entirely.

## When to use a subagent

- A side task would flood the main context with file contents, search hits, or logs that are not referenced again.
- The work needs a different tool-set, a different model (e.g. Haiku for cheap scans), or a separate permission profile.
- The task is breadth-first: three or more independent queries that can run in parallel.
- Verification after implementation — a fresh context is less biased toward the code it just wrote. A reviewer subagent sees only the diff and the criteria given to it, not the reasoning that produced the change.
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

Since subagents run in the background by default, the main agent isn't blocked waiting — it's notified as each one completes and relays a consolidated summary rather than narrating progress.

## Recommendations

- Give each subagent a written objective, output contract, and length cap — vague prompts waste tokens.
- Parallelize independent investigations; serialize only on real dependencies.
- Scope tool access per subagent: read-only agents list only `Read, Grep, Glob, Bash`; write-capable agents require a deliberate carve-out.
- Route high-volume or low-stakes work to Haiku via the subagent's `model:` field.
- Preserve important facts by having subagents persist artifacts (files, memory) rather than stuffing them back into the main context.
- Reuse frequently-spawned workers as named subagents in `.claude/agents/<name>.md` with a clear `description:` so the main agent picks them deterministically.
- Add an adversarial review step before treating long unattended runs as done — a fresh-context subagent reviewing the diff catches gaps the implementing session is blind to.

## Anti-patterns

- Subagents dispatching other subagents — nesting is supported up to 3 layers below the main conversation by default (configurable), but deep nesting still multiplies context cost and latency unpredictably.
- The main agent narrating subagent work step-by-step instead of relaying the final summary.
- Dispatching a subagent for a task that is one tool call — the overhead dwarfs the work.
- Vague prompts like "research X" with no output format — produces redundant searches and unfocused summaries.
- Unbounded spawning — e.g. 50 subagents for a simple query; cap the fan-out in the orchestrator prompt even though the platform's own caps (20 concurrent, 200/session) provide a backstop.
- "Endless search" loops where the subagent scours for sources that do not exist; include a stop condition.
- Duplicate work from overlapping task boundaries — partition the problem space explicitly.
- Write-capable subagents invoked without parsing a contracted output — "run it and hope" corrupts state silently.
