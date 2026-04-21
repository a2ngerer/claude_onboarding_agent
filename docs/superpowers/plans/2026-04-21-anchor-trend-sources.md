# Anchor Trend Sources Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a new file `docs/anchors/_trend-sources.md` that defines exactly three global trend-radar URLs used by the daily anchor updater, with per-source rationale and coverage mapping on the five anchor slugs.

**Architecture:** One new markdown file with YAML frontmatter. The file is NOT an anchor — it is read only by the daily updater workflow. Consumer skills never fetch it. This plan covers research, authorship, and validation. Implementation of the daily-updater changes that consume it lives in a separate plan (`2026-04-21-anchor-redesign-updater.md`).

**Tech Stack:** Markdown, YAML frontmatter, `WebFetch`, `WebSearch`.

**Spec:** `docs/superpowers/specs/2026-04-21-anchor-redesign-design.md` — read section 2 ("Two-layer source architecture") before starting.

---

### Task 1: Establish evaluation criteria

**Files:**
- Create: `docs/anchors/_trend-sources.md` (staged, no content yet — will be written in Task 4)

- [ ] **Step 1: Read the spec**

Read `docs/superpowers/specs/2026-04-21-anchor-redesign-design.md`, sections 1–2. In particular, note the five anchor slugs — `claude-models`, `mcp-servers`, `claude-tools`, `subagents`, `knowledge-base` — and the distinction between canonical sources and trend sources.

- [ ] **Step 2: Write the evaluation criteria in your scratchpad (no file yet)**

A qualifying trend source must satisfy all five:

1. **Freshness:** updated at least weekly (daily preferred).
2. **Topicality:** regularly surfaces new MCP servers, agent/subagent patterns, Claude tooling updates, Claude model releases, or KB workflows — not generic AI news.
3. **Machine-readable:** the updater will scrape this URL via `WebFetch`. HTML/RSS/Atom/plain-markdown pages work. Authenticated-only feeds, JavaScript-heavy SPAs, and PDF-only feeds do not.
4. **Stable URL:** no query parameters required to reach the content; no redirect chains that break unauthenticated GETs.
5. **Signal density:** each visit produces at least a few items that would plausibly inform an anchor, not one item per month.

Do not write these criteria into any file. They guide Task 2 and Task 3.

---

### Task 2: Build a shortlist of candidate sources

**Files:**
- Nothing written yet. This task is research only.

- [ ] **Step 1: Search for candidates**

Use `WebSearch` and `WebFetch` to identify 8–12 candidate URLs that plausibly satisfy the criteria from Task 1. Look across at least these categories:

- **Anthropic-owned:** `anthropic.com/engineering`, `docs.claude.com` changelogs, official Claude newsletters if any.
- **MCP ecosystem:** `github.com/modelcontextprotocol/servers` (releases/commits feed), mcp.so if still live, Discord-linked pages only if publicly accessible without login.
- **Agent / workflow patterns:** Simon Willison's blog feed, Karpathy's X/Twitter export if a public RSS mirror exists, Every.to's "AI Workflows" and similar hand-curated publications, Latent Space newsletter web archive, hackernews front page filtered (only if a reliable "show HN Claude" archive exists).
- **KB / Obsidian:** Obsidian's official forum announcements, Obsidian's "What's new" page, r/ObsidianMD RSS (if reachable without login).
- **Aggregators:** "This Week in AI Agents" style newsletters with public web archives.

- [ ] **Step 2: For each candidate, record:**

URL, primary topic coverage (which of the five anchor slugs it would inform), estimated update cadence, whether `WebFetch` returns useful content. Write this as a short table in your scratchpad — do not commit it.

- [ ] **Step 3: Eliminate disqualified candidates**

Drop any candidate that fails any of the five criteria. In particular: drop X/Twitter URLs that require auth, drop Discord channels, drop sources whose `WebFetch` returns only boilerplate HTML.

You should have at least 5 and at most 8 remaining candidates after this elimination. If fewer than 5 remain, go back to Step 1 and widen the search. If more than 8 remain, keep all — the scoring in Task 3 will thin the list.

---

### Task 3: Score and select the top 3

**Files:**
- Nothing written yet.

- [ ] **Step 1: Score each remaining candidate on coverage**

For each candidate, list which of the five anchor slugs it would inform. A source that covers more slugs is preferred, but a highly-focused source for an under-covered slug is also valuable.

- [ ] **Step 2: Solve the set-cover constraint**

You must select exactly three URLs such that **every** anchor slug (`claude-models`, `mcp-servers`, `claude-tools`, `subagents`, `knowledge-base`) is covered by at least one of them. If no three-source combination achieves full coverage, extend the shortlist in Task 2 until one does.

Prefer combinations where:
- At least one source is community-driven (not Anthropic-owned), to catch external signals like a community-released MCP or a Karpathy-posted workflow.
- No two sources have fully overlapping coverage (redundancy wastes the budget).
- At least one source has a stable dated-URL structure (permalinks) so the updater can reference specific items in rationales.

- [ ] **Step 3: Write down the selected three**

For each of the three, prepare the four pieces the final frontmatter will need:
- `url` — canonical URL (no tracking params).
- `rationale` — one sentence explaining why this source catches trends early and what kind of signal it provides.
- `covers` — list of anchor slugs, strict subset of `{claude-models, mcp-servers, claude-tools, subagents, knowledge-base}`.

- [ ] **Step 4: Verify set cover before writing**

Manually confirm that the union of the three `covers:` lists equals the full set of five anchor slugs. If not, revise the selection — do not proceed to Task 4 with a gap.

---

### Task 4: Write `_trend-sources.md`

**Files:**
- Create: `docs/anchors/_trend-sources.md`

- [ ] **Step 1: Write the file**

Use this exact structure. Replace the three `<url>`/`<rationale>`/`<covers>` triples with the selection from Task 3.

```markdown
---
name: _trend-sources
description: Global trend radar for the daily anchor updater — picks up new Claude/MCP/agent patterns before they land in official docs
last_updated: 2026-04-21
version: 1
sources:
  - url: <source-1-url>
    rationale: <source-1-one-sentence-rationale>
    covers: [<subset-of-five-slugs>]
  - url: <source-2-url>
    rationale: <source-2-one-sentence-rationale>
    covers: [<subset-of-five-slugs>]
  - url: <source-3-url>
    rationale: <source-3-one-sentence-rationale>
    covers: [<subset-of-five-slugs>]
---

## Selection notes

One short paragraph (≤ 10 lines) explaining the overall picking logic: why these three as a set, how they complement each other, and which source fills the "community trends" role. This section is for human reviewers — the daily updater does not parse it.
```

Body ≤ 30 lines total. The frontmatter is what the updater parses. The body is documentation for the human reviewer.

- [ ] **Step 2: Verify no unrelated files were touched**

Run:

```bash
git status --porcelain
```

Expected output (exactly one line):

```
?? docs/anchors/_trend-sources.md
```

If any other files are shown, investigate — this plan should not have touched anything else.

---

### Task 5: Validate the file against acceptance criteria

**Files:**
- None written. Validation only.

- [ ] **Step 1: Parse frontmatter and check schema**

Run this `uv run` one-liner from the repo root. `uv` is the project-standard Python tool per `~/.claude/rules/python.md`.

```bash
uv run --with pyyaml python - <<'PY'
import pathlib, re, sys, yaml
p = pathlib.Path("docs/anchors/_trend-sources.md")
text = p.read_text()
m = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
assert m, "no frontmatter block found"
fm = yaml.safe_load(m.group(1))
required = {"name", "description", "last_updated", "version", "sources"}
missing = required - fm.keys()
assert not missing, f"missing frontmatter keys: {missing}"
assert fm["name"] == "_trend-sources", f"name must be '_trend-sources', got {fm['name']!r}"
assert isinstance(fm["version"], int), "version must be an integer"
assert re.match(r"^\d{4}-\d{2}-\d{2}$", str(fm["last_updated"])), "last_updated must be YYYY-MM-DD"
assert isinstance(fm["sources"], list) and len(fm["sources"]) == 3, f"must have exactly 3 sources, got {len(fm['sources'])}"
slugs = {"claude-models", "mcp-servers", "claude-tools", "subagents", "knowledge-base"}
covered = set()
for i, s in enumerate(fm["sources"]):
    for k in ("url", "rationale", "covers"):
        assert k in s, f"source[{i}] missing key {k!r}"
    assert isinstance(s["covers"], list) and s["covers"], f"source[{i}] covers must be non-empty list"
    extra = set(s["covers"]) - slugs
    assert not extra, f"source[{i}] covers has invalid slugs: {extra}"
    covered |= set(s["covers"])
gap = slugs - covered
assert not gap, f"uncovered anchor slugs: {gap}"
print("OK: schema valid, 3 sources, full coverage")
PY
```

Expected output:

```
OK: schema valid, 3 sources, full coverage
```

If the script raises an `AssertionError`, fix the file and re-run. Do not commit until this passes.

- [ ] **Step 2: Verify body length**

```bash
awk '/^---$/{c++; next} c==2' docs/anchors/_trend-sources.md | wc -l
```

Expected: a number ≤ 30. If larger, trim the selection notes paragraph.

- [ ] **Step 3: Verify no other files changed**

```bash
git status --porcelain
```

Expected:

```
?? docs/anchors/_trend-sources.md
```

---

### Task 6: Commit and open PR

**Files:**
- Modify: git state only.

- [ ] **Step 1: Stage and commit**

```bash
git add docs/anchors/_trend-sources.md
git commit -m "docs(anchors): add _trend-sources.md with top-3 trend-radar URLs"
```

- [ ] **Step 2: Push a feature branch**

```bash
git checkout -b feat/anchor-trend-sources
git push -u origin feat/anchor-trend-sources
```

- [ ] **Step 3: Open the PR**

```bash
gh pr create --title "feat(anchors): add global trend-sources radar" --body "$(cat <<'EOF'
## Summary

Adds `docs/anchors/_trend-sources.md`, the global trend-radar layer defined in section 2 of the anchor-redesign spec (`docs/superpowers/specs/2026-04-21-anchor-redesign-design.md`). Exactly three URLs, each with a rationale and a `covers:` mapping onto the five anchor slugs, with full set-cover.

No other files touched. The daily updater is not yet wired to consume this file — that happens in the follow-up plan `2026-04-21-anchor-redesign-updater.md`.

## Validation

- [x] Frontmatter schema validates (see plan Task 5, Step 1).
- [x] Exactly three `sources[]` entries.
- [x] Full coverage: every anchor slug in at least one source's `covers:`.
- [x] At least one community-driven source.
- [x] Body ≤ 30 lines.

## Test plan

- [ ] Reviewer confirms each source's rationale is plausible.
- [ ] Reviewer manually opens each URL in a browser to verify it loads without auth and shows recent items.
- [ ] Reviewer confirms the `covers:` lists match the actual topical focus of each source.
EOF
)"
```

---

## Self-review checklist

Before handing off:

- [ ] Every step has concrete, runnable content (no "research and decide" with no criteria).
- [ ] Task 5 validation is runnable by an implementing Claude with `uv` installed.
- [ ] The plan never tells the implementer WHICH URLs to pick — that is genuinely left to the research.
- [ ] Acceptance criteria from spec (section "Issue #1") are mirrored 1:1 in Task 5's validation script.
- [ ] No references to types, functions, or skills defined outside this plan.
