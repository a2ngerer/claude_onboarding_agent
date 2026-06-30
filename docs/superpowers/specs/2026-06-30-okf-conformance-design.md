# OKF v0.1 Conformance for the Knowledge Base — Design

**Date:** 2026-06-30
**Status:** Implemented (v1.3.0)

## Context

`knowledge-base-setup` builds a Karpathy LLM-wiki: a `raw/` folder for source
material and a `wiki/` folder of interlinked Markdown notes. Until now the note
format was ad hoc — a one-line summary, an inline `tags: #a #b` line, a body, and
a `## Related: [[wikilink]]` footer.

On 2026-06-12 Google Cloud published the **Open Knowledge Format (OKF)**, a
vendor-neutral specification that formalizes exactly this LLM-wiki pattern into a
portable, interoperable format. An OKF bundle is just a directory of Markdown
files with YAML frontmatter — no SDK, no runtime, no manifest. Aligning the
generated wiki to OKF makes every knowledge base this plugin produces portable to
any OKF-aware agent or tool, at no cost to the existing workflow.

Spec: <https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md>

## OKF v0.1 in brief

Verified against the official spec, the reference bundles in
`GoogleCloudPlatform/knowledge-catalog`, the Google Cloud announcement blog, and
independent explainers:

- **One concept per file.** Every non-reserved `.md` file is one concept.
- **Required frontmatter:** exactly one key — `type`, a non-empty free-form
  string. No closed enumeration; real bundles use as few as three values
  (`BigQuery Table`, `BigQuery Dataset`, `Reference`) and distinguish purpose via
  `tags`.
- **Recommended frontmatter** (priority order): `title`, `description`,
  `resource`, `tags` (a YAML list), `timestamp` (ISO 8601). Real bundles emit
  keys in the order `type, resource, title, description, tags, timestamp`.
- **Reserved filenames:** `index.md` (per-directory listing for progressive
  disclosure; carries no frontmatter) and `log.md` (optional chronological
  history; `YYYY-MM-DD` headings, newest first, entries prefixed with a bold
  action word).
- **Cross-linking:** standard Markdown links to `.md` files — absolute
  bundle-relative (`/path`) or relative. Untyped relationships; broken links
  tolerated. Wikilinks are not part of OKF.
- **Conformance (hard):** parseable frontmatter on every non-reserved file;
  non-empty `type`; reserved files follow their structures when present.
  Everything else is soft.

## Decision

Make the generated `wiki/` an OKF v0.1 bundle by default.

1. **Concept note format → OKF frontmatter.** Replace the summary/`tags:`/Related
   convention with YAML frontmatter (`type` required; `title`, `description`,
   `tags`, `timestamp` recommended; `resource` when an external asset exists),
   an H2/H3 body, and a `## Related` section of Markdown links.
2. **Links → Markdown, not wikilinks.** Canonical cross-links are Markdown links
   (bundle-relative preferred). Wikilinks become an optional Obsidian-only
   convenience, never a replacement.
3. **Seed reserved files.** Setup creates `wiki/index.md` (seeded listing, no
   frontmatter) and `wiki/log.md` (seeded with a `**Creation**` entry) so the
   bundle is conformant from the first commit. Ingestion keeps both current.
4. **Conformance self-check.** Ingestion ends with the OKF self-check
   (frontmatter present, non-empty `type`, Markdown links).

## Obsidian reconciliation

OKF and Obsidian do not conflict. Obsidian renders YAML frontmatter as native
Properties and Markdown links in its graph view, and `obsidian move` rewrites
Markdown links. `tags:` as a list (no leading `#`) is what Obsidian already
expects. The single OKF `timestamp` is canonical; a vault's existing
`created`/`updated` keys coexist as extension fields. The `obsidian-vault-keeper`
subagent is instructed to write frontmatter with a non-empty `type` on every new
note.

## Modularization

`skills/knowledge-base-setup/SKILL.md` was already over the 300-line
modularization threshold. The OKF skeletons, linking rule, `type` vocabulary,
conformance self-check, and Obsidian reconciliation move to the sibling
`document-skeletons.md` (a canonical sibling filename per the repo's
modularization convention), read on-demand at Step 3. SKILL.md keeps the step
ordering, the generated `wiki/README.md` and CLAUDE.md blocks, and a pointer to
the sibling.

## Files changed

- `skills/knowledge-base-setup/document-skeletons.md` — new sibling (OKF skeletons + rules)
- `skills/knowledge-base-setup/SKILL.md` — description, folder structure, seeded `index.md`/`log.md`, OKF note format, ingestion conformance, vault-keeper frontmatter rule, completion summary
- `docs/anchors/knowledge-base.md` — OKF frontmatter conventions + conformance section; sources + version bump
- `README.md` — "Pick your path", "What's Inside", "What gets generated", and the knowledge-base section
- `skills/onboarding/SKILL.md` — knowledge-base menu line notes the OKF bundle
- `.claude-plugin/plugin.json` — version bump to 1.3.0
- `docs/RELEASE-NOTES.md` — v1.3.0 entry

## Out of scope

- `graphify-setup` builds a knowledge *graph* (a queryable index), not an
  LLM-wiki, so OKF does not apply to it.
- No OKF validator tool ships with the plugin; conformance is enforced by the
  ingestion self-check, not by external tooling (consistent with OKF's
  "no required SDK" stance).
