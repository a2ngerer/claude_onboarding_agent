---
name: research-setup
description: Set up Claude for academic research and writing — configures citation format, research domain, and writing tool preferences so Claude supports your workflow from literature review to final paper.
---

# Research Setup

This skill configures Claude for academic and research work.

**Language:** Use `detected_language` from handoff context, or detect from the user's first message and use it throughout.

**Existing CLAUDE.md:** If `existing_claude_md: true` in handoff context, or if CLAUDE.md exists in the filesystem, extend it by appending a new section (`## Claude Onboarding Agent — Research Setup`) rather than overwriting.

## Step 1: Install Dependencies

Read `skills/_shared/installation-protocol.md` and follow it for each dependency below.

Dependencies:
- Superpowers (optional) — description: "A free Claude Code skills library (94,000+ users). Brainstorming and planning skills work well for structuring research arguments and planning complex documents." — marketplace-id: `superpowers@claude-plugins-official`, github: `https://github.com/obra/superpowers`, name: `superpowers`

## Step 2: Context Questions

Ask one at a time:

1. "What is your research domain? (e.g., machine learning, economics, molecular biology, history, philosophy)"

2. "What citation format do you use?
   A) APA
   B) MLA
   C) Chicago / Turabian
   D) IEEE
   E) Vancouver
   F) Other — please specify"

3. "What do you primarily write in?
   A) LaTeX
   B) Word / Google Docs
   C) Markdown
   D) A mix"

## Step 3: Generate Artifacts

### CLAUDE.md

```markdown
# Claude Instructions — Research & Academic Writing

## Domain
Research domain: [answer from Q1]
Citation format: [answer from Q2]
Writing tool: [answer from Q3]

## Guidelines
- Always use [citation format] for all references and bibliographies
- When summarizing a paper, include: main contribution, methodology, key results, limitations
- For literature reviews: group papers thematically, not chronologically
- When building an argument: state the claim clearly, cite supporting evidence, address the strongest counterargument
- [If LaTeX] Format all citations as BibTeX entries. Use \cite{} in the body text.
- [If Word/Docs] Format all references in [citation format] style in a bibliography section at the end
- Never fabricate citations. If you cannot find a specific source, say so explicitly.
- When using information from training data (not a provided source), flag it clearly.

[Include ONLY if superpowers_installed is true]
## Superpowers
Superpowers is installed. For complex writing tasks — outlines, literature reviews, argument structures — use superpowers:brainstorming to map the structure before drafting.
```

### .gitignore

```gitignore
# LaTeX build artifacts
*.aux
*.log
*.bbl
*.blg
*.out
*.toc
*.fdb_latexmk
*.fls
*.synctex.gz

# Large files
*.pdf
*.zip

# OS
.DS_Store
Thumbs.db

# Claude local settings
.claude/settings.local.json
```

## Step 4: Optional Community Skills

> "Would you like to install additional community skills?
>
> A) claude-scientific-skills — NumPy, SciPy, pandas, matplotlib helpers for scientific Python
> B) claude-d3js-skill — data visualization patterns and D3.js helpers
> C) All of the above
> D) None
>
> (Multiple selections via comma, e.g. 'A, B')"

For each selected skill, run: `/plugin install <skill>@claude-plugins-official`

On failure: warn and continue. Add successfully installed skills to the Completion Summary under: `Optional community skills: [list or "none selected"]`

## Step 5: Completion Summary

```
✓ Research setup complete!

Files created:
  CLAUDE.md    — domain, citation format ([format]), and writing guidelines
  .gitignore   — LaTeX artifacts and large file rules

External skills:
  [✓ Superpowers installed via superpowers_method (superpowers_scope)]
  [skipped — install later with: /plugin install superpowers@claude-plugins-official]
  [⚠ Superpowers installation failed — install manually: https://github.com/obra/superpowers]

Optional community skills: [list of installed skills, or "none selected"]

Next steps:
  Start a new Claude session and say: "Summarize this paper: [paste abstract or upload PDF]"
  Or: "Help me outline a literature review on [topic]"
```
