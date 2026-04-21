# Anchor Redesign — Design Spec

- **Date:** 2026-04-21
- **Status:** Approved (pending written-spec review)
- **Related:** `docs/superpowers/plans/2026-04-21-realtime-anchors.md`, `docs/anchors/README.md`, `skills/_shared/fetch-anchor.md`

---

## Problem

The current anchor set (`claude-models`, `mcp-servers`, `python-best-practices`) does not align with the repository's main purpose — helping users set up an ideal Claude workspace. `python-best-practices` is generic developer tooling, unrelated to Claude workspace configuration. The other two are useful but incomplete: the set is missing topics that matter for workspace setup (Claude's own tooling surface, subagent orchestration, knowledge-base repository structure).

The daily updater currently relies on per-anchor `sources:` lists only. Those sources are authoritative documentation sites that update slowly. New trends — a new high-quality MCP server, a new agent-orchestration pattern published by a community author — often land in community feeds weeks before they reach official docs. The updater currently has no way to surface those.

On the consumer side, the anchors are defined but only lightly used. `/tipps` uses `claude-models` for a single check; `/upgrade` uses it for optional diff-based ID replacement. The other anchors (`mcp-servers`, `python-best-practices`) are written but never read by any skill. As a result, the daily-review effort of maintaining anchors produces limited user-visible value.

## Goals

1. Redefine the anchor set so every anchor maps directly to a workspace-setup concern the plugin already handles.
2. Extend the daily updater to catch community trends without loosening the existing security invariant that forbids the updater from inventing new sources.
3. Make anchors genuinely functional on the consumer side by rendering curated excerpts into setup-generated files and providing a refresh command.
4. Keep the hard security invariant: raw anchor markdown never lands in a user's project directory.

## Non-goals

- Replacing the existing fetch-anchor protocol (`skills/_shared/fetch-anchor.md`). It stays; callers change.
- Adding anchors outside the workspace-setup scope (e.g. general programming-language guides).
- Auto-merging daily-updater PRs. Human review remains the trust boundary.

---

## Design

### 1. Anchor set

Five anchors after the redesign. `python-best-practices.md` is removed.

| Slug | Purpose | Primary canonical sources (`sources:`) |
|---|---|---|
| `claude-models` | Current Claude model IDs, aliases, context limits, recommended defaults. | `docs.claude.com/en/docs/about-claude/models`, `docs.claude.com/en/docs/about-claude/pricing`. Unchanged. |
| `mcp-servers` | Recommended MCP servers by use case, official install strings, maturity ranking. | `docs.claude.com/en/docs/claude-code/mcp`, `github.com/modelcontextprotocol/servers`. |
| `claude-tools` | **New.** How to configure Claude's core tooling surface: hooks, rules, `CLAUDE.md`, `AGENTS.md`, settings, slash commands, plugins. Structural patterns. | `docs.claude.com/en/docs/claude-code` (hooks, settings, plugins, slash-commands pages). |
| `subagents` | **New.** Subagent patterns, delegation heuristics, Task/Agent vs. direct tools, context isolation, parallel dispatch. | `docs.claude.com/en/docs/claude-code/sub-agents`, `anthropic.com/engineering` (agent posts). |
| `knowledge-base` | **New.** Vault layouts for Obsidian-style KB setups, naming conventions, frontmatter patterns, KB-agent patterns. | Obsidian documentation plus the plugin's own `skills/knowledge-base-builder/SKILL.md` as a structural reference point. |

All anchor files continue to follow `docs/anchors/README.md`: frontmatter required, body ≤ 100 lines, machine-parsable `##` section headers.

### 2. Two-layer source architecture

**Layer 1 — Canonical sources (per-anchor, frontmatter).**  
Authoritative URLs used to verify factual content. Behavior unchanged from today. The updater never adds URLs to this list; a source change is a separate human PR.

**Layer 2 — Trend sources (global, `docs/anchors/_trend-sources.md`).**  
New central file containing exactly three URLs. Each entry declares which anchor slugs it informs.

```markdown
---
name: _trend-sources
description: Global trend radar for the daily anchor updater — picks up new Claude/MCP/agent patterns before they land in official docs
last_updated: <YYYY-MM-DD>
version: <integer>
sources:
  - url: <canonical feed URL>
    rationale: <why this source catches trends early>
    covers: [claude-tools, subagents, mcp-servers]
  - url: ...
  - url: ...
---
```

The `covers:` list is a subset of `{claude-models, mcp-servers, claude-tools, subagents, knowledge-base}`. Each of the five anchor slugs must be covered by at least one trend source.

`_trend-sources.md` is **not an anchor**. The consumer fetch-anchor protocol never fetches it. It is read only by the daily-updater workflow. The security invariant that only `raw.githubusercontent.com/a2ngerer/claude_onboarding_agent/main/docs/anchors/<name>.md` is fetchable by consumers stays in force.

### 3. Daily updater workflow

`.github/workflows/update-anchors.yml` keeps its cron (`17 6 * * *`) and `workflow_dispatch`. The embedded prompt is rewritten.

**Step 1 — Load trend sources.**  
Read `docs/anchors/_trend-sources.md`, parse `sources[].url` and `sources[].covers`. If the file is missing or malformed, fail the workflow with a clear error — trend-layer is now part of the contract, not optional.

**Step 2 — Per-anchor iteration.**  
For each `docs/anchors/*.md` except `README.md` and `_trend-sources.md`:

- **2a Canonical pass:** `WebFetch` each URL in the anchor's `sources:`. Diff the body against canonical facts. Rewrite if facts are stale. (Unchanged behavior.)
- **2b Trend pass:** filter trend sources whose `covers:` contains this anchor slug. For each, `WebFetch` and scan for newly-mentioned tools, patterns, or workflows that warrant a body update. Rewrite only when:
  - The new mention fits the anchor's topic (e.g. a new MCP server → `mcp-servers.md`).
  - The change has a short defensible rationale (one sentence).
  - Body remains ≤ 100 lines.

**Step 3 — Per-rewrite invariants.**
- Preserve frontmatter schema exactly (`name`, `description`, `last_updated`, `sources`, `version`).
- `version` += 1 on any content change.
- `last_updated` = today UTC.
- `sources:` never extended by the updater (neither per-anchor nor trend).
- No files touched outside `docs/anchors/`.

**Step 4 — PR creation.**  
Branch `chore/anchors-update-YYYY-MM-DD`. PR body uses the updated template (see section 6). No auto-merge.

Allowed tools remain: `Read,Write,Edit,WebFetch,Bash(git:*),Bash(gh:*),Bash(date:*)`.

### 4. Consumer architecture

Three touch points in the user's repository.

#### 4.1 Setup skills

At the end of each **primary** setup skill (`coding-setup`, `data-science-setup`, `devops-setup`, `design-setup`, `web-development-setup`, `knowledge-base-builder`, `academic-writing-setup`, `content-creator-setup`, `office-setup`, `research-setup`), after file generation and before the completion summary, a new step runs:

1. Read the setup→anchor mapping from `skills/_shared/anchor-mapping.md`.
2. For each mapped anchor slug: call `skills/_shared/fetch-anchor.md`.
3. For each fetched anchor, render a **curated excerpt** (typically the `## Recommendations` or `## Defaults` block) and write it to a dedicated marker section in `CLAUDE.md` (and `AGENTS.md` where that skill generates one):

   ```markdown
   <!-- onboarding-agent:start setup=<type> skill=<skill-slug> section=anchor-<anchor-slug> -->
   ... rendered excerpt ...
   <!-- onboarding-agent:end -->
   ```

4. The completion summary mentions `/anchors` as the refresh path.

When the anchor is unavailable (no cache, no network, no fallback — `fetch-anchor` returns `anchor_markdown: null`), the skill writes the marker section with a single placeholder line: `<!-- anchor unavailable at render time — run /anchors to retry -->`. Generation does not fail.

#### 4.2 Setup→anchor mapping

Single source of truth at `skills/_shared/anchor-mapping.md`. Table:

| Setup type | Anchors |
|---|---|
| `coding` | `claude-models`, `mcp-servers`, `claude-tools`, `subagents` |
| `data-science` | `claude-models`, `mcp-servers`, `claude-tools`, `subagents` |
| `devops` | `claude-models`, `mcp-servers`, `claude-tools` |
| `design` | `claude-models`, `mcp-servers`, `claude-tools` |
| `content-creator` | `claude-models`, `claude-tools` |
| `office` | `claude-models`, `claude-tools` |
| `research` | `claude-models`, `claude-tools` |
| `academic-writing` | `claude-models`, `claude-tools` |
| `knowledge-base` | `claude-models`, `claude-tools`, `subagents`, `knowledge-base` |
| `web-development` | `claude-models`, `mcp-servers`, `claude-tools`, `subagents` |

Baseline: every primary setup gets `claude-models` + `claude-tools`. `subagents` only where agentic workflows are realistic (coding, data-science, web-development, knowledge-base). `mcp-servers` only where MCPs are realistically installed. `knowledge-base` only for the KB setup.

**Delegated skills** (`graphify-setup`) are explicitly **excluded** from the mapping. Graphify is a visualization overlay that runs on top of a host setup and inherits the host's `setup_type` in the meta file; it does not render its own anchor marker sections. A user who runs graphify standalone gets no anchor sections — that is acceptable, graphify is not a workspace-setup concern.

#### 4.3 `/anchors` meta-slash-command

New skill at `skills/anchors/SKILL.md`, protocol-style (same interaction pattern as `/upgrade`).

1. Read `./.claude/onboarding-meta.json` → `setup_type`. If missing, ask the user which type applies (offering the nine slugs from the mapping). If the user cancels, exit without writes.
2. Load the anchor list for that type from the mapping.
3. For each anchor, call `fetch-anchor.md` (cache / network / fallback).
4. For each anchor's marker section in `CLAUDE.md` / `AGENTS.md`, re-render the curated excerpt and compute a unified diff against the on-disk body (3 lines of context).
5. Present diffs to the user per section. Accept `y / n / all / skip-rest` replies (identical semantics to `/upgrade` Pass 3).
6. Back up every file that will be written to `./.claude/backups/<timestamp>/` before writing. Support a `--dry-run` flag that prints diffs without writing.
7. After successful writes, update `./.claude/onboarding-meta.json` with `anchors_refreshed_at: <ISO-8601 UTC timestamp>`. `setup_type`, `skills_used`, `installed_at`, `plugin_version`, `upgraded_at` remain untouched.

`/anchors` never creates marker sections that do not already exist — it only refreshes existing ones. Initial creation is the setup skill's job. This keeps the tool surface narrow: `/onboarding` creates, `/anchors` refreshes.

#### 4.4 `/tipps` Pass 5 generalization

Today: only `claude-models` is checked for deprecated IDs.

New behavior: read `./.claude/onboarding-meta.json` → `setup_type`. For each anchor in the mapping for that setup, run anchor-specific checks. The `claude-models` deprecated-ID check stays as-is. Each new anchor adds exactly one check, all keyed off the anchor's `## Recommendations` section (or the anchor-specific equivalent named in the per-check definition below):

- **`mcp-servers`** `[LOW]` — An entry in `.claude/settings.json`'s `mcpServers` is not in the anchor's `## Recommended` list. Finding: "MCP server `<name>` is not on the current recommended list — review whether it still fits your setup."
- **`claude-tools`** `[LOW]` — A file or key referenced in the anchor's `## Deprecated patterns` section is present in the user's repo (e.g. a deprecated hook key in `.claude/settings.json`, a deprecated directory name under `.claude/`). Finding: "`<pattern>` is marked deprecated in the current claude-tools anchor — migrate to `<replacement>`."
- **`subagents`** `[LOW]` — A subagent definition file or configuration references a pattern listed in the anchor's `## Anti-patterns` section. Finding: "Subagent usage pattern `<name>` is flagged as an anti-pattern by the current subagents anchor."
- **`knowledge-base`** `[LOW]` — Only runs when `setup_type == knowledge-base`. The detected vault layout deviates from the anchor's `## Recommended layout`. Finding: "Vault layout does not match the current knowledge-base anchor recommendation."

If the anchor lacks the required section at fetch time, the corresponding check is skipped silently. All four new checks are `LOW` severity.

Fallback: if no setup is detectable (no meta file, no marker), retain today's behavior — only the `claude-models` check runs.

#### 4.5 `/upgrade` Pass 2 extension

Today: Pass 2 diffs Plugin-template marker sections.

New behavior: during Pass 2.2 enumeration, recognize marker sections matching `section=anchor-*`. For those, compute the diff against the **current rendered excerpt** of the corresponding anchor (fetched via `fetch-anchor.md`), not against a plugin template. The diff interaction in Pass 3 is identical. Accepted diffs write the new excerpt. The anchor markdown itself is never written to the repo.

Effectively `/upgrade` becomes a superset of `/anchors` — running `/upgrade` refreshes both templates and anchor excerpts; `/anchors` is the focused, narrower tool for users who only want to refresh the anchor-derived bits.

### 5. Security properties (preserved)

- Raw anchor markdown is never written to the user's repo. Only curated excerpts, produced by a skill, land in marker sections.
- Consumer fetches remain restricted to `raw.githubusercontent.com/a2ngerer/claude_onboarding_agent/main/docs/anchors/<name>.md`. `_trend-sources.md` is not consumer-fetchable.
- Cache stays at `~/.claude/cache/anchors/`, never under the user's project path.
- The daily updater still cannot invent new `sources:` URLs (per-anchor or trend).
- Anchor name validation (`^[a-z0-9][a-z0-9-]*$`) stays; `_trend-sources.md` is not passed through consumer fetch paths.

### 6. PR template update

`.github/PULL_REQUEST_TEMPLATE/anchor-update.md` gains a per-change provenance requirement. Template sketch:

```markdown
### Changed anchors
<!-- bullet list of docs/anchors/*.md files modified -->

### Per-change provenance
<!-- for each changed file, one block: -->
<!-- - <anchor>.md -->
<!--   - pass: canonical | trend -->
<!--   - source: <url> -->
<!--   - rationale: <one sentence> -->
```

The reviewer checklist gains one item: *"Each change lists pass type, source URL, and rationale."* No auto-merge; everything else in the checklist stays.

---

## Issue split

Three GitHub issues, implementable in order by pointing Claude at them with the writing-plans-generated implementation plan as the issue body.

### Issue #1 — Research top-3 trend sources for the anchor updater

**Scope:** Web research. Pick exactly three URLs as the global trend radar. Each gets a rationale and a `covers:` mapping on the five anchor slugs.

**Artifacts:** One new file `docs/anchors/_trend-sources.md` following the frontmatter schema in section 2. Optional body text under the closing `---` may explain the selection in more detail.

**Acceptance criteria:**
- Exactly three entries in `sources[]`.
- Each `covers:` list is a subset of `{claude-models, mcp-servers, claude-tools, subagents, knowledge-base}`.
- Every anchor slug is covered by at least one source.
- At least one source is community-driven (would plausibly catch a newly-released MCP server or a newly-published agent workflow within days, not months).
- File validates against the frontmatter schema.
- No other files changed.

### Issue #2 — Redesign anchors and rebuild daily updater (blocked by #1)

**Scope:** Implement the new anchor set and rewire the daily workflow to the two-layer model.

**Artifacts:**
- Delete `docs/anchors/python-best-practices.md`.
- New: `docs/anchors/claude-tools.md`, `docs/anchors/subagents.md`, `docs/anchors/knowledge-base.md` (each with a valid frontmatter, canonical `sources:` per section 1, body ≤ 100 lines).
- Update: bump `version` and `last_updated` on `docs/anchors/mcp-servers.md` and `docs/anchors/claude-models.md` if any content is re-shaped; otherwise leave.
- Rewrite: `.github/workflows/update-anchors.yml` prompt per section 3.
- Rewrite: `.github/PULL_REQUEST_TEMPLATE/anchor-update.md` per section 6.
- Update: `docs/anchors/README.md` — document the two-layer model, `_trend-sources.md`, and the distinction between `sources:` and trend sources.

**Acceptance criteria:**
- All five anchor files validate against the frontmatter schema and the ≤ 100-line body limit.
- `workflow_dispatch` runs end-to-end on a branch without inventing new URLs and without touching files outside `docs/anchors/`.
- A dry-run of the workflow on a branch produces a structurally correct PR body with per-change provenance filled in.
- No references to `python-best-practices` remain in the repo (code, docs, workflows).

### Issue #3 — Wire anchors into onboarding, `/anchors`, `/tipps`, `/upgrade` (blocked by #2)

**Scope:** Consumer-side integration per section 4.

**Artifacts:**
- New: `skills/_shared/anchor-mapping.md` (setup → anchor list).
- New: `skills/anchors/SKILL.md` (the `/anchors` command, protocol-style).
- Update: `.claude-plugin/plugin.json` — register the new skill and `/anchors` slash command.
- Update every primary setup skill (`coding-setup`, `data-science-setup`, `devops-setup`, `design-setup`, `web-development-setup`, `knowledge-base-builder`, `academic-writing-setup`, `content-creator-setup`, `office-setup`, `research-setup`) with the anchor-render step and the completion-summary mention of `/anchors`. Do not modify `graphify-setup` — see section 4.2.
- Update `skills/onboarding/SKILL.md` — after the setup-skill delegation, add the `/anchors` hint.
- Update `skills/tipps/SKILL.md` — generalize Pass 5 per section 4.4.
- Update `skills/upgrade/SKILL.md` — extend Pass 2 per section 4.5.
- Update `README.md` (What's Inside table) and `CLAUDE.md` (Adding-a-New-Skill checklist if necessary).

**Acceptance criteria:**
- `/anchors` on a freshly-onboarded project produces no diff (setup skill already rendered).
- `/anchors --dry-run` on a project with stale anchor cache shows a diff per affected marker section.
- A setup skill running with no cache, no network, and no embedded fallback does not fail; the marker section gets a placeholder comment.
- No raw anchor markdown is written to the user's repo as a whole file; only curated excerpts inside marker sections.
- `/tipps` and `/upgrade` behavior for non-anchor sections is unchanged.

### Dependency graph

`#2 blocked by #1` — trend sources must be merged before the workflow rewrite can reference them.  
`#3 blocked by #2` — consumer integration needs the new anchor files on `main` to fetch against.

---

## Open questions

None at spec time. All five decisions (anchor set, slash-command architecture, source model, issue split, `/anchors` semantics) are resolved above.
