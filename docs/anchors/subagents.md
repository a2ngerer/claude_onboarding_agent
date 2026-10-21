---
name: subagents
description: Subagent orchestration patterns for Claude Code — when to delegate, how to structure, and what to avoid
last_updated: 2026-10-21
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
| `name`, `description` | Required. `description` tells Claude when to delegate. Unrecognized fields are silently ignored. |
| `tools` | Allowlist (comma-separated or YAML list). Inherits all subagent-available tools if omitted. |
| `model` | `sonnet`, `opus`, `haiku`, `fable`, a full model ID, or `inherit`. |
| `disallowedTools` | Denylist, applied before `tools`. An entry with a specifier like `Bash(git push *)` still removes the whole tool. |
| `permissionMode` | `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, `plan`, or `manual`. Ignored for plugin subagents. |
| `maxTurns` | Maximum agentic turns before the subagent stops; output is marked partial and can be resumed. |
| `autoCompactWindow` | Auto-compact window (`100000`–`1000000`, plain integer). Requires v2.1.296+. |
| `skills` | Skills whose full content is preloaded at startup (at most 32). |
| `mcpServers`, `hooks` | Server references / lifecycle hooks scoped to this subagent. Ignored for plugin subagents. |
| `memory` | Persistent memory scope: `user`, `project`, or `local`. |
| `effort` | `low` / `medium` / `high` / `xhigh` / `max` — thinking budget hint. |
| `isolation` | `worktree` — run the subagent in a temporary git worktree. |
| `background` | `true` keeps the subagent in the background even when Claude asks to wait. |
| `omitClaudeMd` | `true` skips user, project, and local CLAUDE.md files at startup. Requires v2.1.271+. |
| `color`, `initialPrompt`, `experimental` | Display color; first user turn when run as the main session agent; `experimental.cacheTtl` (`5m` / `1h`). |

Model resolution order: per-invocation `model` parameter → subagent `model` frontmatter → `CLAUDE_CODE_SUBAGENT_MODEL` → main conversation's model. Set `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` to force one model on every subagent.

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

## Delegation heuristics

- Prefer a direct tool call for one-shot reads (`Read`, `Grep` with a known path). Subagents add latency and tokens.
- Dispatch via the `Agent` tool when the investigation needs many reads, unbounded exploration, or its own filesystem/network permissions.
- Parallel vs. serial: run in parallel when subtasks are independent; serialize when a later task depends on the earlier result.
- Split research from implementation — one subagent explores and summarizes, the main agent (or another subagent) implements against that summary.
- Use `context: fork` on a skill when the skill itself is the task and it benefits from isolation. Fork subagents (`subagent_type: "fork"`) inherit the parent's context and are on by default in `-p`, the Agent SDK, desktop, and VS Code.

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

- Subagents dispatching other subagents — nesting is allowed up to three layers by default (`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`; `1` turns it off) but remains strongly discouraged; nested fan-out multiplies context cost and latency unpredictably. Omit `Agent` from a subagent's `tools` to stop it spawning. `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` (default 20) caps simultaneous subagents.
- The main agent narrating subagent work step-by-step instead of relaying the final summary.
- Dispatching a subagent for a task that is one tool call — the overhead dwarfs the work.
- Vague prompts like "research X" with no output format — produces redundant searches and unfocused summaries.
- Unbounded spawning — e.g. 50 subagents for a simple query; cap the fan-out in the orchestrator prompt.
- "Endless search" loops where the subagent scours for sources that do not exist; include a stop condition.
- Duplicate work from overlapping task boundaries — partition the problem space explicitly.
- Write-capable subagents invoked without parsing a contracted output — "run it and hope" corrupts state silently.
