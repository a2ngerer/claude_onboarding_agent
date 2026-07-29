---
name: subagents
description: Subagent orchestration patterns for Claude Code — when to delegate, how to structure, and what to avoid
last_updated: 2026-07-29
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
| `model` | Model to run this agent on. Accepts aliases (`fable`, `opus`, `sonnet`, `haiku`) or full IDs. Defaults to `inherit` (uses the invoking context's model). |
| `tools` / `disallowedTools` | Allowlist / denylist of tools; `disallowedTools` applies first, then `tools` is resolved against what remains. Accept `mcp__<server>` patterns. |
| `permissionMode` / `mcpServers` | Override the permission mode or the MCP server set for this subagent. |
| `hooks` | Hooks scoped to this subagent's own lifecycle (converted to `SubagentStop` etc. when run as a subagent). |
| `maxTurns` | Maximum number of agentic turns before the subagent is forced to return. Prevents runaway loops. |
| `skills` | Comma-separated skill slugs to preload (full content injected) into the subagent's context. |
| `initialPrompt` | Seed message injected before the delegation task. |
| `memory` | `true` / `false` — whether the subagent has access to its own auto memory. Default: `false`. |
| `effort` | `low` / `medium` / `high` / `xhigh` — thinking budget hint passed to the model. |
| `isolation` | `worktree` — run the subagent in a temporary git worktree branched from the default branch (not the parent's `HEAD`); auto-cleaned if unchanged. |
| `background` | `true` — always run this subagent as a background task. As of v2.1.198, subagents run in the background **by default** whenever Claude doesn't need the result immediately; background subagents get a narrower built-in tool set. |
| `color` | Display color for the subagent in the UI. |

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
- Verification after implementation — a fresh context is less biased toward the code it just wrote. Anthropic's own guidance now calls this out explicitly as an "adversarial review step": have a subagent review the diff against stated criteria and report gaps only, not style preferences.
- A repeated worker with the same instructions — formalize it as a named subagent under `.claude/agents/`.

## Delegation heuristics

- Prefer a direct tool call for one-shot reads (`Read`, `Grep` with a known path). Subagents add latency and tokens.
- Dispatch via the `Agent` tool when the investigation needs many reads, unbounded exploration, or its own filesystem/network permissions.
- Parallel vs. serial: run in parallel when subtasks are independent; serialize when a later task depends on the earlier result.
- Split research from implementation — one subagent explores and summarizes, the main agent (or another subagent) implements against that summary.
- **Writer/Reviewer pattern** — one session (or subagent) implements, a second reviews the diff in a fresh context for edge cases and consistency, then the first addresses the feedback. Works for tests too: one writes tests, another writes the code to pass them.
- Use `context: fork` on a skill when the skill itself is the task and it benefits from isolation; `/subtask` runs a one-off forked subagent from an interactive session (`/fork` now copies the whole session into a new background session instead).

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

## Spawn limits (defaults, all configurable via env var)

- **Nesting depth** — a subagent can spawn its own subagents up to 3 layers below the main conversation (`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`). At the limit, the `Agent` tool is withheld except for forks.
- **Per-session cap** — at most 200 subagents spawned per session (`CLAUDE_CODE_MAX_SUBAGENTS_PER_SESSION`); every nested subagent, fork, and background subagent counts.
- **Concurrent cap** — at most 20 subagents running at once (`CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`); exceeding it fails the spawn with an error Claude is told not to retry. Sessions with `ultracode` active are exempt.

## Recommendations

- Give each subagent a written objective, output contract, and length cap — vague prompts waste tokens.
- Parallelize independent investigations; serialize only on real dependencies.
- Scope tool access per subagent: read-only agents list only `Read, Grep, Glob, Bash`; write-capable agents require a deliberate carve-out.
- Route high-volume or low-stakes work to Haiku via the subagent's `model:` field.
- Preserve important facts by having subagents persist artifacts (files, memory) rather than stuffing them back into the main context.
- Reuse frequently-spawned workers as named subagents in `.claude/agents/<name>.md` with a clear `description:` so the main agent picks them deterministically.
- When reviewing with a subagent, tell it to flag only gaps that affect correctness or stated requirements — an unconstrained reviewer over-reports style nits and drives over-engineering.

## Anti-patterns

- Unbounded subagent-dispatches-subagent fan-out — nesting is capped at 3 layers below the main conversation by default and remains discouraged beyond one level; it multiplies context cost and latency unpredictably.
- The main agent narrating subagent work step-by-step instead of relaying the final summary.
- Dispatching a subagent for a task that is one tool call — the overhead dwarfs the work.
- Vague prompts like "research X" with no output format — produces redundant searches and unfocused summaries.
- Unbounded spawning — e.g. 50 subagents for a simple query; cap the fan-out in the orchestrator prompt (hard session caps exist but shouldn't be the only guardrail).
- "Endless search" loops where the subagent scours for sources that do not exist; include a stop condition.
- Duplicate work from overlapping task boundaries — partition the problem space explicitly.
- Write-capable subagents invoked without parsing a contracted output — "run it and hope" corrupts state silently.
