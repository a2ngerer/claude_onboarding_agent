---
name: subagents
description: Subagent orchestration patterns for Claude Code — when to delegate, how to structure, and what to avoid
last_updated: 2026-04-30
sources:
  - https://docs.claude.com/en/docs/claude-code/sub-agents
  - https://www.anthropic.com/engineering/multi-agent-research-system
  - https://www.anthropic.com/engineering/claude-code-best-practices
version: 2
---

## When to use a subagent

- A side task would flood the main context with file contents, search hits, or logs that are not referenced again.
- The work needs a different tool-set, a different model (e.g. Haiku for cheap scans), or a separate permission profile.
- The task is breadth-first: three or more independent queries that can run in parallel.
- Verification after implementation — a fresh context is less biased toward the code it just wrote.
- A repeated worker with the same instructions — formalize it as a named subagent under `.claude/agents/`.

## Built-in subagents

Claude Code ships three built-in subagents dispatched automatically:

| Name | Model | Tools | Purpose |
|---|---|---|---|
| `Explore` | Haiku | read-only | File discovery and codebase search |
| `Plan` | inherit | read-only | Research during plan mode |
| `general-purpose` | inherit | all | Complex multi-step tasks requiring both exploration and action |

## Defining custom subagents

Subagents are Markdown files with YAML frontmatter in `.claude/agents/<name>.md` (project) or `~/.claude/agents/<name>.md` (user). The file body is the system prompt. Key frontmatter fields:

| Field | Purpose |
|---|---|
| `name` | Unique kebab-case identifier |
| `description` | When Claude should delegate here |
| `tools` | Allowlist of permitted tools (inherits all if omitted) |
| `disallowedTools` | Denylist removed from the inherited set |
| `model` | `sonnet`, `opus`, `haiku`, a full model ID, or `inherit` |
| `permissionMode` | `default`, `acceptEdits`, `auto`, `bypassPermissions`, `plan` |
| `maxTurns` | Maximum agentic turns before stopping |
| `skills` | Skills to preload into subagent context at startup (full content injected) |
| `mcpServers` | MCP servers available to this subagent |
| `hooks` | Lifecycle hooks scoped to this subagent |
| `memory` | `user`, `project`, or `local` — persistent cross-session notes |
| `isolation` | `worktree` — runs in a temp git worktree; auto-cleaned if no changes made |
| `background` | `true` — always runs as a background task |
| `effort` | Override effort level (`low`, `medium`, `high`, `xhigh`, `max`) |
| `color` | Display color in the task list (`red`, `blue`, `green`, `yellow`, `purple`, etc.) |

## Delegation heuristics

- Prefer a direct tool call for one-shot reads (`Read`, `Grep` with a known path). Subagents add latency and tokens.
- Dispatch via the `Agent` tool when the investigation needs many reads, unbounded exploration, or its own permissions.
- Parallel vs. serial: run in parallel when subtasks are independent; serialize when a later task depends on the earlier result.
- Split research from implementation — one subagent explores and summarizes, the main agent implements against that summary.
- Use `context: fork` on a skill when the skill itself is the task and benefits from isolation.

## Prompting a subagent

Every subagent prompt MUST contain:

1. Goal — one sentence naming the outcome.
2. Known context — files already read, decisions already made, constraints.
3. Output format — exact shape of the reply (bullet list, fenced block, field names).
4. Length cap — "< 200 words" or "≤ 5 bullets" to prevent drift.
5. Stop conditions — when to return with partial results (e.g. "if no matches in 3 globs, report empty").

## Agent teams vs. subagents

Subagents work **within** a single session (nested delegation, max one level deep). Agent teams coordinate **across** separate sessions: teammates can message each other, share a task queue, and run in parallel on long-horizon work. Use subagents for isolated sub-tasks; use agent teams when multiple agents need to communicate.

## Recommendations

- Give each subagent a written objective, output contract, and length cap — vague prompts waste tokens.
- Parallelize independent investigations; serialize only on real dependencies.
- Scope tool access per subagent: read-only agents list only `Read, Grep, Glob, Bash`; write-capable require a deliberate carve-out.
- Route high-volume or low-stakes work to Haiku via the subagent's `model:` field.
- Use `memory: user` on subagents you repeatedly invoke to accumulate cross-session domain knowledge.
- Use `isolation: worktree` when the subagent will make file changes that should be reviewed before merging.
- Reuse frequently-spawned workers as named subagents in `.claude/agents/<name>.md` with a clear `description:`.

## Anti-patterns

- Subagents dispatching other subagents — nested fan-out blows up context and latency.
- The main agent narrating subagent work step-by-step instead of relaying the final summary.
- Dispatching a subagent for a task that is one tool call — the overhead dwarfs the work.
- Vague prompts like "research X" with no output format — produces redundant searches and unfocused summaries.
- Unbounded spawning — e.g. 50 subagents for a simple query; cap the fan-out in the orchestrator prompt.
- "Endless search" loops where the subagent scours for sources that do not exist; include a stop condition.
- Write-capable subagents invoked without parsing a contracted output — "run it and hope" corrupts state silently.
