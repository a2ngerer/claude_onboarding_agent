> Consumed by academic-writing-setup/SKILL.md at Step 4. Do not invoke directly.

# Rule File Templates — Academic Writing Setup

## writing-style

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

## citation-rules

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
