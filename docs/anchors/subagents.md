---
name: subagents
description: Subagent orchestration patterns for Claude Code — when to delegate, how to structure, and what to avoid
last_updated: 2026-09-08
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
| `model` | Model to run this agent on. Accepts aliases (`fable`, `opus`, `sonnet`, `haiku`), a full model ID, or `inherit` (default; uses the invoking context's model). |
| `tools` | Allowlist of tools the subagent can use; inherits all available tools if omitted. |
| `disallowedTools` | Denylist of tools the subagent cannot call, applied before `tools` is resolved, even if `tools:` includes them. |
| `permissionMode` | Permission mode the subagent runs in: `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, `plan`, or `manual`. Overridden by the parent session's `bypassPermissions`/`acceptEdits`. |
| `maxTurns` | Maximum number of agentic turns before the subagent is forced to return (marked partial; can be resumed). Prevents runaway loops. |
| `skills` | List of skill names to preload (full content, not just descriptions) into the subagent's context at startup. |
| `mcpServers` | MCP servers available to this subagent (by name, or an inline definition). Ignored for plugin subagents. |
| `hooks` | Lifecycle hooks scoped to this subagent (`PreToolUse`, `PostToolUse`, `Stop`). Ignored for plugin subagents. |
| `memory` | `user` / `project` / `local` — persistent memory scope enabling cross-session learning; omit for no persistent memory (default for read-only agents). |
| `effort` | `low` / `medium` / `high` / `xhigh` / `max` — thinking budget hint, overrides the session's effort level. |
| `isolation` | `worktree` — run the subagent in a temporary git worktree; branch and path returned to the caller on exit. |
| `background` | `true` — keep the subagent in the background even when foreground execution is requested; caller is notified on completion. |
| `color` | Display color in the task list and transcript (`red`, `blue`, `green`, `yellow`, `purple`, `orange`, `pink`, `cyan`). |
| `initialPrompt` | Auto-submitted as the first user turn when this agent runs as the main session agent (via `--agent` or the `agent` setting). |
| `experimental.cacheTtl` | `5m` or `1h` — prompt-cache lifetime override for this subagent. |

**Model resolution order** when a subagent's model is ambiguous: (1) a per-invocation `model` parameter passed to the Agent tool, (2) the subagent's `model:` frontmatter (`inherit` selects the main conversation's model), (3) the `CLAUDE_CODE_SUBAGENT_MODEL` env var, (4) the main conversation's model. Setting `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` alongside `CLAUDE_CODE_SUBAGENT_MODEL` overrides every subagent to one model regardless of the above.

## Model tiering for subagents

- **Haiku** (`haiku`) — read-only scans, grep/glob searches, file counts, cheap classification. Fastest and cheapest.
- **Sonnet** (`sonnet`) — default worker for most implementation, review, and analysis tasks. Good balance of cost and capability.
- **Opus** (`opus`) — complex multi-step reasoning, architectural decisions, tasks that must get it right the first time.
- **Fable** (`fable`) — maximum capability; reserve for the hardest reasoning tasks where cost is secondary to quality.

Set `model: haiku` on read-only scanner agents; let implementation agents default to `sonnet` via `inherit`. Bump to `opus` or `fable` only when the task demonstrably needs it. For orchestrators dispatching varied subtasks, the Claude Code team has suggested letting the orchestrating model itself judge which lower-power model fits each subtask, rather than hard-coding a tier per agent — useful when subtask difficulty varies a lot within one workflow.

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

- Subagents dispatching other subagents — nesting is technically supported up to 5 levels (since v2.1.172) but remains strongly discouraged; nested fan-out multiplies context cost and latency unpredictably.
- The main agent narrating subagent work step-by-step instead of relaying the final summary.
- Dispatching a subagent for a task that is one tool call — the overhead dwarfs the work.
- Vague prompts like "research X" with no output format — produces redundant searches and unfocused summaries.
- Unbounded spawning — e.g. 50 subagents for a simple query; cap the fan-out in the orchestrator prompt.
- "Endless search" loops where the subagent scours for sources that do not exist; include a stop condition.
- Duplicate work from overlapping task boundaries — partition the problem space explicitly.
- Write-capable subagents invoked without parsing a contracted output — "run it and hope" corrupts state silently.
