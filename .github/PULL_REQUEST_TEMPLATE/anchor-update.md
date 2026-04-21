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
