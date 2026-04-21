---
name: onboarding
description: Guided onboarding orchestrator — scans your repo, infers your use case, and dispatches to the right setup skill. Run this if you're new and want a personalized Claude Code setup.
---

# Claude Onboarding Agent

Welcome. This skill scans your project, asks you one question, and then configures Claude exactly the way you need it.

## Argument parsing

The invocation may contain `--rebuild` anywhere in the argument string (as a flag, not a value).

- If present: set `rebuild_mode: true`. Step 1a's early-exit is skipped; existing onboarding-agent-managed files are backed up first (see Step 1b), then the normal flow runs and produces fresh artifacts.
- Otherwise: set `rebuild_mode: false`.

Any other argument is ignored silently.

## Step 1: Detect Language

Read the user's first message. Detect the language (e.g., English, German, Spanish, French). Respond in that language for the entire session. All generated file comments also use that language. Technical field names, tool names, and code remain in English regardless of detected language.

## Step 1a: Detect existing setup (skip if `rebuild_mode: true`)

Before scanning the repo for use-case signals, check whether an onboarding-agent setup is already present:

- Read `./.claude/onboarding-meta.json` if it exists and parses as JSON. If `setup_type` is a recognized slug, capture `setup_type` and `installed_at`.
- Otherwise, search for the regex `<!--\s*onboarding-agent:start` in `./CLAUDE.md`, `./AGENTS.md`, and the key `"_onboarding_agent"` in `./.claude/settings.json`. If any match, treat as "marker-only" detection (no meta file).

If either a meta file or any marker is found, print (adapt to detected language):

> "Existing onboarding-agent setup detected (type: `<setup_type>`, installed `<installed_at>`). Re-running `/onboarding` would overwrite or duplicate existing sections.
>
> Run `/checkup` to decide whether to rebuild or selectively improve this setup, or re-run `/onboarding --rebuild` to force a full rebuild (existing files will be backed up to `.claude/backups/<timestamp>/` first)."

Exit here. Do not proceed to Step 2.

If nothing is detected, or `rebuild_mode: true`, continue.

## Step 1b: Backup before rebuild (only if `rebuild_mode: true`)

Before any scanning or file generation, back up every onboarding-agent-managed file that currently exists in the repo. Skip this step silently if nothing matches.

1. Compute `timestamp = <YYYYMMDD-HHMMSS>` in local time (single value for this invocation).
2. Create the backup root via Bash: `mkdir -p .claude/backups/<timestamp>/`.
3. For each of the following paths that exists on disk, copy it into the backup folder preserving the relative path:
   - `./CLAUDE.md`
   - `./AGENTS.md`
   - `./.claude/settings.json`
   - `./.claude/settings.local.json` (user-modified — never discard without a copy)
   - `./.claude/onboarding-meta.json`
   - `./claude_instructions/` (recursive — include every `.md` under it)

   Use Bash `cp --parents` where available, otherwise `mkdir -p "$(dirname dest)"` and `cp` the file (or `cp -R` for directories).

4. **Backup failure aborts onboarding.** If any copy fails, print:

   > "⚠ Backup failed for `<path>`: `<error>`. Aborting onboarding before any file is touched. Nothing has been modified. Re-run once the cause is fixed, or back up manually and try again."

   Exit. Do not proceed to Step 2.

5. Store `rebuild_backup_path = .claude/backups/<timestamp>/` for the completion summary.

After a successful backup, continue with Step 2 normally. The existing files are **not** deleted — setup skills will overwrite / extend them as they normally would. The backup is the user's restore point.

## Step 2: Scan the Repository

Before asking anything, silently scan the current directory:

- Count file extensions: `.py`, `.ts`, `.js`, `.go`, `.rs`, `.rb`, `.java`, `.cs` → coding signal
- Look for package manifests: `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `requirements.txt` → strong coding signal
- Look for web-framework config or entry points: `next.config.{js,mjs,ts}`, `vite.config.{js,mjs,ts}`, `astro.config.{mjs,ts}`, `remix.config.{js,ts}`, `svelte.config.{js,ts}`, `nuxt.config.{js,ts}`, `app/page.{tsx,jsx}`, `pages/` directory with `_app` or `index`, `src/routes/` (SvelteKit/Remix), `index.html` next to `public/`, or framework deps in `package.json` (`next`, `react-dom`, `vue`, `svelte`, `@sveltejs/kit`, `astro`, `@remix-run/*`, `solid-js`, `@nuxt/kit`) → **web-development signal** (this should dominate a generic coding signal when present — it indicates a web app, not a library or CLI)
- Look for `.ipynb` files, a `notebooks/` folder, `data/raw/`, or deps on `pandas`/`polars`/`numpy`/`scikit-learn`/`torch`/`jax` in `pyproject.toml` → data-science signal (this should dominate a generic Python coding signal when present)
- Look for `.tex`, `.bib` files → research signal
- Look for a `sections/` folder, a `bib/` folder, `main.tex`/`main.typ`, or a `.typ` file alongside `.bib` → **academic-writing signal** (this should dominate a generic research signal when present — it indicates the repo holds the manuscript, not just literature)
- Look for `*.docx`, `*.pptx`, `*.pdf`, `*.xlsx` files → office signal
- Look for a `notes/`, `vault/`, `wiki/`, `obsidian/` directory → knowledge base signal
- Count total source files and `*.md` / `*.pdf` / `*.ipynb` files. If the repo has a very large code corpus (e.g. > 1000 source files across 25+ tree-sitter languages) OR > 100 PDFs/Markdown notes under `docs/` / `raw/` / `notes/`, set `graphify_candidate: true` — this becomes a hint that a knowledge-graph index (via `graphify-setup`) could significantly reduce Claude's token cost on file-search calls. It is ONLY a hint; the primary use-case decision is unchanged.
- Check if `CLAUDE.md` already exists → set `existing_claude_md: true`
- Check if `AGENTS.md` already exists

Infer the most likely use case based on the strongest signal. If no clear signal exists, make no inference.

**If CLAUDE.md already exists:** Before presenting options, inform the user: "I found an existing CLAUDE.md. The setup skill will extend it (adding a new section) rather than overwriting it."

## Step 3: Present Options

Present all options. If an inference was made, place it at position 1 with a short note explaining what was detected. If no inference, present all options equally.

Example format (adapt wording to detected language):

If `graphify_candidate: true` from Step 2, also print a one-line aside under the numbered list: _"Heads-up: your repo is large enough that a local knowledge graph (option 11) could cut Claude's token cost on file-search tool calls. You can install it now, later via `/graphify-setup`, or layered on top of any of the other setups."_

---

**Which setup would you like?**

1. [Inferred: Coding Setup] — looks like a Python project (pyproject.toml detected)
2. Web Development — frontend, backend, or full-stack web app (Next.js / React / Vue / Svelte / Astro / Remix + API)
3. Data Science / ML — notebooks, experiment tracking, reproducible pipelines
4. Knowledge Base & Documentation — build a structured wiki from code or notes
5. Office & Business Productivity — emails, reports, presentations
6. Research & Academic Writing — literature, papers, LaTeX (reading and note-taking side)
7. Academic Writing — thesis / paper / dissertation: LaTeX or Typst, Zotero, strict no-invented-citations rules (manuscript side)
8. Content Creation — YouTube, social media, newsletters
9. DevOps / Cloud Engineering — CI/CD, Kubernetes, Terraform, cloud providers
10. UI/UX Design — component design, Figma handoff, accessibility
11. Knowledge Graph (Graphify) — install the `/graphify` command + PreToolUse hook for token-efficient search across code, docs, PDFs, and media
12. Already set up — audit my current Claude configuration (`/tipps`)
13. Not sure — help me decide

---

## Step 4: Handle "Not Sure"

If the user picks the "Not sure" option, ask these 9 yes/no questions one at a time:

1. "Are you primarily using Claude to work with code or a codebase?" → yes → recommend Coding Setup
2. "Are you building a web app — frontend, backend API, or full-stack (Next.js / React / Vue / Svelte / Astro / Remix)?" → yes → recommend Web Development Setup
3. "Do you mainly work with notebooks, datasets, or ML models?" → yes → recommend Data Science Setup
4. "Are you trying to organize documents, notes, or code into a structured knowledge base or wiki?" → yes → recommend Knowledge Base Builder
5. "Do you mostly work with documents, emails, reports, or presentations?" → yes → recommend Office Setup
6. "Are you writing a thesis, paper, or dissertation (LaTeX / Typst manuscript)?" → yes → recommend Academic Writing Setup
7. "Do you manage infrastructure, CI/CD pipelines, or cloud resources?" → yes → recommend DevOps Setup
8. "Do you primarily work with UI designs, components, or frontend interfaces?" → yes → recommend Design Setup
9. "Is your main pain that Claude burns too many tokens searching across a large codebase, docs folder, or mixed-media corpus?" → yes → recommend Graphify Setup (layers on top of any other setup)

If none match after 9 questions, present all 11 setup options (1–11, excluding "Already set up" and "Not sure") with one-line descriptions and ask the user to pick a number.

## Step 5: Dispatch

Once the user confirms a choice, pass the following handoff context inline and invoke the chosen skill:

```
HANDOFF_CONTEXT:
  detected_language: "[ISO 639-1 code, e.g. en, de, es]"
  existing_claude_md: [true/false]
  inferred_use_case: "[coding|web-development|data-science|knowledge-base|office|research|academic-writing|content-creator|devops|design|graphify|unknown]"
  repo_signals: ["[list of detected signals, e.g. pyproject.toml, *.py files, *.ipynb, next.config.ts, package.json:next]"]
  graphify_candidate: [true/false]
```

Skill routing:
- Coding Setup → invoke `coding-setup` skill
- Web Development Setup → invoke `web-development-setup` skill
- Data Science / ML → invoke `data-science-setup` skill
- Knowledge Base → invoke `knowledge-base-builder` skill
- Office → invoke `office-setup` skill
- Research → invoke `research-setup` skill
- Academic Writing → invoke `academic-writing-setup` skill
- Content Creator → invoke `content-creator-setup` skill
- DevOps Setup → invoke `devops-setup` skill
- UI/UX Design Setup → invoke `design-setup` skill
- Knowledge Graph (Graphify) → invoke `graphify-setup` skill (standalone — `host_setup_slug: "graphify"`, `host_skill_slug: "graphify-setup"`)
- Already set up (audit) → invoke `tipps` skill

Step back completely. The setup skill handles everything from here. For the five host setups that offer Graphify conditionally (coding-setup, knowledge-base-builder, research-setup, data-science-setup, web-development-setup), the Graphify question appears AFTER the host setup's main questions, not here — those skills delegate to `skills/_shared/graphify-install.md` themselves.

## Step 6: Rebuild backup notice (only if `rebuild_mode: true` and Step 1b ran)

After the delegated setup skill prints its own completion summary, print one additional block so the user knows where the pre-rebuild state lives:

```
Rebuild complete. Pre-rebuild backup saved to:
  <rebuild_backup_path>

To restore everything to the pre-rebuild state:
  cp -R <rebuild_backup_path>. ./
  (this restores files in-place, overwriting what the rebuild wrote)
```

If Step 1b did not run (normal onboarding without `--rebuild`), omit this block entirely.
