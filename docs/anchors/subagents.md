---
name: subagents
description: Subagent orchestration patterns for Claude Code — when to delegate, how to structure, and what to avoid
last_updated: 2026-07-16
sources:
  - https://docs.claude.com/en/docs/claude-code/sub-agents
  - https://www.anthropic.com/engineering/multi-agent-research-system
  - https://www.anthropic.com/engineering/claude-code-best-practices
version: 3
---

## Built-in subagents

Claude Code ships `Explore`, `Plan`, and `general-purpose` by default; Claude delegates to them automatically when appropriate. Explore and Plan skip CLAUDE.md and the parent session's git status to stay fast and cheap — every other built-in and custom subagent loads both. A project/user subagent named `Explore` or `Plan` overrides the built-in one, letting you pin it to `model: haiku`.

## Named subagent frontmatter fields

Named subagents live at `.claude/agents/<name>.md` (or `~/.claude/agents/` for user-level) with YAML frontmatter. `name` and `description` are required. Other available fields:

| Field | Purpose |
|---|---|
| `model` | Model to run this agent on. Accepts aliases (`fable`, `opus`, `sonnet`, `haiku`) or full IDs. Defaults to `inherit` (uses the invoking context's model). Resolution order: `CLAUDE_CODE_SUBAGENT_MODEL` env var > per-invocation `model` param > this frontmatter field. |
| `tools` | Tools the subagent can use; inherits all tools if omitted. |
| `disallowedTools` | Comma-separated list of tools the subagent cannot call, even if its `tools:` whitelist includes them. |
| `permissionMode` | `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, or `plan`. Ignored for plugin subagents. |
| `mcpServers` | MCP servers available to this subagent, by name or inline config. Ignored for plugin subagents. |
| `hooks` | Lifecycle hooks scoped to this subagent. Ignored for plugin subagents. |
| `maxTurns` | Maximum number of agentic turns before the subagent is forced to return. Prevents runaway loops. |
| `skills` | Comma-separated skill slugs to preload (full content, not just description) into the subagent's context. |
| `memory` | `true` / `false` — whether the subagent has access to the user's memory files. Default: `false` for read-only agents. |
| `effort` | `low` / `medium` / `high` / `xhigh` / `max` — thinking budget hint passed to the model; available levels depend on the model. |
| `isolation` | `worktree` — run the subagent in a temporary git worktree branched from the default branch (not the parent session's HEAD); auto-cleaned up if unchanged. |
| `background` | `true` — always run this subagent as a background task. When unset, Claude chooses; subagents run in the background by default. |
| `color` | Display color in the task list/transcript: `red`, `blue`, `green`, `yellow`, `purple`, `orange`, `pink`, `cyan`. |

## Model tiering for subagents

- **Haiku** (`haiku`) — read-only scans, grep/glob searches, file counts, cheap classification. Fastest and cheapest.
- **Sonnet** (`sonnet`) — default worker for most implementation, review, and analysis tasks. Good balance of cost and capability.
- **Opus** (`opus`) — complex multi-step reasoning, architectural decisions, tasks that must get it right the first time.
- **Fable** (`fable`) — maximum capability; reserve for the hardest reasoning tasks where cost is secondary to quality.

Set `model: haiku` on read-only scanner agents; let implementation agents default to `sonnet` via `inherit`. Bump to `opus` or `fable` only when the task demonstrably needs it. In practice, external write-ups (e.g. Simon Willison's "Judgment") reinforce this per-task split further: when a dispatched agent's job is primarily writing/editing code, give it an explicit model override — `sonnet` for substantive implementation, `haiku` for trivial/mechanical edits — rather than letting every subagent inherit the parent's model by default.

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

## Anti-patterns

- Subagents dispatching other subagents — nesting is technically supported up to 5 levels (since v2.1.178) but remains strongly discouraged; nested fan-out multiplies context cost and latency unpredictably.
- The main agent narrating subagent work step-by-step instead of relaying the final summary.
- Dispatching a subagent for a task that is one tool call — the overhead dwarfs the work.
- Vague prompts like "research X" with no output format — produces redundant searches and unfocused summaries.
- Unbounded spawning — e.g. 50 subagents for a simple query; cap the fan-out in the orchestrator prompt.
- "Endless search" loops where the subagent scours for sources that do not exist; include a stop condition.
- Duplicate work from overlapping task boundaries — partition the problem space explicitly.
- Write-capable subagents invoked without parsing a contracted output — "run it and hope" corrupts state silently.
