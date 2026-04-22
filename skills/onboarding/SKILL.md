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
> Run `/checkup` to decide whether to rebuild or selectively improve this setup, or re-run `/onboarding --rebuild` to force a full rebuild (existing files will be backed up to `.claude/backups/<timestamp>-onboarding/` first)."

Exit here. Do not proceed to Step 2.

If nothing is detected, or `rebuild_mode: true`, continue.

## Step 1b: Backup before rebuild (only if `rebuild_mode: true`)

Before any scanning or file generation, back up every onboarding-agent-managed file that currently exists in the repo. Delegate the mechanics to the shared helper; do not reimplement timestamp or copy logic here.

1. Read `skills/_shared/backup-before-write.md` and follow it with `trigger: onboarding-rebuild`. Capture the returned `rebuild_backup_path`.
2. **Backup failure aborts onboarding.** If the helper signals failure (it prints the standardized warning itself), exit here. Do not proceed to Step 2.
3. Store `rebuild_backup_path` (as returned by the helper, e.g. `.claude/backups/<timestamp>-onboarding/`) for the completion summary in Step 6.

After a successful backup, continue with Step 2 normally. The existing files are **not** deleted — setup skills will overwrite / extend them as they normally would. The backup is the user's restore point.

## Step 2: Scan the Repository (via `repo-scanner` subagent)

Dispatch a `repo-scanner` subagent (defined in `.claude/agents/repo-scanner.md`) to gather repository signals without loading raw filesystem evidence into this context.

**Dispatch brief:**

```
Use the Agent tool with:
  subagent_type: repo-scanner
  description: "Scan the current project for use-case signals"
  prompt: |
    Scan the project rooted at the current working directory.
    Return your standard JSON envelope (kind: "repo-scan").
    Signals of interest (advisory — always return every contracted field):
      - coding
      - web-development
      - data-science
      - academic-writing
      - knowledge-base
      - office
      - research
      - content-creator
      - devops
      - design
      - graphify
Expected output: one fenced ```json block per the subagent's output contract (cap: 500 tokens).
```

Wait for the subagent to return. Parse the reply via `skills/_shared/parse-subagent-json.md` with `reply_kind: "repo-scan"` and `schema_path: ".claude/agents/schemas/repo-scan.schema.json"`. Branch on the helper's result:

- On success (`result.ok: true`), extract from `result.data`:
  - `inferred_use_case` → drives Step 3's option ordering
  - `signals` → short list surfaced in the "inferred" option's explanation
  - `graphify_candidate` → drives the Step 3 graphify aside
  - `existing_claude_md`, `existing_agents_md` → drive the Step 3 pre-notice
  - `repo_size_bucket` → kept for downstream skills if needed
- On failure (`result.ok: false`, any `reason`), treat as a malformed response and use the Fallback subsection below.

**If CLAUDE.md already exists** (`existing_claude_md: true`): before presenting options, inform the user: "I found an existing CLAUDE.md. The setup skill will extend it (adding a new section) rather than overwriting it."

If `inferred_use_case: unknown`, make no inference — Step 3 presents all options equally.

### Fallback (if the subagent fails)

Trigger the fallback when the shared parser returns a failure marker (`ok: false` with any `reason`) after one retry, or when the Agent tool itself errors. On dispatch error, do not retry — fall back immediately. Print (adapt to detected language):

> "⚠ repo-scanner subagent unavailable — falling back to inline detection. Detection is best-effort; rerun `/onboarding` once the subagent is restored for full coverage."

Then run this inline heuristic (single source of truth — no other copy exists in this SKILL):

- Count file extensions: `.py`, `.ts`, `.js`, `.go`, `.rs`, `.rb`, `.java`, `.cs` → coding signal
- Look for package manifests: `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `requirements.txt` → strong coding signal
- Look for web-framework config or entry points: `next.config.{js,mjs,ts}`, `vite.config.{js,mjs,ts}`, `astro.config.{mjs,ts}`, `remix.config.{js,ts}`, `svelte.config.{js,ts}`, `nuxt.config.{js,ts}`, `app/page.{tsx,jsx}`, `pages/` directory with `_app` or `index`, `src/routes/` (SvelteKit/Remix), `index.html` next to `public/`, or framework deps in `package.json` (`next`, `react-dom`, `vue`, `svelte`, `@sveltejs/kit`, `astro`, `@remix-run/*`, `solid-js`, `@nuxt/kit`) → **web-development signal** (dominates a generic coding signal when present — indicates a web app, not a library or CLI)
- Look for `.ipynb` files, a `notebooks/` folder, `data/raw/`, or deps on `pandas`/`polars`/`numpy`/`scikit-learn`/`torch`/`jax` in `pyproject.toml` → data-science signal (dominates a generic Python coding signal when present)
- Look for `.tex`, `.bib` files → research signal
- Look for a `sections/` folder, a `bib/` folder, `main.tex`/`main.typ`, or a `.typ` file alongside `.bib` → **academic-writing signal** (dominates a generic research signal when present — indicates the repo holds the manuscript, not just literature)
- Look for `*.docx`, `*.pptx`, `*.pdf`, `*.xlsx` files → office signal
- Look for a `notes/`, `vault/`, `wiki/`, `obsidian/` directory → knowledge base signal
- Count total source files and `*.md` / `*.pdf` / `*.ipynb` files. If the repo has a very large code corpus (e.g. > 1000 source files across 25+ tree-sitter languages) OR > 100 PDFs/Markdown notes under `docs/` / `raw/` / `notes/`, set `graphify_candidate: true` — hint that a knowledge-graph index (via `graphify-setup`) could significantly reduce Claude's token cost on file-search calls. It is ONLY a hint; the primary use-case decision is unchanged.
- Check if `CLAUDE.md` already exists → set `existing_claude_md: true`
- Check if `AGENTS.md` already exists → set `existing_agents_md: true`

Produce the same logical shape the subagent would return (`inferred_use_case`, `signals`, `graphify_candidate`, `existing_claude_md`, `existing_agents_md`, `repo_size_bucket`) and continue with Step 3. Infer the most likely use case based on the strongest signal; if none is strong enough, set `inferred_use_case: unknown`.

## Step 3: Present Options

Present all options grouped into the four categories below. Numbering runs 1–13 continuously across categories — users still select by number. If an inference was made, mark that option with a leading `→` arrow and an `[inferred]` tag, and keep it at its natural position inside its own category (do NOT move it to the top of the list). If no inference was made, omit the arrow and tag — present all options equally.

Fixed numbering (stable across runs):

| # | Slug | Category |
|---|---|---|
| 1 | coding-setup | Code |
| 2 | web-development-setup | Code |
| 3 | data-science-setup | Code |
| 4 | design-setup | Code |
| 5 | academic-writing-setup | Writing & Research |
| 6 | research-setup | Writing & Research |
| 7 | knowledge-base-setup | Writing & Research |
| 8 | content-creator-setup | Writing & Research |
| 9 | office-setup | Operations |
| 10 | devops-setup | Operations |
| 11 | graphify-setup | Other |
| 12 | audit-setup (Already set up) | Other |
| 13 | Not sure | Other |

If `graphify_candidate: true` from Step 2, print exactly ONE line directly under the category that holds the inferred option (or under the Code category when `inferred_use_case: unknown`): _"Your repo is large — `/graphify-setup` can layer on top of any choice in this list."_ Do not print a separate aside elsewhere. This is the only Graphify cue in this step beyond option 11 itself.

Example format (adapt wording to detected language; the `→ [inferred]` marker below assumes coding was inferred — apply it to whichever option matches `inferred_use_case`):

---

**Which setup would you like?**

**Code**
→ **1. [inferred] Coding Setup** — looks like a Python project (pyproject.toml detected)
2. Web Development — frontend, backend, or full-stack web app (Next.js / React / Vue / Svelte / Astro / Remix + API)
3. Data Science / ML — notebooks, experiment tracking, reproducible pipelines
4. UI/UX Design — component design, Figma handoff, accessibility

_Your repo is large — `/graphify-setup` can layer on top of any choice in this list._

**Writing & Research**
5. Academic Writing — thesis / paper / dissertation: LaTeX or Typst, Zotero, strict no-invented-citations rules (manuscript side)
6. Research & Academic Writing — literature, papers, LaTeX (reading and note-taking side)
7. Knowledge Base & Documentation — build a structured wiki from code or notes
8. Content Creation — YouTube, social media, newsletters

**Operations**
9. Office & Business Productivity — emails, reports, presentations
10. DevOps / Cloud Engineering — CI/CD, Kubernetes, Terraform, cloud providers

**Other**
11. Knowledge Graph (Graphify) — install the `/graphify` command + PreToolUse hook for token-efficient search across code, docs, PDFs, and media
12. Already set up — check my current Claude configuration (`/checkup`)
13. Not sure — help me decide

---

## Step 4: Handle "Not Sure"

If the user picks the "Not sure" option, walk them through a short decision tree instead of a flat questionnaire. **Never ask more than 3 questions in this step.** If the user is unmatched after 3 questions, fall through to the full 11-option list (same fallback behaviour as today).

Ask Q1 first. Based on the answer, ask Q2 from the matching branch. Only ask Q3 if that branch explicitly marks it as needed; otherwise commit to the recommendation after Q2. Present each question on its own (one at a time), with the lettered options visible.

### Q1 — Primary axis

> "What kind of work will you primarily do with Claude here?
>   A) Write code or build software
>   B) Write text, do research, or manage notes
>   C) Build or operate infrastructure / data pipelines
>   D) Something else, or a mix of the above"

### Q2 — Branch refinement

**If A (code / software):**

> "What flavor of code work?
>   a) Frontend-heavy or full-stack web app (React / Next.js / Vue / Svelte / Astro / Remix) → recommend `web-development-setup`
>   b) Notebooks, datasets, or ML models → recommend `data-science-setup`
>   c) UI / component design, Figma handoff, accessibility work → recommend `design-setup`
>   d) General coding — backend, CLI, library, or anything else → recommend `coding-setup`"

Commit to the recommendation after Q2. No Q3 needed on this branch.

**If B (text / research / notes):**

> "What's the primary output?
>   a) A thesis, paper, or dissertation manuscript (LaTeX / Typst, with `.bib`) → recommend `academic-writing-setup`
>   b) Reading papers, literature notes, or a personal knowledge vault
>   c) Business documents — emails, reports, slides, spreadsheets → recommend `office-setup`
>   d) Published content for an audience — YouTube, social, newsletters → recommend `content-creator-setup`"

If the user picks B-b, ask Q3 to disambiguate between the two text-centric vault skills:

> "Q3 — Are you mainly organising your own personal notes/vault, or managing the research flow around a paper (literature, citations, reading queue)?
>   vault → recommend `knowledge-base-setup`
>   paper research → recommend `research-setup`"

For every other B-option, commit after Q2.

**If C (infrastructure / pipelines):**

> "What layer?
>   a) Cloud, IaC, Kubernetes, CI/CD → recommend `devops-setup`
>   b) Data pipelines, notebooks, experiments → recommend `data-science-setup`"

Commit after Q2.

**If D (something else / mixed):** fall through to the full 11-option fallback below. Do not ask further questions.

### Fallback

If the user picks D on Q1, or is still unmatched after Q3, or declines any of the branch options, present all 11 setup options (1–11, excluding "Already set up" and "Not sure") with one-line descriptions and ask the user to pick a number. This matches today's fallback.

### Coverage check

The tree covers all 11 setup options:

- `coding-setup` — A/d
- `web-development-setup` — A/a
- `data-science-setup` — A/b and C/b
- `design-setup` — A/c
- `academic-writing-setup` — B/a
- `knowledge-base-setup` — B/b → Q3 vault
- `research-setup` — B/b → Q3 paper
- `office-setup` — B/c
- `content-creator-setup` — B/d
- `devops-setup` — C/a
- `graphify-setup` — not on the decision tree; it is a layered add-on. Surfaced via the Step 3 `graphify_candidate` aside and offered by host setups through `skills/_shared/graphify-install.md`. Users who explicitly want it pick option 11 directly, or reach it from the fallback list.

### Max-depth contract

No path through this step exceeds 3 questions. Paths by depth:
- 1 question: none (Q1 alone never commits — it only selects a branch).
- 2 questions: A/a, A/b, A/c, A/d, B/a, B/c, B/d, C/a, C/b.
- 3 questions: B/b → vault, B/b → paper research.
- D collapses immediately to the 11-option fallback with no further questions.

## Step 5: Dispatch

Once the user confirms a choice, pass the following handoff context inline and invoke the chosen skill. The payload conforms to `docs/schemas/handoff-context.schema.json` (Draft 2020-12); setup skills consume it via `skills/_shared/consume-handoff.md`.

```json
{
  "detected_language": "<ISO 639-1 code, e.g. en, de, es>",
  "existing_claude_md": false,
  "inferred_use_case": "<coding|web-development|data-science|knowledge-base|office|research|academic-writing|content-creator|devops|design|graphify|unknown>",
  "repo_signals": {
    "signals": ["<short evidence strings, e.g. pyproject.toml, *.ipynb, package.json:next>"],
    "existing_agents_md": false,
    "repo_size_bucket": "<tiny|small|medium|large>"
  },
  "graphify_candidate": false,
  "source": "orchestrator"
}
```

Skill routing:
- Coding Setup → invoke `coding-setup` skill
- Web Development Setup → invoke `web-development-setup` skill
- Data Science / ML → invoke `data-science-setup` skill
- Knowledge Base → invoke `knowledge-base-setup` skill
- Office → invoke `office-setup` skill
- Research → invoke `research-setup` skill
- Academic Writing → invoke `academic-writing-setup` skill
- Content Creator → invoke `content-creator-setup` skill
- DevOps Setup → invoke `devops-setup` skill
- UI/UX Design Setup → invoke `design-setup` skill
- Knowledge Graph (Graphify) → invoke `graphify-setup` skill (standalone — `host_setup_slug: "graphify"`, `host_skill_slug: "graphify-setup"`)
- Already set up (checkup) → invoke `checkup` skill

Step back completely. The setup skill handles everything from here. For the five host setups that offer Graphify conditionally (coding-setup, knowledge-base-setup, research-setup, data-science-setup, web-development-setup), the Graphify question appears AFTER the host setup's main questions, not here — those skills delegate to `skills/_shared/graphify-install.md` themselves.

## Step 5a: Verify artifacts (via `artifact-verifier` subagent)

After the delegated setup skill reports completion, dispatch an `artifact-verifier` subagent (defined in `.claude/agents/artifact-verifier.md`) to confirm the files it claimed to write exist and are structurally valid.

Capture the list of files the setup skill announced in its completion summary (e.g. `CLAUDE.md`, `AGENTS.md`, `.claude/settings.json`, `.gitignore`, any `claude_instructions/*.md`). If the setup skill did not print an explicit file list, use the default candidate set for the chosen setup type.

**Dispatch brief:**

```
Use the Agent tool with:
  subagent_type: artifact-verifier
  description: "Verify the files the setup skill just wrote"
  prompt: |
    Verify the following files exist on disk and are structurally valid.
    Return your standard JSON envelope (kind: "artifact-verify").
    files_to_check:
      - <path 1>
      - <path 2>
      - ...
Expected output: one fenced ```json block per the subagent's output contract (cap: 200 tokens).
```

Parse the reply via `skills/_shared/parse-subagent-json.md` with `reply_kind: "artifact-verify"` and `schema_path: ".claude/agents/schemas/artifact-verify.schema.json"`. On success (`result.ok: true`):

- If `result.data.status == "ok"`, print one line: `✓ Artifacts verified (<result.data.files_checked> files checked).`
- If `result.data.status == "issues"`, print the `result.data.issues` list verbatim and suggest `/checkup` to decide next steps.

Do NOT retry the setup skill automatically — the issues may be intentional (e.g. the user skipped a file during the setup skill's own prompts).

### Fallback (if the subagent fails)

Trigger the fallback when the shared parser returns a failure marker (`ok: false` with any `reason`) after one retry, or when the Agent tool itself errors. On dispatch error, do not retry — fall back immediately. Print (adapt to detected language):

> "⚠ artifact-verifier unavailable — please spot-check the generated files manually."

Continue with Step 6.

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

## Step 7: Silent post-setup audit (via `audit-collector` subagent)

After all other steps complete, run a best-effort post-setup audit **silently** in the background. Do NOT ask the user whether to run it — no opt-in prompt, no preamble, no "running audit…" status line. The audit is a no-cost safety net: if everything is clean, the user sees nothing; if something critical is wrong, the user gets a short, actionable list.

Dispatch an `audit-collector` subagent (defined in `.claude/agents/audit-collector.md`).

**Dispatch brief:**

```
Use the Agent tool with:
  subagent_type: audit-collector
  description: "Run /audit-setup and summarize findings"
  prompt: |
    Invoke the audit skill named below and return your standard
    JSON envelope (kind: "audit-summary") with severity-bucketed counts.
    audit_skill: audit-setup
    max_top_titles: 5
Expected output: one fenced ```json block per the subagent's output contract (cap: 300 tokens).
```

### Parsing

Parse the reply via `skills/_shared/parse-subagent-json.md` with `reply_kind: "audit-summary"` and `schema_path: ".claude/agents/schemas/audit-summary.schema.json"`. On success (`result.ok: true`), read `result.data.total`, `result.data.high`, `result.data.medium`, `result.data.low`, `result.data.top_titles`.

Treat the audit as failed — see "Parse failure" below — when any of these hold:
- the shared parser returns a failure marker (`ok: false` with any `reason`) after one retry,
- the subagent's envelope arrives with `ok: false` (the documented in-band error signal), or
- the Agent tool itself errors. On dispatch error, do not retry — fall back immediately.

### Surfacing findings

- **If `high == 0`:** say nothing. The setup skill's completion summary already printed above is the end of the flow. Do not announce that the audit ran, do not list MEDIUM / LOW / INFO findings, do not print totals. Proceed to Step 8.
- **If `high >= 1`:** append a short, actionable block below the completion summary. Use this shape (adapt wording to detected language; keep the command tokens verbatim):

  ```
  Post-setup audit — action items

  - <HIGH finding title> → run `<single most appropriate command>`
  - <HIGH finding title> → run `<single most appropriate command>`
  ```

  One line per HIGH finding, no severity badges, no "Why" / "How to apply" detail. MEDIUM / LOW / INFO findings are never listed here — the user can run `/checkup` manually for the full report.

### Mapping a HIGH finding to exactly one command

Pick the single most appropriate command per finding (never stack two). `/checkup` is the default user-facing entrypoint; it internally routes to `/audit-setup` and `/upgrade-setup` when that is the right next step.

- Finding mentions secrets, tokens, or personal data in `CLAUDE.md` → `/checkup` (the fix requires a guided rewrite of the file; `/checkup` will hand off to `/upgrade-setup`).
- Finding mentions overly broad permissions (`"*"`, `"Bash(*)"`) in `.claude/settings.json` → `/checkup`.
- Finding mentions a stale, deprecated, or out-of-date anchor / best-practice section → `/anchors`.
- Finding mentions structural drift (missing delimiter, orphaned section, stale onboarding-agent marker, artifact mismatch) → `/checkup`.
- Any other HIGH finding → `/checkup` as the default remediation path.

At most one command per finding. If no mapping is obvious, default to `/checkup`.

### Parse failure

If the audit-collector dispatch errors, returns no parseable JSON envelope, or returns an envelope with `ok: false`, fail **silently**: print nothing, do not retry, do not warn the user. The post-setup audit is best-effort; a missing result must not dilute the setup completion summary. Proceed to Step 8.

## Step 8: Final hint about /anchors

After the audit step (or after the setup completion summary if Step 7 was skipped), print one additional line (adapt to detected language):

- Run `/anchors` any time after setup to refresh the anchor-derived best-practice sections. Setup already rendered an initial version; `/anchors` refreshes them against the latest upstream anchors.

End.
