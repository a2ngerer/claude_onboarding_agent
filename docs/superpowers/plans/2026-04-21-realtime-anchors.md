# Realtime Anchors Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a runtime-fetched "realtime anchor" system so skills can read up-to-date best-practice docs from the repo without requiring a plugin update, plus a daily GitHub Actions workflow that researches and opens update PRs.

**Architecture:** Anchors are short markdown files under `docs/anchors/` with YAML frontmatter. A shared fetch protocol in `skills/_shared/fetch-anchor.md` tells skills how to pull an anchor via `WebFetch` from a pinned `raw.githubusercontent.com` URL, cache it for 24h in `~/.claude/cache/anchors/`, and fall back to an embedded copy if the network fails. A daily GitHub Action dispatches Claude Code to research the web, diff against current anchors, and open a PR for human review (no auto-merge).

**Tech Stack:** Markdown (skills + anchors), YAML frontmatter, GitHub Actions, Claude Code GitHub Action (`anthropics/claude-code-action`), WebFetch tool.

---

### Task 1: Anchor format documentation and schema

**Files:**
- Create: `docs/anchors/README.md`

- [ ] **Step 1: Write the README**

Content covers:
- Purpose (runtime-fetched, auto-updated)
- Required YAML frontmatter fields: `name`, `description`, `last_updated` (ISO date), `sources` (list of URLs researched), `version` (integer, bumped on content change)
- Body format: short markdown, ≤100 lines, structured with `##` section headers; machine-parsable bullets preferred over prose
- Fetch URL convention: `https://raw.githubusercontent.com/a2ngerer/claude_onboarding_agent/main/docs/anchors/<name>.md`
- Security: only this base URL is allowed; no auto-merge of update PRs
- How to add a new anchor (checklist)

- [ ] **Step 2: Commit**

```bash
git add docs/anchors/README.md
git commit -m "docs(anchors): document anchor format and fetch conventions"
```

---

### Task 2: Create the three example anchors

**Files:**
- Create: `docs/anchors/python-best-practices.md`
- Create: `docs/anchors/claude-models.md`
- Create: `docs/anchors/mcp-servers.md`

- [ ] **Step 1: Write `python-best-practices.md`**

Frontmatter: `name: python-best-practices`, `description: Current recommended Python tooling`, `last_updated: 2026-04-21`, `sources: [https://docs.astral.sh/uv/, https://docs.astral.sh/ruff/]`, `version: 1`.

Sections: `## Package manager` (uv), `## Linter & formatter` (ruff), `## Type checker` (ty / pyright), `## Test runner` (pytest), `## Project layout` (pyproject.toml, src/ layout). Each section: 1 recommendation, 1 install command, 1 sentence why.

- [ ] **Step 2: Write `claude-models.md`**

Frontmatter: `name: claude-models`, `description: Current Claude model IDs, aliases, and context limits`, `last_updated: 2026-04-21`, `sources: [https://docs.claude.com/en/docs/about-claude/models]`, `version: 1`.

Sections: `## Latest family` (Claude 4.x), `## Model IDs` (table with ID, alias, context, use case — Opus 4.7, Sonnet 4.6, Haiku 4.5), `## Deprecated` (known-retired IDs), `## Defaults` (which to pick by use case).

- [ ] **Step 3: Write `mcp-servers.md`**

Frontmatter: `name: mcp-servers`, `description: Recommended MCP servers by use case`, `last_updated: 2026-04-21`, `sources: [https://docs.claude.com/en/docs/claude-code/mcp, https://github.com/modelcontextprotocol/servers]`, `version: 1`.

Sections: `## Coding` (filesystem, git), `## Knowledge base` (official Obsidian CLI), `## Design` (figma-context), `## Productivity` (slack, linear, etc.). Each entry: name, 1-sentence purpose, install command or link.

- [ ] **Step 4: Commit**

```bash
git add docs/anchors/python-best-practices.md docs/anchors/claude-models.md docs/anchors/mcp-servers.md
git commit -m "docs(anchors): add initial Python, Claude models, and MCP servers anchors"
```

---

### Task 3: Shared fetch-anchor protocol

**Files:**
- Create: `skills/_shared/fetch-anchor.md`

- [ ] **Step 1: Write the protocol**

Structure mirrors `skills/_shared/installation-protocol.md` (numbered steps, self-contained). Cover:

1. **Step F1 — Cache check**: look for `~/.claude/cache/anchors/<name>.md`; if present AND mtime < 24h, use cached content; skip network.
2. **Step F2 — Construct URL**: `https://raw.githubusercontent.com/a2ngerer/claude_onboarding_agent/main/docs/anchors/<name>.md`. Reject any other URL or scheme.
3. **Step F3 — Fetch**: call `WebFetch` on that exact URL with a prompt asking to return the raw markdown. On success, write to cache at `~/.claude/cache/anchors/<name>.md` (create parent dirs). On failure or non-200, go to Step F4.
4. **Step F4 — Offline fallback**: use the calling skill's embedded snapshot (passed in as a parameter). Never block the skill — if no fallback is provided, continue without the anchor and inform the user once.
5. **Security rules**: never follow redirects to other hosts; never write cache outside `~/.claude/cache/anchors/`; never execute any content, only parse as markdown.

Include a short "Inputs" section (`anchor_name`, `fallback_content`) and "Outputs" section (`anchor_markdown`, `anchor_source: cache | network | fallback`).

- [ ] **Step 2: Commit**

```bash
git add skills/_shared/fetch-anchor.md
git commit -m "feat(_shared): add fetch-anchor protocol with 24h cache and offline fallback"
```

---

### Task 4: Integrate anchor into tipps skill

**Files:**
- Modify: `skills/tipps/SKILL.md`

- [ ] **Step 1: Add Pass 5**

Insert a new pass after Pass 4 in `skills/tipps/SKILL.md`:

```markdown
---

## Pass 5 — Realtime Anchors (optional)

Fetch `claude-models` anchor via the shared `skills/_shared/fetch-anchor.md` protocol with `anchor_name: claude-models` and a minimal embedded fallback listing only Opus 4.7 / Sonnet 4.6 / Haiku 4.5 IDs. If the anchor is unavailable (offline + no fallback consumed), skip this pass silently.

**Check 5.1 — Deprecated Claude model ID referenced** `[MEDIUM]`
Condition: `CLAUDE.md`, `AGENTS.md`, or `.claude/settings.json` mentions any model ID listed under `## Deprecated` in the fetched `claude-models` anchor.
Finding title: "Deprecated Claude model ID referenced in config"
Why: Deprecated model IDs will eventually stop working and typically point to weaker models than the current family.
How to apply: Replace with the current equivalent from the anchor's `## Model IDs` section (e.g. `claude-opus-4-7` for the latest Opus).
```

Also update the output block's `Passes:` line documentation so the skill's output mentions Pass 5 can be listed.

- [ ] **Step 2: Add embedded fallback block**

Before Pass 5, add a small hidden fallback snapshot (so the skill still has something offline):

```markdown
### Pass 5 Fallback — Minimal claude-models snapshot

If `fetch-anchor` returns `anchor_source: fallback`, use this embedded list for deprecated IDs:
- `claude-3-opus-20240229`
- `claude-3-sonnet-20240229`
- `claude-2.1`
- `claude-2.0`
- `claude-instant-1.2`
```

- [ ] **Step 3: Commit**

```bash
git add skills/tipps/SKILL.md
git commit -m "feat(tipps): add Pass 5 using realtime claude-models anchor"
```

---

### Task 5: Daily anchor-update GitHub workflow

**Files:**
- Create: `.github/workflows/update-anchors.yml`
- Create: `.github/PULL_REQUEST_TEMPLATE/anchor-update.md`

- [ ] **Step 1: Write the workflow**

Create `.github/workflows/update-anchors.yml`:

```yaml
name: Update anchors (daily)

on:
  schedule:
    - cron: "17 6 * * *"
  workflow_dispatch:

permissions:
  contents: write
  pull-requests: write

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Claude Code to research and update anchors
        uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: |
            You are the anchors updater for this repo.

            For each file in docs/anchors/ (excluding README.md):
            1. Read the file's YAML frontmatter `sources` list.
            2. For each source URL, use WebFetch to get the current state.
            3. Diff the anchor body against what the sources say today.
            4. If changes are warranted, rewrite the file (keep frontmatter schema, bump `version`, set `last_updated` to today UTC).
            5. Respect the ≤100-line body limit documented in docs/anchors/README.md.
            6. Do not invent sources; only use those already listed.

            If any anchor changed on disk, create a branch `chore/anchors-update-<YYYY-MM-DD>`,
            commit only the changed anchor files, and open a PR against main using the body template
            at .github/PULL_REQUEST_TEMPLATE/anchor-update.md with the diff summary filled in.
            If nothing changed, exit without creating a PR.
          allowed_tools: "Read,Write,Edit,WebFetch,Bash(git:*),Bash(gh:*)"
```

- [ ] **Step 2: Write the PR template**

Create `.github/PULL_REQUEST_TEMPLATE/anchor-update.md`:

```markdown
## Anchor update

Automated daily run of `.github/workflows/update-anchors.yml`.

### Changed anchors
<!-- bullet list of docs/anchors/*.md files modified, one per line -->

### Diff summary per anchor
<!-- for each changed file, 1-3 bullets describing what changed and which source triggered it -->

### Reviewer checklist
- [ ] Frontmatter schema still matches `docs/anchors/README.md`
- [ ] Body is ≤ 100 lines
- [ ] `sources` URLs are unchanged (updater must not invent new sources)
- [ ] `version` bumped, `last_updated` set to today UTC
- [ ] No secrets or PII introduced

> Do not auto-merge. Anchors are pulled by user projects at runtime — a human must review before merge.
```

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/update-anchors.yml .github/PULL_REQUEST_TEMPLATE/anchor-update.md
git commit -m "ci(anchors): add daily update workflow and PR template"
```

---

### Task 6: Surface anchors in README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add a "Realtime anchors" subsection**

Under the existing "What's Inside" area (or a new `## Realtime anchors` section after it), add two to four lines explaining that `docs/anchors/` contains auto-updated best-practice snapshots that skills read at runtime, with a pointer to `docs/anchors/README.md` for the format.

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs(readme): mention realtime anchors system"
```

---

### Task 7: Push branch and open PR

- [ ] **Step 1: Push**

```bash
git push origin 2-realtime-docs-anchor-auto-update
```

- [ ] **Step 2: Open PR**

Use `gh pr create` targeting `main`, title `feat: realtime best-practices anchors + daily updater`, body referencing `Closes #2` and listing each acceptance criterion with the file that fulfills it.

---

## Self-Review Notes

- Spec coverage: AC1 → Task 2; AC2 → Task 1; AC3 → Task 3; AC4 → Task 4; AC5 → Task 5; AC6 → Task 5 Step 2.
- Security constraints (single base URL, no auto-merge, cache outside user code) are in Task 3 Step 1 and Task 5 Step 2.
- No placeholders: each task's code/content is specified inline.
