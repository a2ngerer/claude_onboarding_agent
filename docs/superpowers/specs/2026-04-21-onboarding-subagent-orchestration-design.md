# Onboarding Subagent Orchestration — Design

**Date:** 2026-04-21
**Status:** Draft
**Scope:** Refactor the `onboarding` orchestrator (and optionally `checkup`, `upgrade`) to delegate bounded, output-heavy phases to plugin-internal subagents via the Agent tool. Main context retains only cross-phase decision state and routing logic.

## Motivation

The current `onboarding` SKILL.md executes every phase inline: the repo scan reads dozens of filesystem paths into the main context, the dispatched setup skill writes artifacts while the orchestrator is still holding scan output and question answers, and any post-write sanity check would add yet another evidence dump. On a medium-sized repository the scan phase alone can consume 3k–6k tokens of raw evidence that the orchestrator never needs beyond a single routing decision. Verification after artifact writes is absent today — failures are reported by the setup skills themselves, if at all.

Claude Code's native pattern for this problem is the Agent tool: dispatch a short-lived subagent with a narrow task, receive a compact structured report, and discard the intermediate evidence. The plugin already assumes this in Initiative #1 (Plugin-Internal Subagents) by defining a catalog of reusable subagents. Initiative #7 makes the orchestrator the first consumer of that catalog. The main context stays lean, verification becomes routine (one Agent dispatch per artifact write), and the same pattern flows through to `checkup` and `upgrade` in a second wave.

## Prerequisite

**This design depends on Initiative #1 shipping first.** Initiative #1 defines the plugin-internal subagent catalog — the named agent types the orchestrator dispatches into. This spec references that catalog by name (`repo-scanner`, `artifact-verifier`, `audit-collector`) and treats it as a stable contract. If Initiative #1 has not shipped at the time this plan begins, the first task of the implementation plan is a hard gate: verify the catalog exists, and fail fast if not. No part of this initiative is actionable without it.

The catalog contract assumed by this spec (described here in case Initiative #1 is authored in parallel):

| Subagent name | Input | Output schema |
|---|---|---|
| `repo-scanner` | project root path, optional `signals_of_interest` list | structured signal report (see Report Format §) |
| `artifact-verifier` | list of file paths the setup skill just wrote | pass/fail + list of issues |
| `audit-collector` | invocation of an audit skill (e.g. `tipps`) | severity-bucketed finding summary |

If Initiative #1 renames any of these, this spec must be updated in lockstep — no silent remapping.

## Decision

### Delegation points (onboarding)

Three phases of `onboarding/SKILL.md` move to subagents. Everything else stays in the main context.

| Phase | Today | New owner | Rationale |
|---|---|---|---|
| Step 2: Scan the Repository | Inline Glob + Grep + Bash `find` calls; raw output in main context | `repo-scanner` subagent | Output is evidence-heavy; the orchestrator needs only the inferred use case and a short signal list. |
| Post-dispatch artifact verification (new) | Not currently done | `artifact-verifier` subagent | Confirms the setup skill wrote the files it claimed to; surfaces structural issues (missing delimiter, malformed JSON) before the user ever re-opens the project. |
| Post-setup audit (new, opt-in) | Not currently done | `audit-collector` subagent running `/tipps` | Optional — runs only if the user opts in at the completion summary. Returns a 1-screen finding summary without pulling the full `/tipps` output into the orchestrator context. |

What stays in the main context:

- Step 1 (language detection — one message, zero evidence)
- Step 1a / 1b (existing-setup detection and backup — needs filesystem state the orchestrator must own to decide whether to exit)
- Step 3 (present options — needs the scan summary, nothing else)
- Step 4 (not-sure questionnaire — stateful Q&A)
- Step 5 (dispatch — routing decision)
- Step 6 (rebuild backup notice — tiny)

### Report format (token budget per subagent)

Every subagent returns a fixed-schema structured block. The orchestrator parses it; freeform prose is discarded.

**`repo-scanner` report (cap: 500 tokens):**

```
inferred_use_case: <slug | "unknown">
confidence: <high | medium | low>
graphify_candidate: <true | false>
signals:
  - <short tag, e.g. "pyproject.toml">
  - <short tag, e.g. "next.config.ts">
existing_claude_md: <true | false>
existing_agents_md: <true | false>
notes: "<one sentence, optional>"
```

**`artifact-verifier` report (cap: 200 tokens):**

```
status: <ok | issues>
files_checked: <N>
issues:
  - file: <path>
    problem: <"missing delimiter" | "invalid JSON" | "empty file" | "path does not exist">
```

**`audit-collector` report (cap: 300 tokens):**

```
total: <N>
high: <N>
medium: <N>
low: <N>
top_titles:
  - "<title 1>"
  - "<title 2>"
  - "<title 3>"
```

The caps are enforced by prompt wording in the subagent definitions (Initiative #1). The orchestrator does not re-validate token count — it trusts the contract but refuses to proceed on schema failure (see Error handling).

### Dispatch pattern

The orchestrator SKILL.md contains explicit Agent-tool invocation blocks, for example:

```
Dispatch a subagent of type `repo-scanner` with the following brief:

  Inputs:
    project_root: "./"
    signals_of_interest: [coding, web-development, data-science, academic-writing, knowledge-base, office, research, content-creator, devops, design, graphify]

  Expected output: the structured report defined in the repo-scanner catalog entry.

  Token budget: 500 tokens for the final report.

Wait for the subagent to return. Parse the report. If parsing fails, see "Error handling".
```

Skill authors do not write Agent-tool pseudo-code beyond this level of detail — the Initiative #1 catalog entry for each subagent names the exact tool and prompt shape.

### Error handling

Three failure modes, with a two-tier recovery: retry once, then fall back inline with a visible warning.

| Failure | Detection | Recovery |
|---|---|---|
| Subagent times out | No return within the Agent tool's default timeout | Retry once with the same brief. On second timeout: fall back to an inline heuristic (the current in-skill scan code for `repo-scanner`; for `artifact-verifier`, a single-line "could not verify — please spot-check the generated files" notice; for `audit-collector`, skip entirely). Print a visible `⚠ Subagent <name> timed out — using fallback` line to the user. |
| Malformed report (schema failure) | Parser cannot extract required fields | Retry once with a reminder "return only the structured report; no prose". On second failure: same fallback path as timeout. |
| Subagent error (tool error, dispatch failure) | Agent tool returns an error object | Do not retry. Fall back immediately. Print the error reason to the user. |

The fallback heuristics MUST be present in every SKILL.md that dispatches — they are the escape hatch when the subagent layer is unavailable or broken. This is deliberate: onboarding must not become undeployable if a subagent definition regresses.

### Reuse in `upgrade` and `checkup`

The same pattern applies to the two other orchestrators, but the refactor is staged:

- **Wave 1 (this initiative):** `onboarding` only. Prove the pattern, stabilize the catalog contract.
- **Wave 2 (optional follow-on, tracked as mirror-tasks in the plan):** `checkup` delegates its Stage 1.2 delimiter scan to `repo-scanner` and its Stage 3 `/tipps` invocation to `audit-collector`. `upgrade` delegates its Pass 2.1 file enumeration to `repo-scanner` (with a different `signals_of_interest` — delimited-section candidates, not use-case signals).

Wave 2 tasks are included in the implementation plan but marked optional. The PR for Initiative #7 may ship Wave 1 only; Wave 2 is a separate merge.

## Affected Skills

Wave 1:

- `skills/onboarding/SKILL.md` — Step 2, new verification step after Step 5 dispatch, optional audit at Step 7.

Wave 2 (optional, same plan, separate commits):

- `skills/checkup/SKILL.md` — Stage 1.2 and Stage 3.
- `skills/upgrade/SKILL.md` — Pass 2.1.

Not affected by this initiative:

- The 11 setup skills (coding-setup, web-development-setup, …) — they do not orchestrate; they generate artifacts. If they ever grow orchestration complexity, a future initiative can apply the same pattern.
- `skills/tipps/SKILL.md` — it is the audit skill, not the orchestrator. `audit-collector` wraps it; `/tipps` itself does not need to change.
- `skills/_shared/*.md` — no shared scaffolding is affected.

## Phase Map

| Phase | Main-context work | Subagent work | Expected report size |
|---|---|---|---|
| Language detection | Parse first message, set `detected_language` | — | — |
| Existing-setup detection | Read `.claude/onboarding-meta.json`, grep CLAUDE.md | — | — |
| Rebuild backup | Bash `mkdir -p`, `cp` loop | — | — |
| Repo scan (Step 2) | Receive report, derive `inferred_use_case` and `graphify_candidate` | `repo-scanner` runs Glob/Grep/Bash, emits structured report | ≤ 500 tokens |
| Present options (Step 3) | Format option list using scan report | — | — |
| Not-sure Q&A (Step 4) | Ask 9 questions, record answers | — | — |
| Dispatch (Step 5) | Compose `HANDOFF_CONTEXT`, invoke setup skill | — | — |
| Post-dispatch verification (new) | Receive pass/fail, surface issues to user | `artifact-verifier` reads the files the setup skill wrote, checks delimiters / JSON / non-empty | ≤ 200 tokens |
| Rebuild notice (Step 6) | Print backup path | — | — |
| Optional audit (new Step 7) | Receive finding summary, offer `/upgrade` handoff if HIGH > 0 | `audit-collector` invokes `/tipps` internally | ≤ 300 tokens |

Main-context evidence post-refactor: language (≤ 50 tokens), existing-setup flags (≤ 100 tokens), scan report (≤ 500 tokens), user answers (≤ 200 tokens), verification report (≤ 200 tokens), optional audit report (≤ 300 tokens). Total: **≤ 1.4k tokens of evidence** across the full flow, versus today's 3k–6k. The main-context prompt (instructions) is itself unchanged in size — the reduction is in runtime-produced evidence.

## Out of Scope

- **Defining the subagents themselves.** The `repo-scanner`, `artifact-verifier`, and `audit-collector` agent definitions are owned by Initiative #1. This spec consumes them as a contract and does not specify their internal prompts.
- **Refactoring non-orchestrator skills.** The 11 setup skills keep their current inline patterns; they are not orchestrators and their main-context usage is already bounded by the dispatch structure.
- **New orchestrator capabilities.** This is a pure refactor — no new user-visible features beyond the new post-write verification and optional audit. The dispatch routing, the options menu, the `--rebuild` flag, the backup behavior: all unchanged.
- **Rewriting `/tipps` as a subagent.** `/tipps` remains a skill. `audit-collector` is a thin wrapper that invokes `/tipps` and summarizes the output; `/tipps` stays directly usable as a slash command.
- **Metrics / telemetry.** No new measurement infrastructure. Success criteria below are grep-based.

## Risks & Edge Cases

- **Subagent dispatch latency.** Agent-tool dispatches add round-trip overhead. For the repo scan this is acceptable (one dispatch, replaces inline work). For artifact verification after every setup skill, it adds one dispatch per invocation — ~2–5 seconds. Mitigation: the verification step is post-completion, so latency is not on the user's critical path for the conversation; the user has already seen the setup-complete message before verification runs.
- **Report parse errors.** If a subagent returns prose instead of the structured schema, the orchestrator retries once then falls back. The fallback path must be grep-verified to exist in every SKILL.md that dispatches (see Success Criteria).
- **Infinite recursion (subagent dispatches another subagent).** Explicitly forbidden. Subagent definitions (Initiative #1) state that plugin subagents MUST NOT themselves dispatch subagents. The orchestrator depth is 1 — orchestrator → subagent, never deeper. Violation surfaces as a stack-overflow-style Agent-tool error and the fallback triggers; documented here so the boundary is visible to future skill authors.
- **Contract drift between Initiatives #1 and #7.** If Initiative #1 renames a subagent or changes its report schema, the orchestrator breaks silently (the schema parser fails, the fallback fires, the user gets a warning but no failure). Mitigation: Task 1 of the implementation plan is a hard gate asserting the catalog exists with the expected names. Schema-level drift is caught at runtime by the existing retry-then-fallback logic.
- **Fallback divergence.** The inline fallback must stay in sync with what the subagent does. If the `repo-scanner` subagent adds new signals, the inline fallback will under-report. Mitigation: the fallback is documented as a degraded mode ("best-effort — for full detection, ensure the repo-scanner subagent is installed"), and the SKILL.md contains a single source of truth for the signal list. The fallback imports it by reference — no two copies.
- **User opt-out of the optional audit.** The Step 7 audit is opt-in. Users who skip it will not benefit from `audit-collector`; that is by design — post-onboarding audits are noise for users who already saw `/tipps` run in `checkup`. No mitigation needed; just called out to preempt reviewer questions.

## Success Criteria

- **Grep: Agent dispatch present in `onboarding/SKILL.md`.** `grep -c "repo-scanner\|artifact-verifier" skills/onboarding/SKILL.md` returns ≥ 3 (one for scan, one for verify, one for the fallback comment).
- **Grep: fallback branch present for every dispatch.** `grep -c "fallback" skills/onboarding/SKILL.md` returns ≥ 3 (one per delegation point).
- **Grep: no inline Glob/Grep/find in the phases that moved.** After refactor, Step 2 of `onboarding/SKILL.md` contains no `Glob`, `Grep`, or `find` call descriptions (they live in the subagent definition now). Grep: `sed -n '/^## Step 2/,/^## Step 3/p' skills/onboarding/SKILL.md | grep -E "Glob|Grep|find"` returns nothing.
- **Verification step exists.** `grep -c "artifact-verifier" skills/onboarding/SKILL.md` returns ≥ 1. A new section in the SKILL.md named "Step 5a: Verify artifacts" (or equivalent) is present.
- **Phase map matches the document.** The SKILL.md reflects every row of the Phase Map above. Manual check during code review.
- **Wave 2 mirror tasks are independently testable.** If Wave 2 is included in the same PR, the same grep assertions pass for `checkup` and `upgrade`. If Wave 2 ships separately, onboarding alone satisfies the criteria.
- **Initiative #1 dependency gate passed.** At plan-execution time, Task 1 (catalog assertion) either succeeds (Initiative #1 has shipped) or blocks the remaining tasks with a clear error.
