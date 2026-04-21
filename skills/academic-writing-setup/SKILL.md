---
name: academic-writing-setup
description: Set up Claude for academic writing — thesis, paper, or dissertation. Configures LaTeX/Typst stack, bibliography (Zotero + Better BibTeX), citation style, and strict no-invented-citations rules so Claude helps you write without hallucinating references.
---

# Academic Writing Setup

This skill configures Claude for the **output side** of academic work: writing theses, journal papers, conference submissions, dissertations, and abstracts. It pairs with `research-setup` (input side — reading papers, notes) and `knowledge-base-builder` (personal notes) but focuses on producing manuscripts.

Use this skill when the project is primarily a LaTeX or Typst document, not a literature survey or a generic research notebook.

**Language:** Use `detected_language` from handoff context, or detect from the user's first message and use it throughout. All generated file content stays in English.

**Existing CLAUDE.md:** If `existing_claude_md: true` in handoff context, or if `CLAUDE.md` already exists in the filesystem, DO NOT overwrite it. Append a new delimited section at the end of the file:

```
<!-- onboarding-agent:start setup=academic-writing skill=academic-writing-setup section=claude-md -->
## Claude Onboarding Agent — Academic Writing Setup
...generated content...
<!-- onboarding-agent:end -->
```

If the delimited block already exists from a previous run (either the attributed form above or the legacy unattributed `<!-- onboarding-agent:start -->` form), replace only the content between the markers; leave the rest of the file untouched. Upgrade the opening marker to the attributed form — `/upgrade` depends on it for detection.

## Supporting Files

Read these on-demand at the step that invokes them. Do not read eagerly.

- `rule-file-templates.md` — bodies of the `.claude/rules/*.md` files (Step 4)
- `document-skeletons.md` — directory scaffold, `main.tex`, `main.typ`, `bib/references.bib` (Step 4)
- `gitignore-block.md` — the `.gitignore` block (Step 4)
- `optional-integrations.md` — `.pre-commit-config.yaml`, Overleaf instructions, template pointer, KB bridge (Step 4)

## Step 1: Install Dependencies

Read `skills/_shared/installation-protocol.md` and follow it for each dependency below.

Dependencies:
- Superpowers (optional) — description: "A free Claude Code skills library (94,000+ users). Brainstorming and planning skills help structure long arguments, chapter outlines, and multi-section revisions." — marketplace-id: `superpowers@claude-plugins-official`, github: `https://github.com/obra/superpowers`, name: `superpowers`

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

7. "Optional: install Superpowers for structured brainstorming and multi-step writing plans? (yes / no)
   (Separate from the mandatory installation step above — only ask if not already installed.)"

## Step 4: Generate Artifacts

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

## Step 5: Write Upgrade Metadata

Set `setup_slug: academic-writing`, `skill_slug: academic-writing-setup`. Resolve `plugin_version` from the plugin's own `plugin.json`. Then follow `skills/_shared/write-meta.md` to create or merge `./.claude/onboarding-meta.json`.

## Step 6: Completion Summary

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
  .claude/onboarding-meta.json           — setup marker for /upgrade

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

Next steps:
  1. Drop your institution's / venue's template (if any) into the project root.
  2. If using Zotero, wire the Better BibTeX auto-export to bib/references.bib.
  3. Start a new Claude session: "Draft the Methods section from the bullet points in sections/03-methods.tex" — Claude will respect the rules in CLAUDE.md.
```
