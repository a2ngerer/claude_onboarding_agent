# Anchor Redesign and Daily Updater Rebuild — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `python-best-practices` with three new workspace-focused anchors (`claude-tools`, `subagents`, `knowledge-base`), reshape `mcp-servers` to expose a top-level `## Recommended` list, and rewire the daily updater to a two-layer source model (canonical per-anchor sources + global trend sources).

**Architecture:** Each anchor remains a single markdown file in `docs/anchors/` with YAML frontmatter and a body ≤ 100 lines. The daily GitHub Actions workflow now runs two passes per anchor: a canonical-pass (verify facts against `sources:` URLs) and a trend-pass (scan global trend URLs from `_trend-sources.md` whose `covers:` list includes this anchor). PR template gains per-change provenance.

**Tech Stack:** Markdown, YAML frontmatter, GitHub Actions, `anthropics/claude-code-action`, `WebFetch`.

**Spec:** `docs/superpowers/specs/2026-04-21-anchor-redesign-design.md` — read sections 1 (Anchor set), 2 (Two-layer sources), 3 (Daily updater), 6 (PR template) before starting.

**Depends on:** `feat/anchor-trend-sources` branch merged (produces `docs/anchors/_trend-sources.md`).

---

### Task 1: Delete `python-best-practices.md`

**Files:**
- Delete: `docs/anchors/python-best-practices.md`

- [ ] **Step 1: Confirm no consumer references remain**

```bash
grep -rn "python-best-practices" --include='*.md' --include='*.yml' --include='*.json' .
```

Expected: zero results. If any result appears outside of commit messages in `.git/`, stop and investigate before deleting — a skill or workflow may still depend on this anchor.

- [ ] **Step 2: Delete the file**

```bash
git rm docs/anchors/python-best-practices.md
```

- [ ] **Step 3: Commit**

```bash
git commit -m "chore(anchors): remove python-best-practices (out of scope for workspace-setup anchors)"
```

---

### Task 2: Create `claude-tools.md`

**Files:**
- Create: `docs/anchors/claude-tools.md`

- [ ] **Step 1: Research canonical content**

`WebFetch` each URL in the `sources:` list below. Extract current facts about: hooks (event names, shape, config location), `CLAUDE.md` conventions (size guidance, delimiter patterns), `AGENTS.md` conventions, `.claude/settings.json` keys, slash-command structure, plugin manifest structure.

Sources:
- `https://docs.claude.com/en/docs/claude-code/hooks`
- `https://docs.claude.com/en/docs/claude-code/settings`
- `https://docs.claude.com/en/docs/claude-code/plugins`
- `https://docs.claude.com/en/docs/claude-code/slash-commands`
- `https://docs.claude.com/en/docs/claude-code/memory`

- [ ] **Step 2: Write the file**

Use this exact skeleton. Fill each section with 3–8 concise bullets or a short table. Body (everything after the second `---`) must be ≤ 100 lines.

```markdown
---
name: claude-tools
description: How to configure Claude's core tooling surface — hooks, rules, memory files, settings, slash commands, plugins
last_updated: 2026-04-21
sources:
  - https://docs.claude.com/en/docs/claude-code/hooks
  - https://docs.claude.com/en/docs/claude-code/settings
  - https://docs.claude.com/en/docs/claude-code/plugins
  - https://docs.claude.com/en/docs/claude-code/slash-commands
  - https://docs.claude.com/en/docs/claude-code/memory
version: 1
---

## Memory files

Bullets on `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` — what each is for, scoping rules (global vs. project), size guidance (point-don't-dump).

## Settings

Bullets on `.claude/settings.json` structure: `permissions.allow`, `env`, `hooks`, `mcpServers`. Include a 2-line JSON example of a minimal permissions block.

## Hooks

Table with three columns: event name, typical use, one-line example. Cover at minimum: `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `SessionStart`, `SessionEnd`, `Stop`.

## Slash commands

Bullets on where slash commands live (`.claude/commands/` project-scoped vs. plugin-provided), how arguments are passed, naming conventions.

## Plugins

Bullets on `.claude-plugin/plugin.json` manifest fields, how to register skills and commands, versioning guidance.

## Recommendations

A bulleted list of currently recommended patterns. This section is the primary input for the `/tipps` anchor check — each bullet is phrased as "do X" or "prefer Y over Z".

## Deprecated patterns

A bulleted list of patterns that used to be recommended but are now discouraged (e.g. "do not stuff templates into `CLAUDE.md` — reference separate files instead"). This section is the key input for the `/tipps` check on this anchor.
```

- [ ] **Step 3: Verify body length**

```bash
awk '/^---$/{c++; next} c==2' docs/anchors/claude-tools.md | wc -l
```

Expected: ≤ 100.

If over 100, trim the longer sections (keep the section headings, reduce bullet counts).

- [ ] **Step 4: Commit**

```bash
git add docs/anchors/claude-tools.md
git commit -m "feat(anchors): add claude-tools anchor (hooks, settings, slash commands, plugins)"
```

---

### Task 3: Create `subagents.md`

**Files:**
- Create: `docs/anchors/subagents.md`

- [ ] **Step 1: Research canonical content**

`WebFetch` each source below. Extract current facts about: when to delegate to a subagent vs. call a tool directly, context isolation, how parallelism works, Task tool mechanics, known anti-patterns.

Sources:
- `https://docs.claude.com/en/docs/claude-code/sub-agents`
- `https://www.anthropic.com/engineering/multi-agent-research-system`
- `https://www.anthropic.com/engineering/claude-code-best-practices`

- [ ] **Step 2: Write the file**

```markdown
---
name: subagents
description: Subagent orchestration patterns for Claude Code — when to delegate, how to structure, and what to avoid
last_updated: 2026-04-21
sources:
  - https://docs.claude.com/en/docs/claude-code/sub-agents
  - https://www.anthropic.com/engineering/multi-agent-research-system
  - https://www.anthropic.com/engineering/claude-code-best-practices
version: 1
---

## When to use a subagent

Bulleted list of concrete triggers (e.g. "≥ 3 independent queries", "broad codebase exploration", "task needs a protected context window").

## Delegation heuristics

Bullets on: when to prefer the `Agent` tool over direct tool calls, when to spawn in parallel vs. serial, handing off research vs. implementation.

## Prompting a subagent

Short checklist on what a subagent prompt must contain: goal, what's already known, expected output format, length cap.

## Parallel dispatch

A 2–3 line example showing the pattern of sending multiple `Agent` calls in one message for independent work.

## Recommendations

Currently recommended patterns. One bullet per pattern, phrased positively.

## Anti-patterns

A bulleted list of patterns that cause trouble — e.g. "subagent calls another subagent without bounds", "main agent narrates subagent work instead of just relaying results", "dispatching agents for work that could be one tool call". This section is the key input for the `/tipps` check on this anchor.
```

- [ ] **Step 3: Verify body length**

```bash
awk '/^---$/{c++; next} c==2' docs/anchors/subagents.md | wc -l
```

Expected: ≤ 100.

- [ ] **Step 4: Commit**

```bash
git add docs/anchors/subagents.md
git commit -m "feat(anchors): add subagents anchor (orchestration patterns and anti-patterns)"
```

---

### Task 4: Create `knowledge-base.md`

**Files:**
- Create: `docs/anchors/knowledge-base.md`

- [ ] **Step 1: Research canonical content**

`WebFetch` each source below. Extract current facts about: Obsidian vault layouts, frontmatter conventions, note-naming patterns, how KB agents (vault keepers, note organizers) are typically structured.

Sources:
- `https://help.obsidian.md/`
- `https://help.obsidian.md/properties` (frontmatter docs)
- `https://publish.obsidian.md/hub/01+-+Community+Vaults` (if reachable)

Also read the in-repo file `skills/knowledge-base-builder/SKILL.md` and reference its conventions — the anchor's recommendations should align with what the KB setup skill already emits.

- [ ] **Step 2: Write the file**

```markdown
---
name: knowledge-base
description: Recommended vault layouts, frontmatter patterns, and KB-agent structures for Obsidian-style knowledge bases
last_updated: 2026-04-21
sources:
  - https://help.obsidian.md/
  - https://help.obsidian.md/properties
  - https://publish.obsidian.md/hub/01+-+Community+Vaults
version: 1
---

## Vault layout

Short prose (2–3 lines) summarizing the recommended folder hierarchy, then a small tree diagram in a code block showing the top-level folders (e.g. `00_inbox/`, `10_areas/`, `20_resources/`, `30_archive/`).

## Frontmatter conventions

A 4-column markdown table: property, type, required, purpose. Cover at minimum: `title`, `created`, `updated`, `tags`, `aliases`, `type`.

## Naming conventions

Bullets on: title format, date prefixes if any, kebab vs. snake case, avoiding reserved characters.

## Agent patterns

Bullets on KB-specific agents: vault keeper, frontmatter validator, tag normalizer — what each does, when to invoke.

## Recommended layout

The single, currently-recommended layout, named explicitly (e.g. "PARA-inspired with numeric prefixes"). This section is the key input for the `/tipps` check on this anchor — the check compares the user's detected vault layout against this recommendation.

## Anti-patterns

A bulleted list of layouts or conventions that cause trouble — e.g. deeply nested folders, mixing daily-notes with topical notes in one folder.
```

- [ ] **Step 3: Verify body length**

```bash
awk '/^---$/{c++; next} c==2' docs/anchors/knowledge-base.md | wc -l
```

Expected: ≤ 100.

- [ ] **Step 4: Commit**

```bash
git add docs/anchors/knowledge-base.md
git commit -m "feat(anchors): add knowledge-base anchor (vault layouts and KB-agent patterns)"
```

---

### Task 5: Reshape `mcp-servers.md` to expose a `## Recommended` list

**Files:**
- Modify: `docs/anchors/mcp-servers.md`

- [ ] **Step 1: Add a consolidated `## Recommended` section**

The `/tipps` check for this anchor looks for a top-level `## Recommended` list. Today the file uses per-category sections (`## Coding`, `## Knowledge base`, etc.) but no consolidated list. Prepend a new `## Recommended` section at the top of the body (immediately after the frontmatter), containing one bullet per currently-recommended MCP server:

```markdown
## Recommended

- `filesystem` — scoped filesystem access
- `git` — git history and diffs
- `github` — issues and PRs
- `obsidian` (official CLI + subagent)
- `slack`, `linear`, `gmail`, `calendar` — productivity integrations where an official MCP exists

(Adjust the list to match the per-category details below so the two stay consistent.)
```

Keep all existing per-category sections. The `## Recommended` list is a flat, consolidated view; the per-category sections remain the detailed reference.

- [ ] **Step 2: Bump `version` and `last_updated` in the frontmatter**

Increment `version` by 1. Set `last_updated` to today (UTC) — obtain with `date -u +%Y-%m-%d`.

- [ ] **Step 3: Verify body length**

```bash
awk '/^---$/{c++; next} c==2' docs/anchors/mcp-servers.md | wc -l
```

Expected: ≤ 100. If the new `## Recommended` section pushes the file over, tighten the per-category sections.

- [ ] **Step 4: Commit**

```bash
git add docs/anchors/mcp-servers.md
git commit -m "feat(anchors): add consolidated ## Recommended list to mcp-servers for /tipps integration"
```

---

### Task 6: Rewrite `.github/workflows/update-anchors.yml`

**Files:**
- Modify: `.github/workflows/update-anchors.yml`

- [ ] **Step 1: Replace the prompt with the two-pass version**

Write the file with this exact content. Keep `on:`, `permissions:`, and job header as they are today; only the `prompt:` block changes.

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
          github_token: ${{ secrets.GITHUB_TOKEN }}
          prompt: |
            You are the anchors updater for this repo.

            Step 1 — Load trend sources.
            Read `docs/anchors/_trend-sources.md`. Parse its YAML frontmatter and
            extract `sources[].url` and `sources[].covers`. If the file is missing
            or its frontmatter is malformed, print an error and exit non-zero. Do
            not fall back to canonical-only mode — the trend layer is required.

            Step 2 — For each file in `docs/anchors/` (excluding `README.md` and
            `_trend-sources.md`):

              2a Canonical pass:
                - Read the file's YAML frontmatter `sources` list.
                - For each source URL, use `WebFetch` to get the current state of
                  that page.
                - Diff the anchor body against what those sources say today.
                - If factual updates are warranted, rewrite the file (body ≤ 100
                  lines). Record this change as `pass: canonical`, along with the
                  source URL that triggered it and a one-sentence rationale.

              2b Trend pass:
                - From the trend sources loaded in Step 1, select those whose
                  `covers:` list includes this anchor's slug (the filename without
                  `.md`).
                - For each selected trend source, `WebFetch` it and scan for
                  newly-mentioned tools, patterns, or workflows that fit this
                  anchor's topic.
                - If a newly-mentioned item warrants a body update (e.g. a new
                  recommended MCP, a new subagent pattern), rewrite the file (body
                  ≤ 100 lines). Record each such change as `pass: trend`, along
                  with the trend source URL and a one-sentence rationale.

            Step 3 — Per-rewrite invariants (enforce for every change):
              - Frontmatter schema unchanged (`name`, `description`, `last_updated`,
                `sources`, `version`).
              - Bump `version` by one on any content change.
              - Set `last_updated` to today's UTC date (YYYY-MM-DD).
              - Do NOT add URLs to `sources` that were not already there.
              - Do NOT modify any file outside `docs/anchors/`.

            Step 4 — After editing, check `git status`:
              - If any `docs/anchors/*.md` file changed: create a branch
                `chore/anchors-update-$(date -u +%Y-%m-%d)`, commit only the changed
                anchor files, push, and open a PR against `main` using the body
                template at `.github/PULL_REQUEST_TEMPLATE/anchor-update.md`. Fill
                in the "Per-change provenance" section with one block per changed
                file listing pass type (canonical/trend), source URL, and
                rationale.
              - If nothing changed: exit without creating a PR.

            Never auto-merge. Never modify anything outside `docs/anchors/`. Never
            modify `_trend-sources.md` — trend-source changes are a separate human
            PR.
          allowed_tools: "Read,Write,Edit,WebFetch,Bash(git:*),Bash(gh:*),Bash(date:*)"
```

- [ ] **Step 2: YAML syntax check**

```bash
uv run --with pyyaml python -c "import yaml; yaml.safe_load(open('.github/workflows/update-anchors.yml'))"
```

Expected: exits with status 0, no output. If it prints a YAML parse error, fix the indentation or quoting.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/update-anchors.yml
git commit -m "feat(workflow): two-pass anchor updater (canonical + trend) with per-change provenance"
```

---

### Task 7: Rewrite `.github/PULL_REQUEST_TEMPLATE/anchor-update.md`

**Files:**
- Modify: `.github/PULL_REQUEST_TEMPLATE/anchor-update.md`

- [ ] **Step 1: Replace with the new template**

Write the file with this exact content:

```markdown
## Anchor update

Automated run of `.github/workflows/update-anchors.yml`.

### Changed anchors
<!-- bullet list of docs/anchors/*.md files modified, one per line -->

### Per-change provenance
<!-- For each changed file, one block:
- <anchor>.md
  - pass: canonical | trend
  - source: <url>
  - rationale: <one sentence explaining the change>
-->

### Reviewer checklist
- [ ] Frontmatter schema still matches `docs/anchors/README.md` (name, description, last_updated, sources, version)
- [ ] Body is ≤ 100 lines
- [ ] `sources` URLs are unchanged — the updater must not invent new sources
- [ ] `version` bumped, `last_updated` set to today UTC
- [ ] Each change lists pass type (canonical/trend), source URL, and rationale
- [ ] No secrets or PII introduced
- [ ] No files outside `docs/anchors/` changed
- [ ] `_trend-sources.md` not modified by this run

> Do not auto-merge. Anchors are pulled by user projects at runtime — a human must review before merge.
```

- [ ] **Step 2: Commit**

```bash
git add .github/PULL_REQUEST_TEMPLATE/anchor-update.md
git commit -m "feat(workflow): PR template requires per-change provenance (pass + source + rationale)"
```

---

### Task 8: Update `docs/anchors/README.md`

**Files:**
- Modify: `docs/anchors/README.md`

- [ ] **Step 1: Add the two-layer source architecture section**

Insert a new `## Source architecture` section directly after the existing `## Required frontmatter` section. Content:

```markdown
## Source architecture

Two layers of input feed the daily updater:

- **Canonical sources** (per anchor, in the frontmatter `sources:` list). These are authoritative documentation URLs that define factual truth for the anchor (e.g. Anthropic docs for `claude-models`, the MCP registry for `mcp-servers`). The updater never adds URLs to this list — a source change is a separate human PR.
- **Trend sources** (global, in `docs/anchors/_trend-sources.md`). Exactly three URLs that act as a trend radar, picking up new patterns (community releases, new workflows) before they land in official docs. Each trend source declares a `covers:` list of anchor slugs it informs. `_trend-sources.md` is **not itself an anchor** — consumers never fetch it.

Per daily run, the updater makes two passes per anchor:

1. Canonical pass — verify facts against the anchor's `sources:` URLs.
2. Trend pass — scan trend sources whose `covers:` list includes this anchor, and propose body updates for newly-surfaced items that fit the anchor's topic.

Every rewrite records `pass`, `source`, and `rationale` in the PR body for reviewer trail.
```

- [ ] **Step 2: Add `_trend-sources.md` to the "Adding a new anchor" section**

In the existing `## Adding a new anchor` section (or equivalent), add a note: "Do not place `_trend-sources.md` under the consumer fetch path — it is a workflow-only file, not an anchor. To change trend sources, open a separate human PR modifying only that file."

- [ ] **Step 3: Commit**

```bash
git add docs/anchors/README.md
git commit -m "docs(anchors): document two-layer source architecture and _trend-sources.md role"
```

---

### Task 9: Validate the updated workflow end-to-end

**Files:**
- None written. Validation only.

- [ ] **Step 1: Confirm the five anchors are present and `python-best-practices.md` is gone**

```bash
ls docs/anchors/
```

Expected — exactly these lines (order may differ):

```
README.md
_trend-sources.md
claude-models.md
claude-tools.md
knowledge-base.md
mcp-servers.md
subagents.md
```

If `python-best-practices.md` appears, Task 1 did not run. If any of the five anchors is missing, re-check Tasks 2–5.

- [ ] **Step 2: Schema-validate every anchor**

```bash
uv run --with pyyaml python - <<'PY'
import pathlib, re, sys, yaml
anchors_dir = pathlib.Path("docs/anchors")
errors = []
for p in sorted(anchors_dir.glob("*.md")):
    if p.name in ("README.md", "_trend-sources.md"):
        continue
    text = p.read_text()
    m = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    if not m:
        errors.append(f"{p.name}: no frontmatter"); continue
    fm = yaml.safe_load(m.group(1))
    for key in ("name", "description", "last_updated", "sources", "version"):
        if key not in fm:
            errors.append(f"{p.name}: missing frontmatter key {key!r}")
    if fm.get("name") != p.stem:
        errors.append(f"{p.name}: name={fm.get('name')!r} does not match stem")
    body = text[m.end():].splitlines()
    if len(body) > 100:
        errors.append(f"{p.name}: body is {len(body)} lines (> 100)")
if errors:
    print("\n".join(errors)); sys.exit(1)
print(f"OK: 5 anchors validated")
PY
```

Expected:

```
OK: 5 anchors validated
```

- [ ] **Step 3: Confirm the `/tipps`-keyed sections exist**

```bash
grep -l "^## Recommended$" docs/anchors/mcp-servers.md
grep -l "^## Deprecated patterns$" docs/anchors/claude-tools.md
grep -l "^## Anti-patterns$" docs/anchors/subagents.md
grep -l "^## Recommended layout$" docs/anchors/knowledge-base.md
grep -l "^## Deprecated$" docs/anchors/claude-models.md
```

Expected: each line prints the corresponding file path. A missing match means that anchor is not ready for the `/tipps` integration in the next plan.

- [ ] **Step 4: Trigger `workflow_dispatch` on the feature branch**

Push a temporary commit to a branch and trigger the workflow manually:

```bash
git checkout -b chore/test-anchor-updater
git push -u origin chore/test-anchor-updater
gh workflow run update-anchors.yml --ref chore/test-anchor-updater
```

Wait for the run to complete:

```bash
gh run watch
```

Expected: run completes with status `success`. The run either opens a PR (if any anchor was updated by the two-pass logic) or exits cleanly with no PR.

If the run fails because `_trend-sources.md` frontmatter is malformed, go back to the dependency branch `feat/anchor-trend-sources` and fix. If it fails because a canonical source returned non-200, that is acceptable for this validation — the workflow should tolerate a single dead source by skipping it, not by hard-failing the job.

- [ ] **Step 5: Delete the test branch**

```bash
git checkout main
git push origin --delete chore/test-anchor-updater
git branch -D chore/test-anchor-updater
```

---

### Task 10: Open the PR

**Files:**
- git state only.

- [ ] **Step 1: Push the feature branch**

```bash
git checkout -b feat/anchor-redesign
git push -u origin feat/anchor-redesign
```

- [ ] **Step 2: Open the PR**

```bash
gh pr create --title "feat(anchors): redesign anchor set and rebuild daily updater" --body "$(cat <<'EOF'
## Summary

Implements the anchor redesign from `docs/superpowers/specs/2026-04-21-anchor-redesign-design.md`:

- Removed: `docs/anchors/python-best-practices.md` (out of workspace-setup scope).
- Added: `docs/anchors/claude-tools.md`, `docs/anchors/subagents.md`, `docs/anchors/knowledge-base.md`.
- Reshaped: `docs/anchors/mcp-servers.md` gains a top-level `## Recommended` list for `/tipps` integration.
- Rewrote: `.github/workflows/update-anchors.yml` to a two-pass model (canonical + trend) consuming `_trend-sources.md`.
- Updated: `.github/PULL_REQUEST_TEMPLATE/anchor-update.md` now requires per-change provenance.
- Documented: `docs/anchors/README.md` describes the two-layer source architecture.

**Depends on:** PR adding `_trend-sources.md` (merge first).

**Does not include:** consumer-side integration (`/anchors`, setup-skill render step, `/tipps` and `/upgrade` updates). That lives in the follow-up PR from `2026-04-21-anchor-consumer-integration.md`.

## Test plan

- [x] Task 9 Step 1: anchor set matches the redesign.
- [x] Task 9 Step 2: all anchors validate schema and body length.
- [x] Task 9 Step 3: `/tipps`-keyed sections present in every relevant anchor.
- [x] Task 9 Step 4: `workflow_dispatch` runs end-to-end.
- [ ] Reviewer: spot-check each new anchor body for factual correctness against sources.
- [ ] Reviewer: confirm no references to `python-best-practices` remain anywhere in the repo.
EOF
)"
```

---

## Self-review checklist

Before handing off:

- [ ] Every new anchor has a `## Recommended`-equivalent section matching the spec's `/tipps`-check definitions (spec section 4.4).
- [ ] No placeholder text like "TBD" or "add content here" remains in any task.
- [ ] The workflow rewrite preserves the existing `allowed_tools` list and the no-auto-merge invariant.
- [ ] The `workflow_dispatch` validation in Task 9 Step 4 is genuinely executable on a feature branch.
- [ ] Delete-then-create tasks are sequenced so `python-best-practices` is gone before the new anchors are validated.
