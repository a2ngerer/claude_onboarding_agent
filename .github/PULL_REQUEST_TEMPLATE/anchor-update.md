## Anchor update

Automated daily run of `.github/workflows/update-anchors.yml`.

### Changed anchors
<!-- bullet list of docs/anchors/*.md files modified, one per line -->

### Diff summary per anchor
<!-- for each changed file, 1-3 bullets describing what changed and which source triggered it -->

### Reviewer checklist
- [ ] Frontmatter schema still matches `docs/anchors/README.md` (name, description, last_updated, sources, version)
- [ ] Body is ≤ 100 lines
- [ ] `sources` URLs are unchanged — the updater must not invent new sources
- [ ] `version` bumped, `last_updated` set to today UTC
- [ ] No secrets or PII introduced
- [ ] No files outside `docs/anchors/` changed

> Do not auto-merge. Anchors are pulled by user projects at runtime — a human must review before merge.
