---
name: academic-writing-setup
description: Set up Claude for academic writing — thesis, paper, or dissertation. Configures LaTeX/Typst stack, bibliography (Zotero + Better BibTeX), citation style, and strict no-invented-citations rules so Claude helps you write without hallucinating references.
---

# Academic Writing Setup

This skill configures Claude for the **output side** of academic work: writing theses, journal papers, conference submissions, dissertations, and abstracts. It pairs with `research-setup` (input side — reading papers, notes) and `knowledge-base-setup` (personal notes) but focuses on producing manuscripts.

Use this skill when the project is primarily a LaTeX or Typst document, not a literature survey or a generic research notebook.

**Language:** Use `detected_language` from handoff context, or detect from the user's first message and use it throughout. All generated file content stays in English.

**Existing CLAUDE.md:** If `existing_claude_md: true` in handoff context, or if `CLAUDE.md` already exists in the filesystem, DO NOT overwrite it. Append a new delimited section at the end of the file:

```
<!-- onboarding-agent:start setup=academic-writing skill=academic-writing-setup section=claude-md -->
## Claude Onboarding Agent — Academic Writing Setup
...generated content...
<!-- onboarding-agent:end -->
```

If the delimited block already exists from a previous run (either the attributed form above or the legacy unattributed `<!-- onboarding-agent:start -->` form), replace only the content between the markers; leave the rest of the file untouched. Upgrade the opening marker to the attributed form — `/upgrade-setup` depends on it for detection.

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
- Writing style (voice, tense per section, sentence length): `claude_instructions/writing-style.md`
- Citation rules and `.bib` conventions: `claude_instructions/citation-rules.md`
- Document structure: `sections/` (chapters / sections), `figures/`, `data/`, `bib/references.bib`

## Non-negotiable Rules
- Do NOT invent citations. Only cite keys that exist in `bib/references.bib`. If a relevant source is missing, ask the user to add it — never fabricate a citation key, DOI, author name, title, page number, or year.
- Suggest phrasings; do not rewrite whole paragraphs unless explicitly asked. Prefer inline "alternative:" suggestions over silent replacements.
- Preserve existing citation commands and labels when editing — never rename `\cite{…}` keys or `\label{…}` anchors.

[Include ONLY if superpowers_installed is true]
## Superpowers
Superpowers is installed. Use `superpowers:brainstorming` before starting a chapter, and `superpowers:writing-plans` for multi-section revisions.
```

Keep this file short (≤ 30 lines). All detail lives in `claude_instructions/*.md`.

### claude_instructions/writing-style.md

```markdown
# Writing Style

## Voice
- Prefer active voice for clarity. Example: "We measured X" rather than "X was measured".
- Humanities conventions (Q1 = B) may favor passive or third-person constructions — follow the user's lead if they correct an edit.

## Tense by section
- Abstract: present for the contribution, past for what was done. ("We propose X. We evaluated X on …")
- Introduction: present (the problem is X; this work contributes Y).
- Related work: present or present perfect ("Smith proposes", "Several studies have shown").
- Methods: past, passive or active depending on discipline ("We trained a model" / "The model was trained").
- Results: past ("The model achieved 92% accuracy").
- Discussion: present ("These results suggest").
- Conclusion: present / future ("We conclude that …; future work will …").

## Sentence length
- Target 15–25 words for a typical sentence. Break anything above 35 words.
- Avoid stacked subordinate clauses. One main idea per sentence.

## Section-specific rules
- Abstract: self-contained, no citations, no undefined abbreviations, ≤ 250 words (adjust per venue).
- Methods: reproducible. A reader must be able to replicate without reading the rest of the paper.
- Results: describe, do not interpret. Interpretation belongs in Discussion.
- Discussion: explicitly address limitations and threats to validity.

## What Claude should NOT do
- Do not silently "improve" technical terms by swapping synonyms — terminology is load-bearing.
- Do not reorder citations unless asked.
- Do not change mathematical notation, variable names, or theorem labels without explicit instruction.
- Do not translate the manuscript between languages unless explicitly asked.
```

### claude_instructions/citation-rules.md

```markdown
# Citation Rules

## Non-negotiable
**Every citation must resolve to an existing entry in `bib/references.bib`.** Claude must not:
- Invent a citation key, DOI, ISBN, arXiv ID, or URL.
- Guess an author's name, year, journal, or page number.
- Cite from memory when the source is not in `references.bib`.

If a needed source is missing, Claude asks the user:
> "I need to cite <topic>. Can you add the BibTeX entry to `bib/references.bib`, or paste the citation details so I can prepare the entry for you to verify?"

## Preferred citation commands
- LaTeX (Q3 = A/B/C): use `\cite{key}` for neutral citation, `\citep{key}` / `\citet{key}` if the document uses natbib/biblatex-apa, `\autocite{key}` for biblatex.
- Typst (Q3 = D): use `@key` or `#cite(<key>)` — match whatever the template defines.

## `.bib` entry conventions (Q6 = Zotero)
- Primary tool: Zotero with the **Better BibTeX** plugin — https://retorque.re/zotero-better-bibtex/
- Configure Better BibTeX to use the citekey format: `auth.lower + year + shorttitle3_3`
  (e.g. `smith2023deeplearning`). Keys must be stable — never rename a key once used in the manuscript.
- Auto-export the project collection to `bib/references.bib` (Better BibTeX → Export → Keep Updated).
- Commit `references.bib` to git. Do NOT commit Zotero's internal database.

## `.bib` entry conventions (Q6 = manual or other manager)
- Keys follow `authoryearkeyword` lowercase (`smith2023transformer`). No spaces, no accents.
- Always include: `author`, `title`, `year`. For articles add `journal`, `volume`, `number`, `pages`, `doi`. For conference papers add `booktitle`, `pages`, `doi`. For books add `publisher`, `address`.
- Prefer DOI over URL. If only a URL is available, add `urldate = {YYYY-MM-DD}`.

## When Claude drafts text
- If a claim needs a source and no matching `.bib` entry exists, insert a placeholder like `\cite{TODO-author-topic-year}` and list the placeholder in the response so the user can fill it in. Never invent the key.
- When summarizing a paper already in `references.bib`, quote selectively and keep direct quotations below 25 words; use block quotes for longer excerpts and always include the page number.
```

### Directory scaffold

Create the following structure in the user's project root. If a directory already exists, leave it untouched.

For LaTeX stacks (Q3 = A, B, or C):

```
sections/.gitkeep
figures/.gitkeep
data/.gitkeep
bib/references.bib        — seeded with a single commented-out example entry
main.tex                  — minimal skeleton (documentclass, input of sections, biblatex/natbib config)
```

For Typst stack (Q3 = D):

```
sections/.gitkeep
figures/.gitkeep
data/.gitkeep
bib/references.bib        — Typst reads BibTeX too; keep the same name for portability
main.typ                  — minimal skeleton with #bibliography("bib/references.bib") and the chosen style
```

Do not scaffold any directory that already exists. Never overwrite `main.tex` or `main.typ` — if present, print: "Found existing main.[tex|typ] — left untouched. The structure under sections/ / figures/ / data/ / bib/ was added around it."

### `main.tex` skeleton (LaTeX stacks only)

```latex
% Onboarding-agent generated skeleton — replace with your template as needed.
\documentclass[11pt,a4paper]{article}

% Language — adjust for Q5
\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc}
\usepackage[english]{babel} % change to 'ngerman' for DE

% Bibliography — biblatex is preferred over bibtex/natbib for new projects.
% Style is set to match Q4. Override here if your venue requires a different .bst/.bbx.
\usepackage[style=<biblatex-style>,backend=biber]{biblatex}
\addbibresource{bib/references.bib}

\title{Working title}
\author{Your Name}

\begin{document}
\maketitle

\input{sections/00-abstract.tex}
\input{sections/01-introduction.tex}
% \input{sections/02-related-work.tex}
% \input{sections/03-methods.tex}
% \input{sections/04-results.tex}
% \input{sections/05-discussion.tex}
% \input{sections/06-conclusion.tex}

\printbibliography
\end{document}
```

Replace `<biblatex-style>` using the Q4 answer:
- APA → `apa`
- IEEE → `ieee`
- Vancouver → `vancouver` (load `biblatex-vancouver` package)
- Chicago → `chicago-authordate`
- Springer / Nature → `nature`
- ACM → `acmnumeric`
- Other → leave as a comment and ask the user for the correct style name.

Seed `sections/00-abstract.tex` and `sections/01-introduction.tex` as empty stubs with a one-line comment:

```latex
% 00-abstract.tex — self-contained summary, ≤ 250 words, no citations.
```

```latex
% 01-introduction.tex — problem statement and this work's contribution.
```

### `main.typ` skeleton (Typst only)

```typ
// Onboarding-agent generated skeleton — replace with your template as needed.
#set document(title: "Working title", author: "Your Name")
#set text(lang: "en") // change to "de" for DE

#align(center, text(17pt)[*Working title*])
#align(center, [Your Name])

= Abstract
#include "sections/00-abstract.typ"

= Introduction
#include "sections/01-introduction.typ"

#bibliography("bib/references.bib", style: "<csl-style>")
```

Replace `<csl-style>` based on Q4:
- APA → `apa`
- IEEE → `ieee`
- Vancouver → `vancouver`
- Chicago → `chicago-author-date`
- ACM → `association-for-computing-machinery`
- Springer / Nature → `springer-basic-author-date` (ask the user to confirm)

### `bib/references.bib`

Create if missing, with a single commented-out example so users see the expected format:

```bibtex
% References live here. Keep one entry per source. Do not commit Zotero database files.
% Example:
% @article{smith2023transformer,
%   author  = {Smith, Jane and Doe, John},
%   title   = {On the scalability of transformer architectures},
%   journal = {Journal of Machine Learning Research},
%   year    = {2023},
%   volume  = {24},
%   number  = {42},
%   pages   = {1--34},
%   doi     = {10.1000/jmlr.2023.42},
% }
```

### .gitignore

Append a delimited block at the end. If the marker block already exists, replace only the content between the markers.

```gitignore
# onboarding-agent: academic-writing — start
# LaTeX build artifacts
*.aux
*.bbl
*.bcf
*.blg
*.fdb_latexmk
*.fls
*.log
*.out
*.run.xml
*.synctex.gz
*.toc
*.lof
*.lot
*.nav
*.snm
*.vrb
_minted-*/
pdf-build/

# Typst build artifacts
*.typ.pdf

# Editor / OS noise
.DS_Store
Thumbs.db

# Claude local settings
.claude/settings.local.json
# onboarding-agent: academic-writing — end
```

Note: the compiled manuscript PDF (`main.pdf` / similar) is intentionally NOT ignored by default — many supervisors want the built artifact in git. If the user prefers to ignore it, they can add `main.pdf` manually.

### Optional: `.pre-commit-config.yaml` (chktex + vale)

If `chktex_available` or `vale_available` is true, OR if the user wants these enabled regardless, emit the following scaffold. Do NOT install anything automatically — print it as instructions.

```yaml
# Optional writing-quality hooks. Activate with: pre-commit install
repos:
  - repo: local
    hooks:
      - id: chktex
        name: chktex (LaTeX linter)
        entry: chktex -q -n1 -n3 -n8 -n24 -n25
        language: system
        files: \.tex$
        # Skip if chktex is not installed; the hook will fail loudly rather than silently.
      - id: vale
        name: vale (prose linter)
        entry: vale --minAlertLevel=warning
        language: system
        files: \.(tex|typ|md)$
```

Additionally print:

- If `chktex_available` is false: "⚠ `chktex` not detected — install it via your TeX distribution (it ships with TeX Live and MacTeX)."
- If `vale_available` is false: "⚠ `vale` not detected — install from https://vale.sh/docs/vale-cli/installation/ (Homebrew: `brew install vale`). A minimal `.vale.ini` is not generated here; run `vale sync` after picking a style package such as `write-good` or `Microsoft`."

If any helper ever needs Python (e.g. `pygmentize` for the LaTeX `minted` package), recommend installing via `uv tool run pygmentize` rather than `pip install Pygments`.

### Optional: Overleaf + Git bridge (only if Q3 = B)

Print these instructions; do not automate:

```
Overleaf pushes and pulls through a standard Git remote.

1. In Overleaf, open the project → Menu → Git → copy the HTTPS URL.
2. In this repo:
     git remote add overleaf <url>
     git fetch overleaf
     git merge overleaf/master --allow-unrelated-histories
3. Generate an Overleaf Git token (Account Settings → Git Integration) and cache it in your OS keychain.
4. Treat Overleaf as a secondary remote: push to GitHub first, then to Overleaf. Resolve conflicts locally.
5. Keep `bib/references.bib` authoritative on your machine (Better BibTeX auto-export). Do not edit references inside Overleaf.
```

### Optional: Template pointer (only if Q2 = A thesis OR B paper)

Add a short note to the completion summary (do not generate a template file):

- Thesis (Q2 = A): "University-specific thesis templates are usually supplied by your institution. Drop the template files into the project root; the generated `sections/` / `bib/` / `figures/` layout is compatible with most templates. Common examples: TUM, ETH, MIT, LaTeX `classicthesis`."
- Paper (Q2 = B): "Common venue templates: IEEE (`IEEEtran.cls`), ACM (`acmart.cls`), Springer (`svjour3.cls`), Elsevier (`elsarticle.cls`). Drop the class file into the project root and replace `\documentclass{article}` in `main.tex` accordingly."

### Optional: Knowledge-base bridge (mention only)

If the user mentions they already ran `knowledge-base-setup` (or a `wiki/` or `notes/` folder exists), tell them: "Claude can read your existing Obsidian vault / wiki notes as research input while drafting — point to them in `claude_instructions/writing-style.md` or by prefixing prompts with the relevant note path."

## Step 5: Write Upgrade Metadata

Set `setup_slug: academic-writing`, `skill_slug: academic-writing-setup`. Resolve `plugin_version` from the plugin's own `plugin.json`. Then follow `skills/_shared/write-meta.md` to create or merge `./.claude/onboarding-meta.json`.

## Step 6: Completion Summary

```
✓ Academic writing setup complete!

Files created / updated:
  CLAUDE.md                              — pointers + non-negotiable rules (delimited section)
  claude_instructions/writing-style.md   — voice, tense per section, section rules
  claude_instructions/citation-rules.md  — no-invented-citations rule, .bib conventions
  sections/, figures/, data/, bib/       — [created | skipped — already existed]
  bib/references.bib                     — [created with commented example | left untouched]
  main.tex or main.typ                   — [created skeleton | left untouched — already present]
  .gitignore                             — LaTeX/Typst artifact rules (delimited section)
  .pre-commit-config.yaml                — [emitted as instructions | skipped per user]
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

Next steps:
  1. Drop your institution's / venue's template (if any) into the project root.
  2. If using Zotero, wire the Better BibTeX auto-export to bib/references.bib.
  3. Start a new Claude session: "Draft the Methods section from the bullet points in sections/03-methods.tex" — Claude will respect the rules in CLAUDE.md.
```
