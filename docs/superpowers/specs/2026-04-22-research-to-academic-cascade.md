# Research-to-Academic-Writing Cascade — Design

**Date:** 2026-04-22
**Status:** Accepted
**Related issues:** #29 (this spec), #24 (handoff-context schema), #26 (decision-tree depth ≤ 3), #38 (Superpowers offer moved into Step 1)

## Context

The plugin ships two adjacent skills that target academic users:

- `research-setup` — input side: reading papers, taking notes, literature review, citation format for inline references.
- `academic-writing-setup` — output side: LaTeX / Typst manuscript for a thesis, journal paper, or dissertation, with Zotero + Better BibTeX and strict no-invented-citations rules.

Onboarding Step 3 presents both as sibling numbered options. Step 4 ("Not Sure" decision tree) routes to one skill per invocation. A PhD student who both reads and writes in the same repo gets confused: which skill do they pick first? Picking `academic-writing-setup` leaves the reading side unconfigured; picking `research-setup` leaves the manuscript side unconfigured. Re-running the orchestrator is possible but unintuitive.

## Decision

**Option B — cleanly cascading skills.** Keep both skills as distinct, standalone-runnable units. After `research-setup` finishes its normal flow, it probes for a manuscript signal in the repo. On match, it offers a one-way cascade into `academic-writing-setup`, passing a handoff-context payload so the child skill skips its language-detection preamble and its Superpowers offer.

## Option A — Considered and rejected

A merged `academic-setup` skill that asks both reading and writing questions in one flow.

- Rejected because the two skills already diverge: research-setup has no toolchain probe, academic-writing-setup has six context questions plus a Better-BibTeX integration, a project-local subagent, and a SessionStart hook. Merging them creates a 10+-question monster and duplicates logic for users who only want one side.
- Rejected because research-only users (humanities students building a literature library without a thesis in the same repo) would be forced through writing-side questions that do not apply.
- Rejected because the onboarding orchestrator dispatches cleanly to one skill per invocation — a merged skill breaks the "one use case, one skill" invariant established in #26.

## Option B — Chosen

### Rationale

- Each skill stays standalone-runnable (`/research-setup` and `/academic-writing-setup` still work in isolation).
- The cascade is one-way (research → writing), matching the practical workflow: users read before they write.
- Signal detection is cheap, read-only, and unambiguous (`main.tex` / `main.typ` / `sections/*.tex` / `bib/*.bib`).
- The Superpowers offer is not duplicated thanks to the `superpowers_offered` marker.
- The language-detection preamble is not duplicated thanks to the `source_skill` marker.
- No skill is renamed, no slash command breaks, `.claude-plugin/plugin.json` and README.md structure are untouched.

### Mechanics

1. **Schema extension** (`docs/schemas/handoff-context.schema.json`). Two new optional properties:
   - `source_skill` (string, enum: `["research-setup"]`) — marker set only on cascade dispatch. Absent on direct / orchestrator dispatch.
   - `superpowers_offered` (boolean) — set only on cascade dispatch. `true` when the parent already ran the Superpowers opt-in.
   Both fields propagate through `skills/_shared/consume-handoff.md` unchanged; the helper's output contract documents them as optional advisory locals.

2. **Detection (research-setup Step 8).** Read-only probe:
   - `./main.tex` OR `./main.typ` at repo root, OR
   - `./paper.tex`, `./thesis.tex`, `./manuscript.tex`, `./dissertation.tex` at repo root, OR
   - Any `*.tex` file under `./sections/`, `./chapters/`, `./manuscript/`, OR
   - A `./bib/` directory OR any root-level `*.bib` file.
   On no match: skip to completion summary; record `cascade_offered: false`.

3. **Offer** (on match). Ask once, adapted to `detected_language`: *"A manuscript scaffold was detected (`<paths>`). Also run `academic-writing-setup` right after? That configures the writing side (style, citation rules, LaTeX scaffold). (yes / no)"* Record `cascade_accepted`.

4. **Invocation** (on accept). Construct the handoff payload by copying every field from research-setup's current handoff context and adding:
   ```json
   {
     "source": "orchestrator",
     "source_skill": "research-setup",
     "superpowers_offered": <true if Step 1 already asked the user, else false>
   }
   ```
   Invoke `academic-writing-setup` with this payload as the handoff block.

5. **Child-skill adaptations (academic-writing-setup preamble).**
   - On `source_skill: "research-setup"`: use the parent's `detected_language`; do not re-run language detection.
   - On `superpowers_offered: true`: skip Step 1 entirely (do not re-ask; inherit whatever the parent resolved). `superpowers_installed` carries over as-is.
   - All other steps (toolchain probe, Q1–Q6, artifact generation, subagent emission, hook offer) still run — the user explicitly opted into the writing-side setup.

6. **Completion.** research-setup's Step 9 summary prints a single `Cascade:` line only when an offer was made. Accepted → `✓ Cascaded into academic-writing-setup — see its summary above for writing-side artifacts.`. Declined → one-line deferred reminder. No match → no line.

7. **Onboarding Step 3 tip.** One italic line beneath the Writing & Research options: *"Tip: if you both read papers and write a manuscript in this repo, pick option 6 (research) first — it detects a manuscript folder and offers to cascade into option 5 (academic-writing) automatically."*

8. **Onboarding Step 4.** The existing B-branch Q3 gains a short parenthetical: *"(if a manuscript folder is present, [research-setup] will offer to cascade into academic-writing-setup automatically)."* The tree stays depth-≤-3; the #26 invariant holds. No new question is added.

## Acceptance criteria

- `/research-setup` in a repo with `./main.tex` prompts for the cascade.
- `/research-setup` in a repo with no manuscript signal prompts nothing and prints no `Cascade:` line.
- Declining the cascade prints one deferred reminder in the completion summary.
- Accepting the cascade invokes `academic-writing-setup`, which skips its language-detection preamble and Step 1 (Superpowers offer).
- `/academic-writing-setup` invoked standalone (no `source_skill`) retains all existing behaviour.
- No rename of either skill. `.claude-plugin/plugin.json` and README.md structure are untouched.

## Risks

- **Double-execution of anchor rendering.** Both skills run anchor rendering. Duplicate anchor sections in CLAUDE.md are a risk if the delimited-section logic fails. Mitigation: the existing `<!-- onboarding-agent:start -->` / `end` markers replace-in-place when present, so a second render updates rather than duplicates.
- **Stale `graphify_candidate`.** The parent may pass a stale flag if the user grew the corpus between the two legs. Acceptable — the flag is a hint, not a gate.
- **Superpowers mid-state.** If the parent offered Superpowers and the user declined, the child must honour that. Guaranteed by the Step 1 skip condition.
- **Cascade error mid-way.** If `academic-writing-setup` errors after the handoff, research-setup continues to its own summary; the error surfaces in the child's output. No silent failure; no retry loop.
