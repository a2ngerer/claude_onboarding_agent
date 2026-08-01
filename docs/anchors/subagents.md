---
name: subagents
description: Subagent orchestration patterns for Claude Code — when to delegate, how to structure, and what to avoid
last_updated: 2026-08-01
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
| `tools` / `disallowedTools` | Allowlist / denylist of tools; `mcp__<server>` patterns grant or remove a whole MCP server's tools |
| `model` | Model to run this agent on. Accepts aliases (`fable`, `opus`, `sonnet`, `haiku`), a full model ID, or `inherit` (default) |
| `permissionMode` | `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, `plan`. Ignored for plugin subagents |
| `maxTurns` | Maximum number of agentic turns before the subagent is forced to return |
| `skills` | Skill slugs to preload (full content, not just description) into the subagent's context |
| `mcpServers` | MCP servers available to this subagent — by name or inline config. Ignored for plugin subagents |
| `hooks` | Lifecycle hooks scoped to this subagent. Ignored for plugin subagents |
| `memory` | `user` / `project` / `local` — persistent cross-session memory scope. Omit for stateless read-only agents |
| `effort` | `low` / `medium` / `high` / `xhigh` / `max` — thinking budget hint |
| `isolation` | `worktree` — run in a temporary git worktree; branch and path returned to the caller on exit |
| `background` | `true` — always run as a background task. Subagents run in the background by default (since v2.1.198) unless Claude needs the result immediately |
| `color` | Display color in the task list/transcript (`red`, `blue`, `green`, …) |

## Built-in subagents

Claude Code ships `Explore` (read-only search/analysis), `Plan` (research during plan mode), and `general-purpose` (exploration + modification). Explore and Plan skip CLAUDE.md and git status to stay fast. Explore now **inherits the main conversation's model** (capped at Opus), not a fixed Haiku — define a project/user subagent named `Explore` with `model: haiku` if you want the old cheap-scan behavior.

## Model tiering for subagents

- **Haiku** (`haiku`) — read-only scans, grep/glob searches, file counts, cheap classification. Fastest and cheapest.
- **Sonnet** (`sonnet`) — default worker for most implementation, review, and analysis tasks. Good balance of cost and capability.
- **Opus** (`opus`) — complex multi-step reasoning, architectural decisions, tasks that must get it right the first time.
- **Fable** (`fable`) — maximum capability; reserve for the hardest reasoning tasks where cost is secondary to quality.

Set `model: haiku` explicitly on custom read-only scanner agents; let implementation agents default to `sonnet` via `inherit`. Bump to `opus` or `fable` only when the task demonstrably needs it.

## When to use a subagent

- A side task would flood the main context with file contents, search hits, or logs that are not referenced again.
- The work needs a different tool-set, a different model (e.g. Haiku for cheap scans), or a separate permission profile.
- The task is breadth-first: three or more independent queries that can run in parallel.
- Verification after implementation — a fresh context is less biased toward the code it just wrote (the bundled `/code-review` skill runs this pattern).
- A repeated worker with the same instructions — formalize it as a named subagent under `.claude/agents/`.

## Delegation heuristics

- Prefer a direct tool call for one-shot reads (`Read`, `Grep` with a known path). Subagents add latency and tokens.
- Dispatch via the `Agent` tool (renamed from `Task` in v2.1.63; old references still work) when the investigation needs many reads, unbounded exploration, or its own filesystem/network permissions.
- Parallel vs. serial: run in parallel when subtasks are independent; serialize when a later task depends on the earlier result.
- Split research from implementation — one subagent explores and summarizes, the main agent (or another subagent) implements against that summary.
- Use `context: fork` on a skill when the skill itself is the task and it benefits from isolation.
- For adversarial review, spawn a fresh subagent that sees only the diff and stated criteria, not the reasoning that produced the change — ask it to report gaps, not style preferences.

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

The main agent waits once, then relays a consolidated summary — it does not narrate each subagent's progress. Subagents run in the background by default, so the caller can keep working while they run.

## Limits

- Nested subagent spawning defaults to depth 3 (`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`); still discouraged (see Anti-patterns).
- Concurrent subagents default to 20 (`CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`); per-session spawn cap defaults to 200 (`CLAUDE_CODE_MAX_SUBAGENTS_PER_SESSION`).

## Recommendations

- Give each subagent a written objective, output contract, and length cap — vague prompts waste tokens.
- Parallelize independent investigations; serialize only on real dependencies.
- Scope tool access per subagent: read-only agents list only `Read, Grep, Glob, Bash`; write-capable agents require a deliberate carve-out.
- Route high-volume or low-stakes work to Haiku via the subagent's `model:` field.
- Preserve important facts by having subagents persist artifacts (files, memory) rather than stuffing them back into the main context.
- Reuse frequently-spawned workers as named subagents in `.claude/agents/<name>.md` with a clear `description:` so the main agent picks them deterministically.

## Anti-patterns

- Subagents dispatching other subagents — nesting is supported up to depth 3 by default but remains discouraged; nested fan-out multiplies context cost and latency unpredictably.
- The main agent narrating subagent work step-by-step instead of relaying the final summary.
- Dispatching a subagent for a task that is one tool call — the overhead dwarfs the work.
- Vague prompts like "research X" with no output format — produces redundant searches and unfocused summaries.
- Unbounded spawning — e.g. 50 subagents for a simple query; cap the fan-out in the orchestrator prompt.
- "Endless search" loops where the subagent scours for sources that do not exist; include a stop condition.
- Duplicate work from overlapping task boundaries — partition the problem space explicitly.
- Write-capable subagents invoked without parsing a contracted output — "run it and hope" corrupts state silently.
