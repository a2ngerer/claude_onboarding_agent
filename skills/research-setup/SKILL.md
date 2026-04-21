---
name: research-setup
description: Set up Claude for academic research and writing — configures citation format, research domain, and writing tool preferences so Claude supports your workflow from literature review to final paper.
---

# Research Setup

This skill configures Claude for academic and research work.

**Language:** Use `detected_language` from handoff context, or detect from the user's first message and use it throughout.

**Existing CLAUDE.md:** If `existing_claude_md: true` in handoff context, or if CLAUDE.md exists in the filesystem, DO NOT overwrite it. Append a new delimited section at the end of the file:

```
<!-- onboarding-agent:start setup=research skill=research-setup section=claude-md -->
## Claude Onboarding Agent — Research Setup
...generated content...
<!-- onboarding-agent:end -->
```

If the delimited block already exists from a previous run, replace only the content between the markers; leave the rest untouched. Wrap generated `.gitignore` entries in `# onboarding-agent: research — start` / `— end` markers so `/upgrade-setup` can refresh them non-destructively.

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

## Step 5: Optional Graphify Integration

Research projects often carry large PDF libraries, Markdown notes, and literature folders — exactly what Graphify indexes. Ask ONCE (adapt to detected language):

> "Install Graphify knowledge-graph integration now?
>
> Graphify indexes your research corpus (PDFs, Markdown notes, code snippets via tree-sitter for 25 languages, diagrams, images, audio/video) into a local graph, registers a `/graphify` slash command, and adds a PreToolUse hook that consults the graph BEFORE Claude runs Grep / Glob / Read. This cuts token cost substantially on large literature folders. See https://github.com/safishamsi/graphify.
>
> (yes / no / later)"

- **yes** → set `host_setup_slug: "research"`, `host_skill_slug: "research-setup"`, `run_initial_build: true`, `install_git_hook: false` (research folders are usually not under git). Read `skills/_shared/graphify-install.md` and follow steps G1–G9 in order. The protocol writes the attributed CLAUDE.md section with `setup=research skill=graphify-setup section=graphify`.
- **no** → set `graphify_installed: false` and skip to Step 6.
- **later** → invoke `skills/_shared/graphify-install.md` in "later" mode: skip G1–G7 and write only the short deferred pointer block. Set `graphify_installed: false`, `graphify_deferred: true`.

## Step 6: Write Upgrade Metadata

Set `setup_slug: research`, `skill_slug: research-setup`. Resolve `plugin_version` from the plugin's own `plugin.json`. Then follow `skills/_shared/write-meta.md` to create or merge `./.claude/onboarding-meta.json`. If Step 5 installed Graphify, `skills_used` will include both `research-setup` and `graphify-setup`.

## Step 7: Completion Summary

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

Next steps:
  Start a new Claude session and say: "Summarize this paper: [paste abstract or upload PDF]"
  Or: "Help me outline a literature review on [topic]"
  [If Graphify installed] Try: /graphify query "which papers discuss <topic>?"
```
