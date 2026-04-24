---
name: subagents
description: Subagent orchestration patterns for Claude Code — when to delegate, how to structure, and what to avoid
last_updated: 2026-04-24
sources:
  - https://docs.claude.com/en/docs/claude-code/sub-agents
  - https://www.anthropic.com/engineering/multi-agent-research-system
  - https://www.anthropic.com/engineering/claude-code-best-practices
version: 2
---

## Built-in subagents

Claude Code ships named subagents that Claude uses automatically:

| Subagent | Model | Tools | When Claude uses it |
|---|---|---|---|
| `Explore` | Haiku | Read-only | File search and codebase exploration (quick / medium / very thorough) |
| `Plan` | Inherits | Read-only | Codebase research during plan mode |
| `general-purpose` | Inherits | All | Complex multi-step tasks needing both exploration and action |

## Agent teams vs subagents

**Subagents** work within a single session — Claude delegates a task and the subagent returns a summary. **Agent teams** coordinate multiple agents across separate sessions in parallel and can communicate with each other. Use agent teams for problems requiring true parallel long-running execution; use subagents for context isolation within one session.

## When to use a subagent

- A side task would flood the main context with file contents, search hits, or logs not referenced again.
- The work needs a different tool-set, a different model (e.g. Haiku for cheap scans), or a separate permission profile.
- The task is breadth-first: three or more independent queries that can run in parallel.
- Verification after implementation — a fresh context is less biased toward the code it just wrote.
- A repeated worker with the same instructions — formalize it as a named subagent under `.claude/agents/`.

## Subagent configuration

Subagent files (`<name>.md`) live at `.claude/agents/` (project) or `~/.claude/agents/` (user). Managed (org-wide) > CLI `--agents` > project > user > plugin priority. Key frontmatter fields:

```yaml
---
name: my-agent
description: "Use to … (trigger phrases, concrete examples)"
tools: Read, Grep, Glob, Bash
model: haiku          # or sonnet, opus, inherit
permissionMode: acceptEdits
maxTurns: 20
memory: { scope: project }   # persistent auto-memory directory
hooks: {}                    # lifecycle hooks scoped to this agent
color: blue
---
```

- `/agents` command opens a management UI (create, edit, delete, view running agents).
- `claude agents` (CLI, no session) lists all configured subagents.
- `--agents` JSON flag defines session-scoped subagents without saving to disk; supports all frontmatter fields.
- `--agent <name>` and `--print` mode both honor the agent's `permissionMode` and `tools:`/`disallowedTools:` frontmatter.

**Persistent memory:** `memory: { scope: project }` or `scope: user` gives a subagent its own auto-memory directory, accumulating domain knowledge across sessions without polluting main conversation memory.

## Delegation heuristics

- Prefer a direct tool call for one-shot reads (`Read`, `Grep` with a known path). Subagents add latency and tokens.
- Dispatch via the `Agent` tool when the investigation needs many reads, unbounded exploration, or its own permissions.
- Parallel vs. serial: run in parallel when subtasks are independent; serialize when a later task depends on the earlier result.
- Split research from implementation — one subagent explores and summarizes, the main agent (or another subagent) implements.
- Use `context: fork` on a skill when the skill itself is the task and benefits from isolation.

## Prompting a subagent

Every subagent prompt MUST contain:

1. Goal — one sentence naming the outcome.
2. Known context — files already read, decisions already made, constraints.
3. Output format — exact shape of the reply (bullet list, fenced block, field names).
4. Length cap — "< 200 words" or "≤ 5 bullets" to prevent drift.
5. Stop conditions — when to return with partial results.

## Recommendations

- Give each subagent a written objective, output contract, and length cap — vague prompts waste tokens.
- Parallelize independent investigations; serialize only on real dependencies.
- Scope tool access per subagent: read-only agents list only `Read, Grep, Glob, Bash`.
- Route high-volume or low-stakes work to Haiku via `model: haiku`.
- Preserve important facts via persistent memory or written artifacts rather than stuffing summaries into main context.
- Reuse frequently-spawned workers as named subagents with a clear `description:` so Claude picks them deterministically.

## Anti-patterns

- Subagents dispatching other subagents — nesting is blocked by design; use agent teams for true fan-out.
- The main agent narrating subagent work step-by-step instead of relaying the final summary.
- Dispatching a subagent for a task that is one tool call — overhead dwarfs the work.
- Vague prompts like "research X" with no output format — produces redundant searches and unfocused summaries.
- Unbounded spawning — cap fan-out in the orchestrator prompt.
- "Endless search" loops without a stop condition.
- Overlapping task boundaries causing duplicate work — partition the problem space explicitly.
- Write-capable subagents invoked without parsing a contracted output — "run it and hope" corrupts state silently.
