# Document Skeletons — OKF-conformant wiki bundle

> Consumed by knowledge-base-setup/SKILL.md at Step 3 (artifact generation) and referenced by the generated CLAUDE.md ingestion workflow. Do not invoke directly. Do not read eagerly.

The `wiki/` folder this skill produces is an **OKF v0.1 bundle** — Google Cloud's
Open Knowledge Format, the published standard for the Karpathy LLM-wiki pattern.
A bundle is just a directory of Markdown files: one concept per file, a small
YAML frontmatter block per concept, and standard Markdown links between them.
Spec: https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md

## OKF in one screen

- **One concept per file.** Every non-reserved `.md` file describes a single
  concept (a topic, person, project, module, API, dataset, …).
- **Required frontmatter:** exactly one key — `type`, a non-empty free-form
  string identifying the kind of concept.
- **Recommended frontmatter** (priority order): `title`, `description`,
  `resource`, `tags` (a YAML list), `timestamp` (ISO 8601 of the last meaningful
  change). Real bundles emit them in the order `type, resource, title,
  description, tags, timestamp`.
- **Two reserved filenames:** `index.md` (per-directory listing, no frontmatter)
  and `log.md` (optional chronological history). Every other `.md` is a concept.
- **Links are standard Markdown links to `.md` files — never wikilinks.**
  OKF consumers parse Markdown links; `[[wikilinks]]` are invisible to them.

## Concept note skeleton

Write one file per concept. Filename is kebab-case (`knowledge-graphs.md`).

```markdown
---
type: concept
title: Knowledge Graphs
description: One-sentence summary of what this note covers.
resource: https://example.com/source   # optional — URI of the underlying asset; omit for prose notes
tags: [graphs, retrieval]
timestamp: 2026-06-30T12:00:00+00:00
---

# Knowledge Graphs

Structured body with H2/H3 headers — definitions, key facts, design decisions.

## Related
- [Embeddings](embeddings.md) — how vectors back the graph
- [Vector Search](/references/vector-search.md) — bundle-relative link
```

`type` is required; everything else is recommended-but-optional. Keep `type`
first. Omit `resource` when there is no external asset.

### `type` vocabulary

Free-form strings, producer-chosen — there is no closed enumeration. Pick a small,
consistent set and reuse it:

- **Notes / second brain:** `concept`, `person`, `project`, `topic`, `reference`
- **Codebases:** `module`, `component`, `service`, `api`, `reference`

Distinguish finer purpose with `tags`, not by inventing one `type` per note
(real OKF bundles use as few as three distinct `type` values and lean on tags).

## `index.md` skeleton (reserved — no frontmatter)

A plain-Markdown directory listing for progressive disclosure: a reader scans the
index before opening individual notes. No YAML frontmatter. Group entries under
headings; each entry is a relative Markdown link plus a one-line description.

```markdown
# Knowledge Base — Index

## Concepts
- [Knowledge Graphs](knowledge-graphs.md) — graph-structured knowledge representation
- [Embeddings](embeddings.md) — dense vector representations of meaning

## Subdirectories
- [references](references/index.md) — supporting reference notes
```

Give every subdirectory its own `index.md` following the same pattern.

## `log.md` skeleton (reserved — optional)

Chronological update history, newest date first. ISO 8601 `YYYY-MM-DD` date
headings; each entry is prefixed with a bold action word (`**Creation**`,
`**Update**`). Optional — per-note `timestamp` frontmatter already records change
time, so a `log.md` is only worth keeping when a human-readable changelog helps.

```markdown
# Update Log

## 2026-06-30
- **Creation** Initialized the OKF knowledge bundle.
```

## Linking rule

Concepts link to each other with **standard Markdown links to `.md` files**. Two
forms are valid:

- **Absolute (bundle-relative):** begins with `/`, e.g. `/references/vector-search.md`.
  Stable when notes move — prefer this for cross-directory links.
- **Relative:** standard relative path, e.g. `../references/metrics.md`.

A link asserts an untyped relationship; surrounding prose conveys the meaning.
Broken links are tolerated — a missing target never invalidates the bundle.

## Conformance self-check

Run this after every ingestion. The bundle conforms to OKF v0.1 when:

1. Every non-reserved `.md` file has a parseable YAML frontmatter block.
2. Every such block has a non-empty `type`.
3. `index.md` files carry no frontmatter and list children as Markdown links.
4. `log.md`, if present, uses `YYYY-MM-DD` headings, newest first.
5. Concept links are Markdown links to `.md` files, not `[[wikilinks]]`.

Everything else is soft: missing optional fields, unknown `type` values, custom
frontmatter keys, and broken links are all allowed.

## Obsidian reconciliation

OKF and Obsidian coexist cleanly — no either/or:

- **Frontmatter is native.** Obsidian renders YAML frontmatter as *Properties*;
  `tags:` as a list (no leading `#`) is exactly what Obsidian expects.
- **Markdown links render in the graph view** and `obsidian move` rewrites them,
  so OKF's canonical Markdown links keep backlinks and the graph intact.
- **Wikilinks stay optional.** `[[note]]` is an Obsidian convenience that OKF
  consumers cannot parse. Prefer Markdown links for portability; if a user insists
  on wikilinks, treat them as Obsidian-only sugar layered on top of the canonical
  Markdown link, not a replacement.
- **`timestamp` maps onto Obsidian dates.** Use the single OKF `timestamp` key; if
  a vault already uses `created`/`updated`, keep `timestamp` as the OKF-canonical
  field and let the others coexist as extension keys.
