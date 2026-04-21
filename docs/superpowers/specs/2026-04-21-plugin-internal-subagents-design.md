# Plugin-Internal Subagents — Design

**Date:** 2026-04-21
**Status:** Draft
**Scope:** Introduce plugin-internal Claude Code subagents as first-class primitives of the onboarding-agent plugin. Scaffolding only — this initiative creates the subagent files and authoring conventions; consumer refactors (onboarding orchestrator, upgrade planner) follow in separate initiatives.

## Motivation

Several plugin skills currently perform large read-heavy operations in the main conversation context:

- `onboarding/SKILL.md` Step 2 scans the user's repository for language, framework, and corpus signals. The scan reads many paths, greps manifests, and counts files — all in the main context window, where every tool result stays visible for the remainder of the session.
- `upgrade/SKILL.md` Pass 2 enumerates every delimited section across `CLAUDE.md`, `AGENTS.md`, `.gitignore`, `.claude/settings.json`, and `.claude/rules/*.md`, then diffs each one against the canonical template. This is the heaviest main-context read-phase the plugin performs.

Both operations share the same shape: **read many files, return a compact structured report, let the caller act on it**. That is the canonical subagent use case. A subagent runs in an isolated context, returns a short summary to the parent, and releases the intermediate file reads from the parent's token budget.

Shipping subagents alongside skills also aligns the plugin with idiomatic Claude Code primitives (`.claude/agents/<name>.md`), matching the direction already taken for `.claude/commands/` and `.claude/hooks/`.

## Decision

### Subagent Catalog

Two subagents ship in v1. The catalog is intentionally small — YAGNI. Future additions go through a spec update.

| Name | Purpose | Tool-set | Model | Triggered by |
|---|---|---|---|---|
| `repo-scanner` | Scan a user repository for language, framework, corpus-size, and use-case signals. Returns a single structured report (inferred use case, signal list, `graphify_candidate` flag). | `Bash`, `Glob`, `Grep`, `Read` | opus | `onboarding` (Step 2 scan), `checkup` Gate G4 (soft re-scan), `tipps` (environmental context) |
| `upgrade-planner` | Enumerate plugin-owned delimited sections across a user project, diff each against the canonical current template, and return the list of proposed changes (one entry per non-empty diff). | `Bash`, `Glob`, `Grep`, `Read` | opus | `upgrade` (Pass 2 planning), `checkup` Stage 4 (optional — judgment signal only) |

**Rejected candidates (kept out of v1):**

- `setup-verifier` — "Did the setup skill produce artifacts that match the spec?" overlaps heavily with `/tipps` (audit). Without a clear consumer in this initiative, it would ship unused. Revisit if and when a concrete caller emerges.
- `docs-composer` — "Compose a CLAUDE.md section from multiple inputs" is already the primary job of each setup skill. A composer subagent would either duplicate that work or force skills to delegate their core artifact — both violate DRY. Rejected.

Both rejections follow the same rule: a subagent earns its slot only when a concrete caller in this repository would invoke it. Speculative capabilities belong in a follow-up spec, not v1.

### Tool-Set Policy

Both v1 subagents are **read-only**. Neither may `Write` nor `Edit`. Rationale:

- The parent skill owns the artifact contract (which files exist, which delimiters, which content). Subagents returning proposed writes is harder to reason about than subagents returning structured reports the parent applies.
- Read-only tool-sets are safer to delegate and easier to test: a malformed subagent reply cannot corrupt user files directly.
- `Bash` is included for `find`/`ls`/`wc -l`/`git ls-files` — these are read operations in the scanning context, not write operations. Subagent prompts explicitly forbid destructive bash (no `rm`, `mv`, `>`-redirects, `git commit`).

Any future write-capable subagent requires a spec update and an explicit carve-out for its tool-set.

### Model Choice

Both subagents use `opus`. Rationale:

- Signal inference (repo-scanner) and structural diffing (upgrade-planner) benefit from stronger reasoning. The token savings from subagent-level isolation are the point; using a weaker model on top would negate the quality.
- Consistency with the parent skills, which are already run on opus by users who have this plugin installed.

If future telemetry shows either subagent is latency-bound, downgrading a single subagent's frontmatter `model:` field is a one-line change.

### Manifest Integration

The plugin ships subagents as files in `.claude/agents/<name>.md` in the plugin root. Claude Code discovers these by convention at plugin-load time — the same convention used for `.claude/commands/` and `.claude/hooks/`, neither of which is listed in `plugin.json`.

**`.claude-plugin/plugin.json` is NOT modified by this initiative.** The current manifest schema lists `skills[]` and `commands[]`. No verified `agents[]` field exists in the plugin manifest schema today. Introducing an unsupported field risks validation failure in strict loaders. Convention-based discovery is sufficient.

If a future Claude Code release adds an explicit `agents[]` manifest field, a follow-up spec can register the subagents explicitly. That change is cosmetic — the subagent files themselves would not move.

### Invocation Pattern (for consumers)

Consumer skills dispatch a subagent via the Agent tool. The exact invocation pattern all consumer skills use:

```
Use the Agent tool with:
  subagent_type: repo-scanner
  description: "Scan the current project for use-case signals"
  prompt: |
    Scan the project rooted at <cwd> and return a single fenced code block
    tagged `repo-scan` containing:

      inferred_use_case: <one of: coding|web-development|data-science|...|unknown>
      signals: [<list>]
      graphify_candidate: <true|false>
      existing_claude_md: <true|false>
      existing_agents_md: <true|false>

    Do not write any files. Do not modify the project.
```

The subagent's SKILL-like body defines the structured output format; consumers parse it and continue. Parent skills MUST NOT call subagents recursively from within a subagent — nested dispatch blows up context budgets and creates hard-to-diagnose failures.

## Subagent File Format

Each subagent lives at `.claude/agents/<name>.md` with frontmatter and a body prompt. Canonical shape:

```markdown
---
name: repo-scanner
description: Read-only subagent that scans a user project for language, framework, and corpus signals. Returns a single structured report.
tools: Bash, Glob, Grep, Read
model: opus
---

# Repo Scanner

Role, inputs, output contract, constraints.
```

**Frontmatter fields:**

- `name` — must match the filename stem exactly.
- `description` — one sentence, includes "read-only" when applicable. Used by Claude Code when auto-selecting a subagent for the `subagent_type`.
- `tools` — comma-separated whitelist. Omitting this field grants all tools; this initiative always sets it explicitly to enforce the read-only contract.
- `model` — `opus` for both v1 subagents.

**Body structure:**

1. Role paragraph — one sentence on what this subagent does and what it does NOT do.
2. Inputs — what the caller provides in the `prompt:` field.
3. Output contract — exact fenced-block format, including the code-fence tag and every field.
4. Constraints — the "never do X" list (no writes, no recursive dispatch, no destructive bash).
5. Failure mode — what to return if the task cannot be completed (e.g., "unknown" for missing signals, never a partial silent result).

## File Layout

**New files:**

- `.claude/agents/repo-scanner.md`
- `.claude/agents/upgrade-planner.md`

**Modified files:**

- `CLAUDE.md` (repo root) — add a "Subagent Authoring Rules" subsection under "Skill Authoring Rules" documenting the file format, tool-set policy, and invocation pattern above.

**Unchanged:**

- `.claude-plugin/plugin.json` — no manifest change (see Manifest Integration).
- All existing skill files — consumers are not refactored in this initiative.
- All existing commands under `.claude/commands/` — unchanged.

## Consumer Integration

This initiative ships the subagents and the authoring docs. It does **not** refactor any skill to call the new subagents. That is tracked separately:

- Initiative #7 (Onboarding Orchestrator Refactor) will rewrite `onboarding/SKILL.md` Step 2 to dispatch `repo-scanner` instead of scanning inline. That initiative depends on this one.
- A future follow-up (not yet filed) will refactor `upgrade/SKILL.md` Pass 2 to dispatch `upgrade-planner`. Out of scope here.

Until those refactors ship, the subagent files exist but have zero production callers. This is deliberate — decoupling the primitive from its consumers keeps each change small and reviewable.

Example invocation, for reference (not wired up in this initiative):

```
# From onboarding/SKILL.md (future form — NOT added in this initiative)

### Step 2: Scan the Repository

Dispatch the `repo-scanner` subagent via the Agent tool:

  subagent_type: repo-scanner
  description: "Scan the user's repo for use-case signals"
  prompt: |
    Scan the current working directory. Return your standard report.

Parse the `repo-scan` fenced block from the subagent's reply. Use the
returned `inferred_use_case` and `signals` to populate HANDOFF_CONTEXT.
```

## Out of Scope

- **End-user subagents** — subagents the plugin generates into users' projects during setup (e.g., a project-scoped "code-reviewer" subagent). That is Initiative #2 (Ship End-User Subagents) and is independent of this work.
- **Onboarding orchestrator refactor** — rewriting `onboarding/SKILL.md` Step 2 to dispatch `repo-scanner`. That is Initiative #7 (Onboarding Orchestrator Refactor) and depends on this initiative having landed.
- **Upgrade planner wiring** — refactoring `upgrade/SKILL.md` Pass 2 to use `upgrade-planner`. Not filed; separate follow-up.
- **Write-capable subagents** — any subagent that modifies user files. Requires its own spec with an explicit tool-set carve-out.
- **Parallel subagent dispatch** — fanning out multiple subagents concurrently for a single task. Not needed by v1 consumers; if needed later, the `superpowers:dispatching-parallel-agents` skill already covers the pattern.

## Risks & Edge Cases

- **Malformed subagent output.** A subagent may reply with prose instead of the contracted fenced block, or with a block missing fields. Mitigation: each subagent body specifies the output contract explicitly and includes a "failure mode" clause (return `unknown` for missing signals, never partial silent results). Consumer skills (when they land) must validate the parse and fall back to the main-context inline scan if the subagent reply is unparseable.
- **Nested subagent dispatch.** A subagent invoking another subagent would blow up context budgets and is hard to debug. Mitigation: each subagent body includes an explicit "do not dispatch other subagents" constraint. Reviewers check this in code review.
- **Plugin manifest compatibility.** Convention-based discovery (no `agents[]` in `plugin.json`) is the safer default today. Risk: a future Claude Code release MIGHT require explicit registration. Mitigation: the spec notes the follow-up path — adding the field is a one-line manifest change if it becomes mandatory.
- **Tool-set too narrow.** `repo-scanner` may need a bash invocation this spec did not anticipate. The `tools:` frontmatter whitelists `Bash` broadly, relying on the subagent body prompt to forbid destructive operations. If a specific bash command is needed and the prompt blocks it, the prompt is updated, not the frontmatter.
- **Name collisions with user-created subagents.** A user may have their own `~/.claude/agents/repo-scanner.md`. Claude Code's subagent resolution order (project `.claude/agents/` before plugin, before user — verify at implementation time) determines precedence. Mitigation: subagent names in this catalog are generic enough that collisions are plausible; if that becomes a real problem, a future initiative prefixes plugin subagent names (e.g., `onboarding-repo-scanner`). Not worth the churn today.
- **Skill authors forget the contract.** A future skill author may invoke a subagent with free-form prompts that ignore the output contract. Mitigation: the "Subagent Authoring Rules" section in `CLAUDE.md` (added by this initiative) documents the required invocation shape. Reviewers check consumer skills against it.
- **Empty consumer base at merge time.** The initiative ships primitives with zero callers. This looks like dead code. Mitigation: the initiative explicitly scopes itself as scaffolding for #7; the CLAUDE.md authoring rules serve as the documentation hook until #7 lands.

## Success Criteria

All grep-testable unless otherwise noted.

- **Subagent files exist with correct frontmatter:**
  - `test -f .claude/agents/repo-scanner.md` succeeds.
  - `test -f .claude/agents/upgrade-planner.md` succeeds.
  - `grep -c "^name: repo-scanner$" .claude/agents/repo-scanner.md` → `1`.
  - `grep -c "^name: upgrade-planner$" .claude/agents/upgrade-planner.md` → `1`.
  - Each file's frontmatter contains `tools:`, `model: opus`, and a one-sentence `description:`.
- **Tool-set is read-only:**
  - `grep -E "^tools:.*\b(Write|Edit|NotebookEdit)\b" .claude/agents/*.md` returns zero matches. Any occurrence of a write-capable tool in frontmatter fails this criterion.
- **Body contains the required sections:**
  - Each file has a heading for Role, Inputs, Output Contract, Constraints, and Failure Mode. A `grep -c "^## " .claude/agents/<name>.md` returns at least 5.
- **Output contract is concrete:**
  - Each body includes at least one fenced code block showing the exact output format (not placeholders like `<output>`).
- **Authoring docs exist:**
  - `grep -c "Subagent Authoring Rules" CLAUDE.md` → `1`.
  - `CLAUDE.md` contains the invocation-pattern example and the tool-set policy verbatim (copy-pasteable for skill authors).
- **Manifest is unchanged:**
  - `git diff --stat .claude-plugin/plugin.json` on the feature branch shows the file is untouched by this initiative's commits.
- **No consumer wiring:**
  - `grep -l "subagent_type: repo-scanner" skills/*/SKILL.md` returns zero files. Same for `upgrade-planner`. Any wiring done here fails this criterion — wiring belongs to Initiative #7 and the upgrade follow-up.
- **Manual sanity check (non-grep):**
  - In a Claude Code session inside this repo, invoke the Agent tool with `subagent_type: repo-scanner` and a trivial prompt ("return your standard report for the current directory"). The subagent returns a fenced `repo-scan` block with all contracted fields. Same check for `upgrade-planner` against a fixture project with known delimited sections. Document the result in the PR description.
