---
name: knowledge-base
description: Recommended vault layouts, OKF v0.2 frontmatter patterns, and KB-agent structures for Obsidian-style knowledge bases
last_updated: 2026-08-08
sources:
  - https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md
  - https://cloud.google.com/blog/products/data-analytics/how-the-open-knowledge-format-can-improve-data-sharing
  - https://help.obsidian.md/
  - https://help.obsidian.md/properties
  - https://publish.obsidian.md/hub/01+-+Community+Vaults
version: 3
---

## Vault layout

The plugin's recommended layout separates raw material from curated notes. `raw/` holds ingested source files (articles, PDFs, code, notes); `wiki/` holds the interlinked note graph produced from that raw material. The `wiki/` folder is an **OKF v0.2 bundle** (Google's Open Knowledge Format), so it stays portable across any OKF-aware agent or tool. Extra top-level folders only when justified by scale.

```
vault/
├── raw/           ← drop source material here (ingestion input)
├── wiki/          ← OKF v0.2 bundle (curated, interlinked concept notes)
│   ├── index.md   ← OKF directory listing (reserved; no frontmatter)
│   ├── log.md     ← OKF update history (reserved; optional)
│   └── README.md
├── templates/     ← note templates (optional)
└── .obsidian/     ← vault config, plugins, workspace state
```

## OKF v0.2 conformance

OKF (Open Knowledge Format) is Google Cloud's published standard for the Karpathy LLM-wiki pattern: a directory of Markdown concept files, one concept per file, cross-linked with standard Markdown links. A bundle conforms when:

1. Every non-reserved `.md` file carries a parseable YAML frontmatter block.
2. Every such block has a non-empty `type` (the single required key).
3. Reserved filenames — `index.md` (per-directory listing, no frontmatter) and `log.md` (optional chronological history) — follow their structures when present.

Everything else is soft: missing optional fields, unknown `type` values, custom keys, and broken links never invalidate a bundle. Concepts link with Markdown links (`[Title](note.md)` or bundle-relative `[Title](/folder/note.md)`), **not** `[[wikilinks]]` — OKF consumers cannot parse wikilinks.

## Frontmatter conventions

Notes carry OKF frontmatter in YAML delimited by `---`. Obsidian renders these as native *Properties*, so OKF and Obsidian agree on the same block. OKF requires exactly one key (`type`) and recommends four more.

| Property | OKF status | Type | Purpose |
|---|---|---|---|
| `type` | **Required** | text | Kind of concept (`concept`, `module`, `person`, `reference`, …); free-form string |
| `title` | Recommended | text | Human-readable display name when it differs from the filename |
| `description` | Recommended | text | Single-sentence summary (used for index generation and search previews) |
| `resource` | Recommended | text | URI uniquely identifying the underlying asset (omit for prose notes) |
| `tags` | Recommended | list | Categorization strings (`[graphs, retrieval]`); enables dataview queries |

OKF v0.2 replaced the v0.1 `timestamp` field with a structured `generated: { by, at }` object recording provenance (`generated.at` is the ISO 8601 timestamp); it also moved the old body-level `# Citations` list into an optional frontmatter `sources` list with per-source credibility fields (`author`, `usage_count`, `last_modified`). Both are optional additions, not part of the core recommended set above. Real bundles emit the required/recommended keys in the order `type, resource, title, description, tags`. Producers may add custom keys (e.g. `aliases`, `created`, `updated`); OKF consumers preserve unknown keys. If a vault already uses Obsidian's `created`/`updated`, keep OKF's `generated.at` as the canonical provenance timestamp and let the others coexist as extensions. Reserved Obsidian keys (`aliases`, `tags`, `cssclasses`) keep their typed UI behavior. Dates use ISO 8601; lists may use YAML block or flow syntax.

## Naming conventions

- Kebab-case filenames (`knowledge-graphs.md`), not snake_case or PascalCase. Link- and wikilink-friendly.
- No date prefixes on topical notes — dates go in `generated.at` (or a custom `created`/`updated` key), not the filename.
- Daily notes: `YYYY-MM-DD.md` under a dedicated `daily/` folder only.
- Avoid reserved characters: `:`, `/`, `\`, `?`, `*`, `"`, `<`, `>`, `|`. Obsidian rejects them on write.
- One concept per note — resist multi-topic dumps. Break out subtopics into linked notes.
- `index.md` and `log.md` are reserved OKF filenames — do not use them as topical concept notes.

## Agent patterns

- **Vault keeper** — dispatched subagent owning all vault I/O via the Obsidian CLI. Forbids direct `Edit`/`Write` so links and backlinks stay consistent. Reference: `.claude/agents/obsidian-vault-keeper.md`.
- **Frontmatter validator** — reads notes, enforces OKF conformance (non-empty `type` on every non-reserved note; recommended keys present), reports missing/malformed entries. Read-only, Haiku-class model.
- **Tag normalizer** — scans `tags:` across the vault, flags near-duplicates (`ai`, `AI`, `artificial-intelligence`), proposes a canonical form. Read-only.
- **Ingester** — watches `raw/` for new files, summarizes into `wiki/` concept notes with frontmatter and Markdown backlinks, refreshes `index.md` and `log.md`. Write-capable; dispatched only on explicit user request.

## Recommended layout

**`raw/` + `wiki/` (Karpathy LLM-Wiki pattern, OKF v0.2).** Exactly two top-level folders: `raw/` for ingested material, `wiki/` for the OKF concept-note bundle. Templates and daily notes go into dedicated subfolders (`templates/`, `daily/`) only when they are actually used. Vault ops are routed through the `obsidian-vault-keeper` subagent so the Obsidian CLI owns every write.

## Anti-patterns

- Deeply nested topical folders (`wiki/tech/programming/python/django/models/`) — defeats links, buries notes from the graph view.
- Mixing daily notes with topical notes in one folder — date prefixes pollute the index and the graph.
- Frontmatter type drift — `tags: "one, two"` (string) vs. `tags: [one, two]` (list) across notes breaks dataview queries; a missing or empty `type` breaks OKF conformance.
- Wikilink-only cross-linking — `[[note]]` is invisible to OKF consumers. Use Markdown links; treat wikilinks as optional Obsidian-only sugar.
- Editing vault files with plain `Edit`/`Write` or `mv` — skips Obsidian's link-rewrite logic and silently corrupts backlinks.
- Using the third-party Obsidian MCP for vault I/O — its tool schemas load into every session. Prefer the official CLI plus the vault-keeper subagent.
- Dumping raw source material into `wiki/` — `wiki/` is for curated OKF concept notes only; raw inputs belong in `raw/`.
