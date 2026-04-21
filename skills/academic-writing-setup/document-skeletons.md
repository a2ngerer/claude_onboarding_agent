> Consumed by academic-writing-setup/SKILL.md at Step 4. Do not invoke directly.

# Document Skeletons — Academic Writing Setup

## Directory scaffold

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

## main.tex skeleton (LaTeX stacks only: Q3 = A, B, or C)

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

## main.typ skeleton (Typst only: Q3 = D)

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

## bib/references.bib

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
