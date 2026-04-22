---
name: research-setup
description: Set up Claude for academic research and writing — configures citation format, research domain, and writing tool preferences so Claude supports your workflow from literature review to final paper.
---

# Research Setup

This skill configures Claude for academic and research work.

**Handoff context:** Read `skills/_shared/consume-handoff.md` and run it with the handoff block (if any). The helper guarantees the following locals: `detected_language`, `existing_claude_md`, `inferred_use_case`, `repo_signals`, `graphify_candidate`. Use `detected_language` for all user-facing prose; generated file content stays in English.

**Existing CLAUDE.md:** If `existing_claude_md: true`, DO NOT overwrite it. Append a new delimited section at the end of the file:

```
<!-- onboarding-agent:start setup=research skill=research-setup section=claude-md -->
## Claude Onboarding Agent — Research Setup
...generated content...
<!-- onboarding-agent:end -->
```

If the delimited block already exists from a previous run, replace only the content between the markers; leave the rest untouched. Wrap generated `.gitignore` entries in `# onboarding-agent: research — start` / `— end` markers so `/upgrade-setup` can refresh them non-destructively.

## Supporting Files

Read these on-demand at the step that invokes them. Do not read eagerly.

- `skills/_shared/consume-handoff.md` — orchestrator handoff parse + inline fallback (preamble, before Step 1)
- `skills/_shared/offer-superpowers.md` — canonical Superpowers opt-in (Step 1)
- `skills/_shared/offer-graphify.md` — canonical Graphify opt-in (Step 5)

## Step 1: Install Dependencies

Read `skills/_shared/offer-superpowers.md` and run it with `skill_slug: research-setup`, `mandatory: false`, `capability_line: "A free Claude Code skills library (94,000+ users). Brainstorming and planning skills work well for structuring research arguments and planning complex documents."` The helper asks the user, delegates to `skills/_shared/installation-protocol.md` on `yes`, and sets `superpowers_installed`, `superpowers_scope`, `superpowers_method`.

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

Assemble the block from the research-specific lines below plus the shared common patterns from `skills/_shared/gitignore-common.md`. Wrap in `# onboarding-agent: research — start` / `— end` markers.

Research-specific lines:

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
```

Then inline the block from `skills/_shared/gitignore-common.md` (OS noise, env files, `.claude/settings.local.json`).

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

## Step 5: Optional Graphify Integration

Research projects often carry large PDF libraries, Markdown notes, and literature folders — exactly what Graphify indexes.

Read `skills/_shared/offer-graphify.md` and run it with:

- `host_setup_slug: "research"`
- `host_skill_slug: "research-setup"`
- `run_initial_build: true`
- `install_git_hook: false` (research folders are usually not under git)
- `corpus_blurb: "your research corpus (PDFs, Markdown notes, code snippets via tree-sitter for 25 languages, diagrams, images, audio/video). This cuts token cost substantially on large literature folders"`

The helper owns the opt-in prompt and the three-way branch (yes / no / later),
delegating to `skills/_shared/graphify-install.md`. Record the `graphify_*`
variables it produces for use in Step 8.

## Step 6: Write Upgrade Metadata

Set `setup_slug: research`, `skill_slug: research-setup`. Resolve `plugin_version` from the plugin's own `plugin.json`. Then follow `skills/_shared/write-meta.md` to create or merge `./.claude/onboarding-meta.json`. If Step 5 installed Graphify, `skills_used` will include both `research-setup` and `graphify-setup`.

## Step 7: Render Anchor Sections

Read `skills/_shared/anchor-mapping.md`. Locate the row for `setup_type: research`. For each anchor slug in that row:

1. Call `skills/_shared/render-anchor-section.md` with:
   - `setup_type: research`
   - `skill_slug: research-setup`
   - `anchor_slug: <slug>`
   - `target_file: ./CLAUDE.md`
   - `fallback_content: <embedded fallback from skills/anchors/SKILL.md for that slug>`
2. If a `./AGENTS.md` file was generated earlier in this skill, repeat the call with `target_file: ./AGENTS.md`.

Do not fail if any single `render-anchor-section.md` call returns `placeholder`. Collect rendered / placeholder slugs for the completion summary.

For every call, also capture `render_freshness`. When it is anything other than `network` or `cache` (i.e. `fallback` or `embedded`), record the `(anchor_slug, render_freshness)` pair in `anchor_freshness_notes`. The completion summary's `Anchor freshness` line consumes this list.

## Step 8: Cascade to academic-writing-setup (conditional)

Research projects often ship a manuscript folder next to the literature — when they do, `academic-writing-setup` configures the writing side (voice, citation rules, LaTeX scaffold). Offer the cascade when signals suggest the user is also authoring a paper in this repo.

### Detection

Probe the project root (read-only, non-fatal on any error):

- `main.tex` or `main.typ` at the root
- `paper.tex`, `thesis.tex`, `manuscript.tex`, or `dissertation.tex` at the root
- Any `*.tex` file inside `sections/`, `chapters/`, or `manuscript/`
- A `bib/` directory OR a `*.bib` file at the root

If none match, skip to Step 9. Record `cascade_offered: false`.

### Offer

If at least one signal matched, ask once (adapt to `detected_language`):

> "Ein Manuskript-Gerüst wurde erkannt ([list matched signals, max 3]). Auch `academic-writing-setup` direkt im Anschluss ausführen? Das konfiguriert die Schreibseite (Stil, Zitationsregeln, LaTeX-Scaffold). (yes / no)"

Record the answer as `cascade_accepted`.

- On `no`: set `cascade_offered: true`, `cascade_accepted: false`, `cascade_ran: false`. Continue to Step 9.
- On `yes`: set `cascade_offered: true`, `cascade_accepted: true`. Proceed to Invocation.

### Invocation

Construct the cascade handoff payload. Copy every field from the handoff context this skill received and add the two cascade markers:

```json
{
  "detected_language": "<current detected_language>",
  "existing_claude_md": <current existing_claude_md>,
  "inferred_use_case": "<current inferred_use_case>",
  "repo_signals": <current repo_signals object>,
  "graphify_candidate": <current graphify_candidate>,
  "source": "orchestrator",
  "source_skill": "research-setup",
  "superpowers_offered": <true if Step 1 already asked the user about Superpowers, else false>
}
```

Invoke `skills/academic-writing-setup/SKILL.md` with this payload as the handoff block. The child skill will read the two cascade markers and skip its own language detection preamble and its own Superpowers offer.

Record `cascade_ran: true` once the child skill returns. Do not retry on failure — log the outcome and continue to Step 9.

## Step 9: Completion Summary

```
✓ Research setup complete!

Files created:
  CLAUDE.md                     — domain, citation format ([format]), and writing guidelines
  .gitignore                    — LaTeX artifacts and large file rules
  .claude/onboarding-meta.json  — setup marker for /upgrade-setup

External skills:
  [✓ Superpowers installed via superpowers_method (superpowers_scope)]
  [skipped — install later with: /plugin install superpowers@claude-plugins-official]
  [⚠ Superpowers installation failed — install manually: https://github.com/obra/superpowers]

Optional community skills: [list of installed skills, or "none selected"]

Graphify (knowledge graph):
  [✓ installed via <installer>, /graphify + PreToolUse hook registered | ⚠ installed but hook not verified — run /graphify in a new session | — skipped: <reason> | — deferred: run /graphify-setup when ready | — not offered]

Cascade:
  [omit the whole line if cascade_offered is false; otherwise:
   ✓ Cascaded into academic-writing-setup — see its summary above for writing-side artifacts. |
   — Cascade declined; run /academic-writing-setup later if you also need writing-side rules.]

Anchor freshness:
  [omit the whole block if anchor_freshness_notes is empty; otherwise one line per entry:
   Anchor <anchor_slug> served from <render_freshness> — consider running /anchors to refresh.]

Next steps:
  Start a new Claude session and say: "Summarize this paper: [paste abstract or upload PDF]"
  Or: "Help me outline a literature review on [topic]"
  [If Graphify installed] Try: /graphify query "which papers discuss <topic>?"
  - Run `/anchors` any time to refresh the anchor-derived sections. If any section was rendered as a placeholder due to offline mode, re-run `/anchors` once you are back online.
```
