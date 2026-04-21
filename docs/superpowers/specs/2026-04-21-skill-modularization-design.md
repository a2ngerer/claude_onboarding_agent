# Skill Modularization — Design

**Date:** 2026-04-21
**Status:** Draft
**Scope:** Split the three oversized SKILL.md files (`web-development-setup`, `academic-writing-setup`, `data-science-setup`) into a thin orchestration prompt plus domain-scoped sibling files. Lock an extraction threshold and a sibling-file naming convention into the plugin's authoring rules.

## Motivation

SKILL.md files are markdown prompts Claude follows at runtime. They are read top-to-bottom when the skill is invoked. Three files have grown past the point where that model works well:

| Skill | Current lines |
|---|---|
| `web-development-setup` | 543 |
| `academic-writing-setup` | 463 |
| `data-science-setup` | 341 |

For comparison, the natural cluster of healthy skills sits between 112 and 220 lines (`office-setup`, `content-creator-setup`, `coding-setup`, `design-setup`, `devops-setup`, `tipps`). The baseline `coding-setup` at 186 lines is the reference shape: orchestration steps, questions, small inline templates, completion summary.

Three problems follow from oversize:

1. **Scannability.** A skill author or reviewer reading `web-development-setup/SKILL.md` in the GitHub UI cannot see the flow without scrolling through embedded artifact templates, framework matrices, and gitignore blocks.
2. **Token cost at runtime.** Claude loads the full SKILL.md into context on invocation. A 543-line file burns context that is irrelevant at 80% of the steps (e.g. the Overleaf instructions at the bottom are only relevant when Q3 = B).
3. **Growth pressure from other initiatives.** Initiatives #2 (end-user subagents) and #3 (end-user hooks) will add content to these same skills. Absorbing that growth without first extracting the existing bulk pushes all three files further past a reasonable working size.

A secondary goal: establish the convention early so every new skill and every later addition to existing skills has a clear rule for where content belongs.

## Decision

### Extraction Threshold

**A SKILL.md file requires modularization when it exceeds 300 lines.**

- Files at 200–300 lines are audited on edit but not forced. The convention is a trigger for review, not a hard ceiling.
- Files under 200 lines stay inline by default.

Rationale for 300 over 200 or 250:

- 200 would pull `devops-setup` (215), `tipps` (220), and the natural cluster into scope — a far larger refactor than the observed pain demands.
- 250 would force `knowledge-base-builder` (303), `checkup` (310), and `upgrade` (315) into scope. Two of those are explicitly out-of-scope for this initiative (see below) and the third is borderline; a threshold just below them would generate churn without solving a visible problem.
- 300 cleanly captures the three outliers (`data-science-setup` at 341, `academic-writing-setup` at 463, `web-development-setup` at 543) and leaves the rest of the plugin untouched.

### Sibling-File Naming Convention

Supporting files live **next to SKILL.md in the same skill directory**, not in a subdirectory. The filename describes the content domain, not the skill phase.

Canonical filenames, used across skills wherever applicable:

| Filename | Purpose |
|---|---|
| `rule-file-templates.md` | Ready-to-write bodies of `.claude/rules/<topic>.md` files the skill generates (e.g. `api-conventions.md`, `writing-style.md`, `data-schema.md`). |
| `gitignore-block.md` | The exact delimited `.gitignore` block the skill appends to the user's project, plus any `.env.example` or similar companion snippets. |
| `framework-defaults.md` | Framework- or stack-conditional matrices (e.g. web-dev's implied styling table, public-env-var prefix table, deploy-target hints). |
| `document-skeletons.md` | Artifact skeletons the skill writes into the user's project (e.g. `main.tex`, `main.typ`, `pyproject.toml`, `.pre-commit-config.yaml`). |
| `stack-scaffolds.md` | Stack-dependent scaffolds that mix multiple small artifacts (e.g. data-science's `pyproject.toml` + `.claude/settings.json` permissions adapted per Q1/Q3). |

Skill-specific names are allowed when none of the above fits cleanly, but a new name must describe a content domain (not a phase like "questions.md" or "step-4.md"). Subdirectories are not introduced — YAGNI, and flat layout matches the rest of the plugin.

**Same filename, different skill:** Two skills may both own a `rule-file-templates.md`. Each lives in its own skill directory and is scoped to that skill. This is analogous to how multiple skills own a `SKILL.md`.

### Extraction Boundary

**Stays in SKILL.md (orchestration prompt):**

- YAML front matter
- Opening description and placement advice ("use this skill when X, use Y for Z")
- Language detection, handoff-context consumption
- Existing-CLAUDE.md delimiter policy
- Step ordering, step headings, one-line description of what each step produces
- Context-question text (Q1 through Q7)
- Decision branches that gate execution (e.g. "if Q3 = Python backend, probe `uv --version`")
- Short environment probes and their warning text
- Installation-protocol invocations and Graphify-install invocations (these reference `skills/_shared/*` today and continue to)
- Write-meta invocation
- Completion-summary template
- Anywhere Claude needs to make a decision or print a fixed message

**Moves to sibling files (reference content):**

- Rule-file content bodies (the full markdown the skill writes into `.claude/rules/<topic>.md`)
- Gitignore blocks and `.env.example` scaffolds
- Framework/stack lookup matrices longer than ~10 rows
- Artifact skeletons (`main.tex`, `main.typ`, `pyproject.toml`, `package.json`, `.pre-commit-config.yaml`)
- Per-framework install-command lists
- Per-stack `.claude/settings.json` permission adaptations when they exceed ~15 lines
- Overleaf / provider-specific instruction blocks only relevant under one Q3 answer

**Hard rule:** if a block is shorter than ~15 lines and relevant on every path through the skill, leave it inline. Extraction is for bulk, not for every template.

### Reference Pattern

SKILL.md references siblings inline, at the step where they are used. The pattern matches the existing `skills/_shared/installation-protocol.md` idiom.

**At the top of SKILL.md**, immediately after the existing-CLAUDE.md section, add a short "Supporting Files" block so Claude sees what is available:

```markdown
## Supporting Files

Read these on-demand at the step that invokes them. Do not read eagerly.

- `rule-file-templates.md` — bodies of the .claude/rules/*.md files this skill generates
- `gitignore-block.md` — the .gitignore block and .env.example scaffold
- `framework-defaults.md` — framework-conditional matrices
```

(Only list the siblings the skill actually owns.)

**At the step that needs a sibling**, SKILL.md gives an imperative instruction:

```markdown
### .claude/rules/api-conventions.md

Read `rule-file-templates.md` and write the `api-conventions` section to `.claude/rules/api-conventions.md`. Substitute placeholders based on Q1–Q7.
```

The sibling file itself uses H2 headings to separate multiple artifacts, so one sibling can hold several templates without ambiguity.

**No global index.** The "Supporting Files" block lists filenames; each step explains what to do with them. Claude does not navigate a table of contents.

## Affected Skills

Only the three files that exceed the 300-line threshold. Concrete extraction plan and target line count follows.

### `skills/web-development-setup/SKILL.md` (543 → target ≤ 260)

**New siblings:**

- `skills/web-development-setup/rule-file-templates.md` — contains the three rule-file bodies currently embedded as `### claude_instructions/api-conventions.md`, `### claude_instructions/component-structure.md`, `### claude_instructions/env-vars.md`. Each becomes an H2 section inside the sibling.
- `skills/web-development-setup/framework-defaults.md` — contains the Step 4 "Derive Implied Defaults" matrix (styling + deploy-target table) and the env-var public-prefix table from the current `env-vars.md` block.
- `skills/web-development-setup/gitignore-block.md` — contains the `.gitignore` block and the `.env.example` scaffold.
- `skills/web-development-setup/document-skeletons.md` — contains the `package.json`, `pyproject.toml`, and the per-framework install-command list (Q6/Q7 install commands included).

**SKILL.md after extraction holds:**

- Front matter + intro + language + existing-CLAUDE.md block
- Supporting-Files listing (new)
- Step 1 Install Dependencies
- Step 2 Detect Package Manager
- Step 3 Context Questions (Q1–Q7)
- Step 4 (one-paragraph pointer to `framework-defaults.md` — the matrix moves out)
- Step 5 Verify Package Manager Tooling (warnings stay inline)
- Step 6 Generate Artifacts — each subsection becomes a one-paragraph "read sibling X, write artifact Y" instruction, except `.claude/settings.json` which stays inline (under 40 lines and fully conditional)
- Step 7 Optional Graphify Integration (unchanged, already short)
- Step 8 Write Upgrade Metadata
- Step 9 Completion Summary

### `skills/academic-writing-setup/SKILL.md` (463 → target ≤ 240)

**New siblings:**

- `skills/academic-writing-setup/rule-file-templates.md` — contains the `writing-style.md` and `citation-rules.md` bodies currently embedded in Step 4.
- `skills/academic-writing-setup/document-skeletons.md` — contains the `main.tex` skeleton with biblatex-style mapping table, the `main.typ` skeleton with CSL-style mapping table, and the `bib/references.bib` example.
- `skills/academic-writing-setup/gitignore-block.md` — contains the LaTeX/Typst `.gitignore` block.
- `skills/academic-writing-setup/optional-integrations.md` — contains the `.pre-commit-config.yaml` scaffold (chktex + vale), the Overleaf Git bridge instructions (only relevant when Q3 = B), and the knowledge-base bridge mention.

**SKILL.md after extraction holds:**

- Front matter + intro + language + existing-CLAUDE.md block
- Supporting-Files listing
- Step 1 Install Dependencies
- Step 2 Verify Writing Toolchain (probes and warning text stay inline)
- Step 3 Context Questions (Q1–Q7)
- Step 4 Generate Artifacts — each subsection shrinks to a sibling-reference paragraph; the "Directory scaffold" list stays inline (short, universal)
- Step 5 Write Upgrade Metadata
- Step 6 Completion Summary

### `skills/data-science-setup/SKILL.md` (341 → target ≤ 220)

**New siblings:**

- `skills/data-science-setup/rule-file-templates.md` — contains the `data-schema.md` and `evaluation-protocol.md` bodies.
- `skills/data-science-setup/stack-scaffolds.md` — contains the `pyproject.toml` scaffold with the full `uv add` command matrix per Q2/Q3/Q4/Q6 and the `.claude/settings.json` permissions body with per-Q1/Q2/Q4 adaptations.
- `skills/data-science-setup/gitignore-block.md` — contains the data-science `.gitignore` block.
- `skills/data-science-setup/notebook-hygiene.md` — contains the `.pre-commit-config.yaml` scaffold for Q6 = yes and the adjoining install instructions.

**SKILL.md after extraction holds:**

- Front matter + intro + language + existing-CLAUDE.md block
- Supporting-Files listing
- Step 1 Install Dependencies
- Step 2 Verify Python Tooling (probe + warning stays inline)
- Step 3 Context Questions (Q1–Q6)
- Step 4 Generate Artifacts — subsections shrink to sibling-reference paragraphs; the directory-scaffold list stays inline
- Step 5 Optional Graphify Integration
- Step 6 Write Upgrade Metadata
- Step 7 Completion Summary

## Authoring Documentation

To lock the convention, the repository's `CLAUDE.md` "Skill Authoring Rules" section gains a new subsection:

- The 300-line threshold rule (and the 200–300 soft-audit band)
- The canonical sibling-file names table
- The extraction-boundary rule (what stays, what moves)
- The reference pattern (Supporting Files block + step-local imperatives)

No new documentation file is created. CLAUDE.md is already the canonical entry point for plugin-development conventions, and the rules-convention spec has set the pattern of editing it for authoring rules.

## Out of Scope

- **Renaming skills** or changing their slash commands. The modularization is structural only.
- **Splitting a skill into multiple skills.** `web-development-setup` stays one skill with one slash command; it merely gains siblings.
- **Skills under 300 lines.** `checkup` (310) and `upgrade` (315) are near the threshold but are intentionally excluded to keep the PR focused. A follow-up may revisit them after initiatives #2 and #3 have settled the content these skills need to hold. `knowledge-base-builder` (303) is similarly deferred.
- **Modifying `skills/_shared/*`.** The existing shared helpers already follow the sibling pattern at repo scope; this initiative only adds per-skill siblings.
- **Semantic changes to generated content.** Every rule-file body, gitignore block, and skeleton must land in the user's project byte-for-byte identical to what the current SKILL.md produces.
- **Updates to the `onboarding` routing skill.** It references child skills by name, not by file size; no change needed.

## Cross-Initiative Note

**This initiative should land before initiatives #2 (end-user subagents) and #3 (end-user hooks) touch the same three skills.** Both #2 and #3 will add content (subagent definitions, hook registrations, or examples) to setup skills. Adding that content to the already-oversized SKILL.md files would compound the problem this initiative solves. Running #4 first means #2 and #3 can place their additions directly into siblings or into a slimmed SKILL.md with clear extraction rules available.

Order suggestion: #4 (this one) → #2 → #3, with #1 (skill renaming) orthogonal.

## Risks & Edge Cases

- **Siblings are not auto-loaded.** Claude Code does not eagerly read siblings of SKILL.md. The Supporting-Files block plus the step-local imperatives ("Read `rule-file-templates.md` and write …") are the only signals Claude has. If the SKILL.md instruction is ambiguous, Claude may skip the read. Mitigation: each step that needs a sibling must say `Read <filename>` explicitly. Verified at review time by grepping for `Read \`.*\.md\`` in each refactored SKILL.md.
- **User-facing output must not regress.** Every artifact the skill writes to the user's project (CLAUDE.md section, `.claude/rules/*.md`, `.gitignore`, skeletons) must be byte-equivalent before and after. Enforced by a pre/post grep comparison for distinctive tokens (e.g. `NEXT_PUBLIC_`, `\\cite{key}`, `uv add pandas polars`) in the plan's verification task.
- **Heading-level collision.** Sibling files use H1 for their own title and H2 for each artifact section. SKILL.md uses H1 for the skill name and H2 for steps. Claude reading a sibling mid-step must not confuse heading levels with SKILL.md's flow. Mitigation: siblings open with a one-line `> Consumed by <skill>/SKILL.md at Step N. Do not invoke directly.` note so the context is explicit.
- **Duplicate filename across skills.** `rule-file-templates.md` appears in each of the three skill directories. This is intentional and mirrors the `SKILL.md` per-skill pattern. Grep searches in the plan must be scoped to the specific skill directory to avoid cross-skill matches.
- **Siblings drift out of sync.** Because siblings hold content, not logic, the risk is low — but it is possible to update SKILL.md without updating the sibling it references. Mitigation: the review checklist in `CLAUDE.md`'s new authoring subsection includes "when editing a sibling, grep SKILL.md for its filename to confirm the reference still matches; when editing SKILL.md, scan the Supporting-Files block."
- **Threshold gaming.** A future author could pad SKILL.md to 299 lines and avoid extraction. Mitigation: the threshold is a trigger for review, not a hard ceiling. The convention is enforced by PR review, not by a CI rule.

## Success Criteria

- **Line count:** `wc -l skills/web-development-setup/SKILL.md skills/academic-writing-setup/SKILL.md skills/data-science-setup/SKILL.md` returns values ≤ 260, ≤ 240, and ≤ 220 respectively. Each is ≤ 300 unconditionally.
- **Sibling presence:** Each of the three skill directories contains at least two new `.md` files beyond `SKILL.md`, and each refactored SKILL.md references each sibling at least once via `Read \`<filename>\`` or equivalent.
- **Generated-output parity:** For each of the following tokens, the post-refactor grep of the refactored SKILL.md plus its siblings returns the same or greater count than the pre-refactor SKILL.md grep: `NEXT_PUBLIC_` (web-dev), `\\cite{`, `biblatex-style` (academic), `uv add pandas` (data-science), `# onboarding-agent: <slug> — start` (all three). The block still ends up in the user's project; only its source location changed.
- **Supporting-Files block:** Each refactored SKILL.md contains a `## Supporting Files` section within the first 60 lines, listing every sibling the skill owns.
- **Authoring doc:** `CLAUDE.md` contains a "SKILL.md Modularization" subsection under "Skill Authoring Rules" with the 300-line threshold, the canonical sibling-filename table, the extraction boundary, and the reference pattern — all copy-pasteable verbatim.
- **Manifest untouched:** `.claude-plugin/plugin.json` is not modified. Siblings are referenced by SKILL.md at runtime; the manifest lists only SKILL.md entries. (Verify by `git diff` on the manifest file after all commits.)
