# Consume Handoff Context

> Consumed by every setup skill's Step 1 when it launches. Do not invoke directly.

The onboarding orchestrator (`skills/onboarding/SKILL.md` Step 5) serialises a context payload as a single fenced ```json block. Every setup skill consumes that block through this helper, which validates the payload against the schema and falls back to inline detection when the block is missing or malformed. The goal: one parse path, one fallback path, one set of locals — regardless of whether the skill was dispatched by the orchestrator or invoked directly.

## Schema

- Schema file: `docs/schemas/handoff-context.schema.json` (Draft 2020-12).
- Required fields: `detected_language`, `existing_claude_md`, `inferred_use_case`, `repo_signals`, `graphify_candidate`.
- Optional fields propagate through unchanged (e.g. `source`, nested keys inside `repo_signals`).

## Input contract (set by the calling skill before reading this file)

- `handoff_block` — the raw string the orchestrator passed inline (may be absent when the skill runs standalone).
- `schema_path` — `docs/schemas/handoff-context.schema.json`.

No other input is required. The helper never asks the user anything; detection runs silently.

## Procedure

Execute these steps in order. The helper ALWAYS returns a populated set of locals — there is no failure exit.

### H1 — Locate the fenced JSON block

If `handoff_block` is absent, empty, or obviously unrelated prose, skip to H4 (fallback).

Otherwise, scan `handoff_block` for the first line matching ```` ```json ```` (optionally with trailing whitespace), then the following lines up to (but not including) the next ```` ``` ```` line on its own.

- If no fenced block is found, skip to H4.
- If more than one is found, use the first and note `"multiple json fences — first one used"` in `notes`.

### H2 — Parse as JSON

Parse the extracted fence body. On parse failure, skip to H4.

### H3 — Validate against the schema

Read `docs/schemas/handoff-context.schema.json`. Apply these inline checks (Claude reads the schema body and evaluates):

1. Top-level value is an object.
2. Every field in the schema's `required` array is present.
3. Every field with a declared `type` matches (string / boolean / object / array / null — use the union where the schema declares one).
4. Every field with an `enum` has a value inside the enum.
5. `detected_language` matches the declared pattern (ISO 639-1 style).

If any check fails, skip to H4. Do not attempt partial recovery — a malformed handoff must not silently produce half-populated locals.

On success, populate the locals listed in the Output contract below from the parsed object, set `source: "orchestrator"`, and stop.

### H4 — Fallback (inline detection)

This branch runs whenever H1–H3 did not produce a valid object. It MUST always succeed with reasonable defaults.

1. **Language:** detect from the user's first message in the current session. If the skill has no user turn yet (e.g. invoked programmatically), default to `en`. Store as `detected_language`.

2. **Existing CLAUDE.md:** check whether `./CLAUDE.md` exists on disk. Store as `existing_claude_md` (boolean).

3. **Repo scan:**
   - Preferred path: dispatch the `repo-scanner` subagent (defined in `.claude/agents/repo-scanner.md`) with the standard brief used in `skills/onboarding/SKILL.md` Step 2. Parse the reply via `skills/_shared/parse-subagent-json.md` with `reply_kind: "repo-scan"`. On `result.ok: true`, copy `result.data.inferred_use_case` to `inferred_use_case`, `result.data.graphify_candidate` to `graphify_candidate`, and the full `result.data` object (minus the fields already mapped) to `repo_signals`.
   - Fallback path (used when the subagent is unavailable, errors out, or returns `ok: false`): run the inline heuristic documented in `skills/onboarding/SKILL.md` Step 2 Fallback. That heuristic is the single source of truth — do not duplicate it here. Populate `inferred_use_case`, `graphify_candidate`, and `repo_signals` from its output, using `inferred_use_case: "unknown"` when no signal dominates.

4. Set `source: "fallback"` so downstream steps can log the provenance if they need to.

Skip every inline probe gracefully on error (e.g. missing `CLAUDE.md` is not a failure; a Bash probe failure sets the corresponding signal to the conservative default of `false` / empty).

## Output contract

After this helper returns, the calling skill reads the following locals directly. Every local is guaranteed to be populated:

- `detected_language` — string, always set (default `en`).
- `existing_claude_md` — boolean, always set.
- `inferred_use_case` — string (enum above) or `"unknown"`; never null in the locals the skill reads (the schema allows null on the wire; the helper normalises to `"unknown"`).
- `repo_signals` — object, possibly with `signals` / `existing_agents_md` / `repo_size_bucket` keys. Always an object, possibly empty.
- `graphify_candidate` — boolean, always set (default `false`).
- `source` — `"orchestrator"` | `"fallback"`. Advisory; consumers MAY ignore it.

## Failure mode

There is no failure exit. The helper is designed so that:

- A missing handoff block is not an error — the fallback runs.
- A malformed handoff block is not an error — the fallback runs.
- A subagent dispatch failure is not an error — the inline heuristic runs.
- An empty repo with no detectable signals is not an error — `inferred_use_case: "unknown"`, `repo_signals: { "signals": [] }`, `graphify_candidate: false`.

A setup skill invoked directly (without the orchestrator) therefore produces the same artifacts as the same skill invoked via the orchestrator, given the same project state.

## Consumer obligations

- Callers MUST read all five required locals. They MAY read `source` for logging.
- Callers MUST NOT add their own handoff parsing on top — any new required field goes into the schema and this helper, nowhere else.
- Callers MAY keep skill-specific probes AFTER this helper runs (e.g. a LaTeX-toolchain probe in academic-writing-setup). This helper only covers the five contracted fields.

## Design decision record

- **Single helper, guaranteed populate.** Two sources of truth (orchestrator payload + per-skill fallback) caused drift every time the contract grew. Consolidating here means adding a new field costs one schema edit and one helper edit.
- **Fallback delegates to the orchestrator's inline heuristic.** The repo-scan heuristic is non-trivial; duplicating it across ten setup skills is how it drifted in the first place. The orchestrator's Step 2 Fallback remains the single authoritative copy.
- **Normalise `null` to `"unknown"` for `inferred_use_case` in the locals.** The schema allows `null` on the wire (future-proofing); every downstream consumer already treats `"unknown"` as the no-inference sentinel, and a single normalisation point avoids littering branches with `null`-checks.
