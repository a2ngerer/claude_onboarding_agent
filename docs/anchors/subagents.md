---
name: subagents
description: Subagent orchestration patterns for Claude Code — when to delegate, how to structure, and what to avoid
last_updated: 2026-08-29
sources:
  - https://docs.claude.com/en/docs/claude-code/sub-agents
  - https://www.anthropic.com/engineering/multi-agent-research-system
  - https://www.anthropic.com/engineering/claude-code-best-practices
version: 3
---

## Named subagent frontmatter fields

Named subagents live at `.claude/agents/<name>.md` with YAML frontmatter. Key fields:

| Field | Purpose |
|---|---|
| `model` | Model to run this agent on. Accepts aliases (`fable`, `opus`, `sonnet`, `haiku`) or full IDs. Defaults to `inherit`. |
| `tools` / `disallowedTools` | Allowlist / denylist of tools. `disallowedTools` is applied before `tools` resolution; both support MCP patterns (`mcp__server-name`). |
| `permissionMode` | `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, or `plan`. Inherits parent mode if omitted. |
| `maxTurns` | Max agentic turns before stopping; result returns marked partial and can be resumed via `SendMessage`. |
| `skills` | Skill slugs preloaded (full content) into the subagent's context at startup. |
| `memory` | Persistent memory scope: `user`, `project`, or `local`. Default: none. First 200 lines / 25KB of `MEMORY.md` auto-load. |
| `effort` | Thinking-budget override: `low` / `medium` / `high` / `xhigh` / `max`. |
| `isolation` | `worktree` — run in a temporary git worktree branched from the default branch; cleaned up automatically if unchanged. |
| `background` | `true` — keep the subagent in the background even when the caller asks for foreground results. |
| `mcpServers` | MCP servers scoped to the subagent (inline defs or shared references). |
| `hooks` | Lifecycle hooks (`PreToolUse`, `PostToolUse`, `Stop`) scoped to the subagent. |
| `color` / `initialPrompt` / `experimental.cacheTtl` | Display color; auto-submitted first turn when run as a main session; per-agent prompt-cache TTL (e.g. `5m`, `1h`). |

Restrict which subagents a session can spawn with `tools: Agent(worker, researcher), Read, Bash`.

## Model tiering and resolution

- **Haiku** — read-only scans, grep/glob searches, cheap classification.
- **Sonnet** — default worker for most implementation, review, and analysis.
- **Opus** — complex multi-step reasoning, architectural decisions.
- **Fable** — maximum capability; reserve for the hardest reasoning tasks.

Resolution order for a spawned subagent's model: `CLAUDE_CODE_SUBAGENT_MODEL` env var → per-invocation `model` parameter on the Agent call → the subagent definition's `model:` field → the main conversation's model.

## Nesting and concurrency limits

- Max subagent spawn depth defaults to **3** layers below the main conversation (`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`; set to `1` to disable nesting entirely). At the depth limit the `Agent` tool is withheld except from forks.
- Max concurrent subagents defaults to **20** (`CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`); new spawns fail past that.
- `subagent_type: "fork"` inherits the full parent conversation and prompt cache; fork mode is on by default in interactive sessions, so non-teammate agent spawns now run in the background by default unless `background: false`/foreground is forced.

## When to use a subagent

- A side task would flood the main context with file contents, search hits, or logs not referenced again.
- The work needs a different tool-set, model, or permission profile.
- The task is breadth-first. Scale effort to complexity: a simple query needs one agent with ~3–10 tool calls; a comparison needs 2–4 subagents with ~10–15 calls each; complex research uses 10+ subagents with divided responsibilities.
- Verification after implementation — a fresh context is less biased toward code it just wrote (e.g. an adversarial review subagent checking a diff against a plan, or `/code-review`).
- A repeated worker with the same instructions — formalize it as a named subagent under `.claude/agents/`.

## Delegation heuristics

- Prefer a direct tool call for one-shot reads. Subagents add latency and tokens (multi-agent runs can cost roughly 15x a single-turn interaction).
- Dispatch via the `Agent` tool when the investigation needs many reads, unbounded exploration, or its own permissions. The phrase `"use subagents to investigate X"` reliably triggers this.
- Parallel vs. serial: run in parallel when subtasks are independent; serialize when a later task depends on the earlier result.
- Split research from implementation — one subagent explores and summarizes, the main agent implements against that summary.
- Give each subagent an objective, an output format, guidance on which tools/sources to use, and clear task boundaries — vague instructions cause duplicated or missing work.

## Prompting a subagent

Every subagent prompt MUST contain: (1) goal, (2) known context, (3) output format, (4) length cap, (5) stop conditions for returning with partial results.

## Parallel dispatch

Send multiple `Agent` calls in a single message for independent work; the main agent waits once, then relays a consolidated summary rather than narrating each subagent's progress.

## Recommendations

- Give each subagent a written objective, output contract, and length cap.
- Scope tool access per subagent: read-only agents list only `Read, Grep, Glob, Bash`; write-capable agents require a deliberate carve-out.
- Route high-volume or low-stakes work to Haiku via `model:`.
- Persist important facts via subagent memory/artifacts rather than stuffing them back into the main context.
- Reuse frequently-spawned workers as named subagents with a clear `description:` so the main agent picks them deterministically.

## Anti-patterns

- Deep or unbounded nesting — the platform caps spawn depth at 3 and concurrency at 20 by default; treat those as hard backstops, not a target to approach.
- The main agent narrating subagent work step-by-step instead of relaying the final summary.
- Dispatching a subagent for a task that is one tool call.
- Vague prompts like "research X" with no output format.
- "Endless search" loops with no stop condition; scope investigations narrowly.
- Duplicate work from overlapping task boundaries — partition the problem space explicitly.
- Write-capable subagents invoked without parsing a contracted output.
