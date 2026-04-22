---
name: academic-writing-setup
description: Set up Claude for academic writing — thesis, paper, or dissertation. Configures LaTeX/Typst stack, bibliography (Zotero + Better BibTeX), citation style, and strict no-invented-citations rules so Claude helps you write without hallucinating references.
---

# Academic Writing Setup

This skill configures Claude for the **output side** of academic work: writing theses, journal papers, conference submissions, dissertations, and abstracts. It pairs with `research-setup` (input side — reading papers, notes) and `knowledge-base-setup` (personal notes) but focuses on producing manuscripts.

Use this skill when the project is primarily a LaTeX or Typst document, not a literature survey or a generic research notebook.

**Handoff context:** Read `skills/_shared/consume-handoff.md` and run it with the handoff block (if any). The helper guarantees the following locals: `detected_language`, `existing_claude_md`, `inferred_use_case`, `repo_signals`, `graphify_candidate`. Use `detected_language` for all user-facing prose; generated file content stays in English.

**Existing CLAUDE.md:** If `existing_claude_md: true`, DO NOT overwrite it. Append a new delimited section at the end of the file:

```
<!-- onboarding-agent:start setup=academic-writing skill=academic-writing-setup section=claude-md -->
## Claude Onboarding Agent — Academic Writing Setup
...generated content...
<!-- onboarding-agent:end -->
```

If the delimited block already exists from a previous run (either the attributed form above or the legacy unattributed `<!-- onboarding-agent:start -->` form), replace only the content between the markers; leave the rest of the file untouched. Upgrade the opening marker to the attributed form — `/upgrade-setup` depends on it for detection.

## Supporting Files

Read these on-demand at the step that invokes them. Do not read eagerly.

- `rule-file-templates.md` — bodies of the `.claude/rules/*.md` files (Step 4)
- `document-skeletons.md` — directory scaffold, `main.tex`, `main.typ`, `bib/references.bib` (Step 4)
- `gitignore-block.md` — the `.gitignore` block (Step 4)
- `optional-integrations.md` — `.pre-commit-config.yaml`, Overleaf instructions, template pointer, KB bridge (Step 4)
- `skills/_shared/consume-handoff.md` — orchestrator handoff parse + inline fallback (preamble, before Step 1)
- `skills/_shared/offer-superpowers.md` — canonical Superpowers opt-in (Step 1)

## Step 1: Install Dependencies

Read `skills/_shared/offer-superpowers.md` and run it with `skill_slug: academic-writing-setup`, `mandatory: false`, `capability_line: "A free Claude Code skills library (94,000+ users). Brainstorming and planning skills help structure long arguments, chapter outlines, and multi-section revisions."` The helper asks the user, delegates to `skills/_shared/installation-protocol.md` on `yes`, and sets `superpowers_installed`, `superpowers_scope`, `superpowers_method`.

## Step 2: Verify Writing Toolchain

Probe the environment (via Bash) BEFORE asking context questions so the installation hints match what the user actually has.

Run each of these and record the outcome:

- `pdflatex --version` → sets `latex_available: true|false`
- `tectonic --version` → sets `tectonic_available: true|false`
- `typst --version` → sets `typst_available: true|false`
- `biber --version` → sets `biber_available: true|false`
- `chktex --version` → sets `chktex_available: true|false`
- `vale --version` → sets `vale_available: true|false`

If NEITHER `latex_available` NOR `tectonic_available` NOR `typst_available` is true, print ONCE:

> "⚠ No LaTeX or Typst toolchain detected. Setup will continue and emit all configuration as instructions, but you will not be able to compile the document locally until you install one of:
>  - macOS: MacTeX — https://tug.org/mactex/
>  - Linux: TeX Live — https://tug.org/texlive/
>  - Cross-platform (lightweight LaTeX): Tectonic — https://tectonic-typesetting.github.io/
>  - Modern alternative: Typst — https://github.com/typst/typst/releases
>  Re-run this skill after installing if you want the configuration regenerated."

Never try to install these automatically. Never silently proceed — the warning must appear.

## Step 3: Context Questions

Ask these questions ONE AT A TIME. Wait for each answer before asking the next.

1. "Which discipline is this work in?
   A) STEM (engineering, computer science, physics, chemistry, biology, math)
   B) Humanities (philosophy, history, literature, linguistics)
   C) Social sciences (economics, psychology, sociology, political science)
   D) Medicine / life sciences
   E) Other — please specify"

2. "What are you writing?
   A) Thesis / dissertation (bachelor, master, PhD)
   B) Journal or conference paper
   C) Mixed — the repo will hold several documents"

3. "Which writing stack do you want to target?
   A) LaTeX (local compile: pdflatex / lualatex / xelatex)
   B) LaTeX via Overleaf (with Git bridge back to this repo)
   C) Tectonic (single-binary LaTeX — simpler install, same sources)
   D) Typst (modern alternative, faster compile, simpler syntax)"

4. "Which citation style?
   A) APA (7th edition)
   B) IEEE
   C) Vancouver
   D) Chicago / Turabian
   E) Springer / Nature
   F) ACM
   G) Other — please specify (e.g. a university-specific style)"

5. "In which language will the manuscripts be written?
   A) English
   B) German
   C) Other — please specify
   D) Mixed (e.g. German thesis, English paper)"

6. "Do you use Zotero for reference management?
   A) Yes — I already use it
   B) Yes — I'm willing to set it up
   C) No — I manage `.bib` entries manually
   D) I use a different manager (Paperpile, Mendeley, EndNote)"

(Superpowers was already offered in Step 1 — no separate question here.)

## Step 4: Offer Project-Local Subagent

Read `skills/_shared/emit-subagent.md` and follow it with these inputs:

- `slug`: `writing-style-auditor`
- `purpose_blurb`: "Audit an academic passage for voice, tense, structure, and citation hygiene against the project's rules."
- `frontmatter_description`: "Use to audit an academic passage (paragraph, section, or chapter draft) for voice, tense, section-structure compliance, and citation hygiene against the project's writing-style and citation rules. Dispatch when the user asks to review a paragraph, check style, verify citations, or 'audit this section'."
- `tools_list`: `Read, Grep, Glob`
- `rules_files`: `.claude/rules/writing-style.md, .claude/rules/citation-rules.md`
- `body_markdown`:

  ```
  You are the Writing Style Auditor. You audit academic prose against the project's writing-style and citation rules.

  ## Procedure
  1. Identify the target passage (paragraph, section, or file).
  2. Read writing-style.md (voice, tense, section rules) and citation-rules.md (.bib conventions, no-invented-citations).
  3. Audit for: first-person violations if passive is required, tense drift, banned AI-slop patterns, missing or malformed citations, invented citation keys, overlong sentences if the style file prescribes a limit.
  4. Return a structured verdict: target passage, findings with line reference and severity, concrete rewrite suggestions (describe, do not apply).

  ## Rules
  - Do not rewrite the passage. Describe the fix; let the caller apply it.
  - Never invent a citation to fill a gap — flag the gap instead.
  - If a rules file is missing, audit against general academic conventions and say so in the header.
  ```

Record the emit outcome for use in the completion summary (Step 8). If `emit_subagent: true`, add `"writing-style-auditor"` to the list passed to `skills/_shared/write-meta.md` in Step 6 as `subagents_installed`.

## Step 5: Generate Artifacts

For each file below, if it already exists extend rather than overwrite. Use `<!-- onboarding-agent:start -->` / `<!-- onboarding-agent:end -->` markers for CLAUDE.md; use `# onboarding-agent: academic-writing — start` / `# onboarding-agent: academic-writing — end` markers for `.gitignore`.

### CLAUDE.md (≤ 30 lines — pointers only)

```markdown
# Claude Instructions — Academic Writing

## Project Context
Discipline: [Q1]. Output type: [Q2]. Stack: [Q3]. Citation style: [Q4]. Language: [Q5]. Reference manager: [Q6].

## Key Pointers
- Writing style (voice, tense per section, sentence length): `.claude/rules/writing-style.md`
- Citation rules and `.bib` conventions: `.claude/rules/citation-rules.md`
- Document structure: `sections/` (chapters / sections), `figures/`, `data/`, `bib/references.bib`

## Non-negotiable Rules
- Do NOT invent citations. Only cite keys that exist in `bib/references.bib`. If a relevant source is missing, ask the user to add it — never fabricate a citation key, DOI, author name, title, page number, or year.
- Suggest phrasings; do not rewrite whole paragraphs unless explicitly asked. Prefer inline "alternative:" suggestions over silent replacements.
- Preserve existing citation commands and labels when editing — never rename `\cite{…}` keys or `\label{…}` anchors.

[Include ONLY if superpowers_installed is true]
## Superpowers
Superpowers is installed. Use `superpowers:brainstorming` before starting a chapter, and `superpowers:writing-plans` for multi-section revisions.
```

Keep this file short (≤ 30 lines). All detail lives in `.claude/rules/*.md`.

### .claude/rules/writing-style.md

Read `rule-file-templates.md` and write its `writing-style` section to `.claude/rules/writing-style.md`. Skip the write if the file already exists.

### .claude/rules/citation-rules.md

Read `rule-file-templates.md` and write its `citation-rules` section to `.claude/rules/citation-rules.md`. Skip the write if the file already exists.

### Document scaffold and skeletons

Read `document-skeletons.md`. Create the directory scaffold (LaTeX layout if Q3 ∈ {A, B, C}; Typst layout if Q3 = D); leave any already-existing directory untouched. If `main.tex` is missing and Q3 ∈ {A, B, C}, emit the `main.tex` skeleton from the same file with `<biblatex-style>` substituted per Q4. If `main.typ` is missing and Q3 = D, emit the `main.typ` skeleton with `<csl-style>` substituted per Q4. If `bib/references.bib` is missing, emit the commented-example entry.

### .gitignore

Read `gitignore-block.md` and append its block to the user's `.gitignore` (delimited markers; replace only the content between them if already present).

### Optional integrations

Read `optional-integrations.md`. Emit the `.pre-commit-config.yaml` scaffold if `chktex_available` or `vale_available` is true OR the user requested it, and print the matching missing-tool warnings. If Q3 = B, print the Overleaf + Git bridge instructions. If Q2 = A or B, print the template pointer note. Mention the knowledge-base bridge only when the user references an existing vault / wiki.

### Optional: SessionStart rules-reload hook

Ask ONCE (adapt to detected language):

> "Install the session-start rules-reload hook? At every new Claude Code session or resume, the hook injects the current `writing-style.md` + `citation-rules.md` text as additional context. Keeps voice and citation discipline consistent across long writing projects. (yes / no)"

Default on empty input: `yes`.

On `no`: set `acad_hook_emitted: false` and skip.

On `yes`:

1. Write the reload script body:

   ```bash
   #!/usr/bin/env bash
   # Generated by claude-onboarding-agent (skill: academic-writing-setup)
   # Purpose: re-inject writing-style and citation rules at session start.
   # Safe to delete — Claude Code will continue without the hook.

   set -u

   cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || exit 0

   PARTS=()
   for f in .claude/rules/writing-style.md .claude/rules/citation-rules.md; do
     if [ -f "$f" ]; then
       PARTS+=("### $f")
       PARTS+=("$(cat "$f")")
       PARTS+=("")
     fi
   done

   [ "${#PARTS[@]}" -eq 0 ] && exit 0

   CTX=$(printf '%s\n' "${PARTS[@]}")
   jq -cn --arg ctx "$CTX" \
     '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
   exit 0
   ```

2. Set the hook spec (the helper writes `"_plugin": "claude-onboarding-agent"` and `"_skill": "academic-writing-setup"` into the emitted entry):

   ```
   hook_entries = [
     {
       event: "SessionStart",
       matcher: "startup|resume",
       command: "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/academic-rules-reload.sh\"",
       script_name: "academic-rules-reload.sh",
       script_source: <the bash block above>
     }
   ]
   skill_slug = "academic-writing-setup"
   ```

3. Read `skills/_shared/emit-hook.md` and follow every step H1–H7.

4. Capture the status variables.

## Step 6: Write Upgrade Metadata

Set `setup_slug: academic-writing`, `skill_slug: academic-writing-setup`. Resolve `plugin_version` from the plugin's own `plugin.json`. If Step 4 emitted the `writing-style-auditor` subagent, set `subagents_installed: ["writing-style-auditor"]`; otherwise leave it unset. Then follow `skills/_shared/write-meta.md` to create or merge `./.claude/onboarding-meta.json`.

## Step 7: Render Anchor Sections

Read `skills/_shared/anchor-mapping.md`. Locate the row for `setup_type: academic-writing`. For each anchor slug in that row:

1. Call `skills/_shared/render-anchor-section.md` with:
   - `setup_type: academic-writing`
   - `skill_slug: academic-writing-setup`
   - `anchor_slug: <slug>`
   - `target_file: ./CLAUDE.md`
   - `fallback_content: <embedded fallback from skills/anchors/SKILL.md for that slug>`
2. If a `./AGENTS.md` file was generated earlier in this skill, repeat the call with `target_file: ./AGENTS.md`.

Do not fail if any single `render-anchor-section.md` call returns `placeholder`. Collect rendered / placeholder slugs for the completion summary.

## Step 8: Completion Summary

```
✓ Academic writing setup complete!

Files created / updated:
  CLAUDE.md                              — pointers + non-negotiable rules (delimited section)
  .claude/rules/writing-style.md         — voice, tense per section, section rules
  .claude/rules/citation-rules.md        — no-invented-citations rule, .bib conventions
  sections/, figures/, data/, bib/       — [created | skipped — already existed]
  bib/references.bib                     — [created with commented example | left untouched]
  main.tex or main.typ                   — [created skeleton | left untouched — already present]
  .gitignore                             — LaTeX/Typst artifact rules (delimited section)
  .pre-commit-config.yaml                — [emitted as instructions | skipped per user]
  .claude/agents/writing-style-auditor.md — project-local subagent (auto-invoked) [only on yes path; if skipped existing: .claude/agents/writing-style-auditor.md (already existed — skipped; re-run /checkup --rebuild to regenerate); if no/later: Subagent writing-style-auditor not installed — re-run /academic-writing-setup to add it later.]
  .claude/onboarding-meta.json           — setup marker for /upgrade-setup

External skills:
  [✓ Superpowers installed via superpowers_method (superpowers_scope)]
  [skipped — install later with: /plugin install superpowers@claude-plugins-official]
  [⚠ Superpowers installation failed — install manually: https://github.com/obra/superpowers]

Environment:
  [✓ LaTeX detected (pdflatex) | ✓ Tectonic detected | ✓ Typst detected | ⚠ no LaTeX/Typst toolchain — see install links printed earlier]
  [✓ biber | ⚠ biber missing — required for biblatex; ships with TeX Live / MacTeX]
  [✓ chktex | ⚠ chktex missing — ships with TeX Live / MacTeX]
  [✓ vale | ⚠ vale missing — brew install vale or https://vale.sh]

Reminders:
  - Do not invent citations. Every \cite{…} must exist in bib/references.bib.
  - Zotero users: enable Better BibTeX "Keep Updated" export into bib/references.bib.
  - Overleaf users: Overleaf is a Git remote — push from local first, then sync.

Hooks:
  [✓ SessionStart rules-reload hook written to .claude/settings.json + .claude/hooks/academic-rules-reload.sh
   | — skipped per user
   | ⚠ settings.json is corrupt — entries printed above for manual paste]

Next steps:
  1. Drop your institution's / venue's template (if any) into the project root.
  2. If using Zotero, wire the Better BibTeX auto-export to bib/references.bib.
  3. Start a new Claude session: "Draft the Methods section from the bullet points in sections/03-methods.tex" — Claude will respect the rules in CLAUDE.md.
  - Run `/anchors` any time to refresh the anchor-derived sections. If any section was rendered as a placeholder due to offline mode, re-run `/anchors` once you are back online.
```
