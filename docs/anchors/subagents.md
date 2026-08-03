---
name: subagents
description: Subagent orchestration patterns for Claude Code — when to delegate, how to structure, and what to avoid
last_updated: 2026-08-03
sources:
  - https://docs.claude.com/en/docs/claude-code/sub-agents
  - https://www.anthropic.com/engineering/multi-agent-research-system
  - https://www.anthropic.com/engineering/claude-code-best-practices
version: 3
---

## Named subagent frontmatter fields

Named subagents live at `.claude/agents/<name>.md` with YAML frontmatter. Only `name` and `description` are required. Other fields:

| Field | Purpose |
|---|---|
| `model` | Model to run this agent on. Accepts aliases (`fable`, `opus`, `sonnet`, `haiku`) or full IDs. Defaults to `inherit` (uses the invoking context's model). |
| `disallowedTools` | Comma-separated list of tools the subagent cannot call, even if its `tools:` whitelist includes them. |
| `permissionMode` | `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, or `plan`. Ignored if the parent session is in `bypassPermissions`/`acceptEdits`/`auto` (parent takes precedence). |
| `mcpServers` | MCP servers available only to this subagent — inline definitions or references to already-configured servers. Keeps their tool schemas out of the main conversation's context. |
| `maxTurns` | Maximum number of agentic turns before the subagent is forced to return. Prevents runaway loops. |
| `skills` | Comma-separated skill slugs to preload (full content, not just description) into the subagent's context. |
| `memory` | `user` / `project` / `local` — persistent memory scope surviving across conversations. Default: unset (no persistent memory). |
| `effort` | `low` / `medium` / `high` / `xhigh` / `max` — thinking budget hint passed to the model. |
| `isolation` | `worktree` — run the subagent in a temporary git worktree; branch and path returned to the caller on exit. |
| `background` | `true` — always run in the background. Unset defers to Claude, which runs subagents in the background **by default** since v2.1.198. |
| `color` | Display color for the subagent in the task list and transcript. |
| `initialPrompt` | Auto-submitted as the first user turn when this agent runs as the main session agent via `--agent`. |

## Foreground vs. background execution

As of v2.1.198, subagents run **in the background by default**; Claude only runs one in the foreground when it needs the result before continuing. This matters for authoring: a background subagent gets a *smaller* built-in tool set than a foreground one (it keeps `Read`, `Grep`, `Glob`, `Bash`, `PowerShell`, `Edit`, `Write`, `NotebookEdit`, `WebFetch`, `WebSearch`, `TodoWrite`, `Skill`, and every MCP tool, but loses most other built-ins). If a subagent's job needs a tool outside that set, either force `background: false`-equivalent behavior by design (the field only forces background *on*, not off) or design the task so Claude needs the result immediately, which keeps it in the foreground.

## Model tiering for subagents

- **Haiku** (`haiku`) — read-only scans, grep/glob searches, file counts, cheap classification. Fastest and cheapest.
- **Sonnet** (`sonnet`) — default worker for most implementation, review, and analysis tasks. Good balance of cost and capability.
- **Opus** (`opus`) — complex multi-step reasoning, architectural decisions, tasks that must get it right the first time.
- **Fable** (`fable`) — maximum capability; reserve for the hardest reasoning tasks where cost is secondary to quality.

Set `model: haiku` on read-only scanner agents; let implementation agents default to `sonnet` via `inherit`. Bump to `opus` or `fable` only when the task demonstrably needs it. Note: the built-in `Explore` agent now inherits the main conversation's model (capped at Opus on the Claude API) rather than always running on Haiku — define a project/user agent named `Explore` with `model: haiku` if you want exploration to stay on a cheap model.

## When to use a subagent

- A side task would flood the main context with file contents, search hits, or logs that are not referenced again.
- The work needs a different tool-set, a different model (e.g. Haiku for cheap scans), or a separate permission profile.
- The task is breadth-first: three or more independent queries that can run in parallel. Anthropic's multi-agent research system saw parallel decomposition outperform single-agent runs by ~90% on complex breadth-first queries.
- Verification after implementation — a fresh context is less biased toward the code it just wrote.
- A repeated worker with the same instructions — formalize it as a named subagent under `.claude/agents/`.

## Delegation heuristics

- Prefer a direct tool call for one-shot reads (`Read`, `Grep` with a known path). Subagents add latency and tokens.
- Scale fan-out to task complexity: a simple query needs one agent with 3–10 tool calls; complex research needs 10+ subagents with divided responsibilities.
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

Within a subagent, prefer a broad-to-narrow search strategy: start with short, broad queries, evaluate what's available, then progressively narrow focus — this out-performs committing to a single narrow query up front.

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
- Don't fully trust a subagent's final report: Claude Code scans it for instruction-shaped text (e.g. fake `<system-reminder>` tags) before Claude reads it, but that scan doesn't judge intent — restrict a subagent's own tool/permission scope rather than relying on output scanning as your only defense.

## Anti-patterns

- Subagents dispatching other subagents — nesting is supported up to depth 3 (raised from depth 1) but remains discouraged; nested fan-out multiplies context cost and latency unpredictably. `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=1` restores the old limit.
- The main agent narrating subagent work step-by-step instead of relaying the final summary.
- Dispatching a subagent for a task that is one tool call — the overhead dwarfs the work.
- Vague prompts like "research X" with no output format — produces redundant searches and unfocused summaries.
- Unbounded spawning — e.g. 50 subagents for a simple query; cap the fan-out in the orchestrator prompt.
- "Endless search" loops where the subagent scours for sources that do not exist; include a stop condition.
- Duplicate work from overlapping task boundaries — partition the problem space explicitly.
- Write-capable subagents invoked without parsing a contracted output — "run it and hope" corrupts state silently.
