---
name: subagents
description: Subagent orchestration patterns for Claude Code — when to delegate, how to structure, and what to avoid
last_updated: 2026-05-07
sources:
  - https://docs.claude.com/en/docs/claude-code/sub-agents
  - https://www.anthropic.com/engineering/multi-agent-research-system
  - https://www.anthropic.com/engineering/claude-code-best-practices
version: 2
---

## Built-in subagents

Claude Code ships built-in subagents that are invoked automatically:

| Name | Model | Tools | Purpose |
|---|---|---|---|
| `Explore` | Haiku | Read-only | Fast codebase search and analysis |
| `Plan` | Inherits | Read-only | Research during plan mode |
| `general-purpose` | Inherits | All | Complex multi-step research and implementation |
| `statusline-setup` | Sonnet | — | Configure status line (`/statusline`) |
| `claude-code-guide` | Haiku | — | Answer questions about Claude Code features |

Custom subagents supplement these. Subagents run within a single session. For multiple agents communicating across separate sessions, see agent teams.

## When to use a subagent

- A side task would flood the main context with file contents, search hits, or logs not referenced again.
- The work needs a different tool-set, a different model (e.g. Haiku for cheap scans), or a separate permission profile.
- The task is breadth-first: three or more independent queries that can run in parallel.
- Verification after implementation — a fresh context is less biased toward the code it just wrote.
- A repeated worker with the same instructions — formalize it as a named subagent under `.claude/agents/`.

## Subagent file format

Store subagent files in `.claude/agents/<name>.md` (project) or `~/.claude/agents/<name>.md` (user). Plugin subagents live in the plugin's `agents/` directory.

```
---
name: code-reviewer
description: Reviews code for quality and best practices. Use after code changes.
tools: Read, Glob, Grep
model: sonnet
---

You are a code reviewer...
```

### Frontmatter fields

| Field | Description |
|---|---|
| `name` | Required. Lowercase letters and hyphens. |
| `description` | Required. When Claude should delegate to this subagent. |
| `tools` | Allowed tools; inherits all if omitted. Also `disallowedTools` to remove from inherited set. |
| `model` | `sonnet`, `opus`, `haiku`, a full model ID, or `inherit` (default). |
| `permissionMode` | `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, or `plan`. |
| `maxTurns` | Maximum agentic turns before the subagent stops. |
| `skills` | List of skill names to preload (full content injected at startup). |
| `mcpServers` | Server names referencing configured servers, or inline server definitions. |
| `hooks` | Lifecycle hooks scoped to this subagent. |
| `memory` | `user`, `project`, or `local` — enables cross-session learning in a persistent memory dir. |
| `background` | `true` to always run as a background task. |
| `effort` | Effort level override: `low`, `medium`, `high`, `xhigh`, `max`. |
| `isolation` | `worktree` to run in a temporary isolated git worktree (auto-cleaned if no changes made). |
| `color` | Display color in the task list: `red`, `blue`, `green`, `yellow`, `purple`, `orange`, `pink`, `cyan`. |

## Delegation heuristics

- Prefer a direct tool call for one-shot reads. Subagents add latency and tokens.
- Dispatch via the `Agent` tool when the investigation needs many reads, unbounded exploration, or its own permissions.
- Parallel vs. serial: run in parallel when subtasks are independent; serialize when a later task depends on the earlier result.
- Split research from implementation — one subagent explores and summarizes, another implements.
- Use `isolation: worktree` when the subagent needs an isolated repo copy (e.g. risky modifications).

## Prompting a subagent

Every subagent prompt MUST contain:

1. Goal — one sentence naming the outcome.
2. Known context — files already read, decisions made, constraints.
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

The main agent waits once, then relays a consolidated summary.

## Recommendations

- Give each subagent a written objective, output contract, and length cap.
- Parallelize independent investigations; serialize only on real dependencies.
- Scope tool access per subagent: read-only agents list only `Read, Grep, Glob, Bash`.
- Route high-volume or low-stakes work to Haiku via the subagent's `model:` field.
- Use `memory: project` on frequently-spawned workers to accumulate codebase knowledge across sessions.
- Reuse frequently-spawned workers as named subagents with a clear `description:`.

## Anti-patterns

- Subagents dispatching other subagents — nested fan-out blows up context and latency; subagents cannot spawn subagents.
- The main agent narrating subagent work step-by-step instead of relaying the final summary.
- Dispatching a subagent for a task that is one tool call.
- Vague prompts like "research X" with no output format.
- Unbounded spawning — cap the fan-out in the orchestrator prompt.
- "Endless search" loops without a stop condition.
- Write-capable subagents invoked without parsing a contracted output — "run it and hope" corrupts state silently.
