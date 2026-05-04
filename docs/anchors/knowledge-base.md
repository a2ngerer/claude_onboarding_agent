---
name: knowledge-base
description: Recommended vault layouts, frontmatter patterns, and KB-agent structures for Obsidian-style knowledge bases
last_updated: 2026-05-04
sources:
  - https://help.obsidian.md/
  - https://help.obsidian.md/properties
  - https://publish.obsidian.md/hub/01+-+Community+Vaults
version: 2
---

## Vault layout

The plugin's recommended layout separates raw material from curated notes. `raw/` holds ingested source files (articles, PDFs, code, notes); `wiki/` holds the interlinked note graph produced from that raw material. Extra top-level folders only when justified by scale.

```
vault/
├── raw/           ← drop source material here (ingestion input)
├── wiki/          ← curated, interlinked notes (Karpathy LLM-Wiki pattern)
│   └── README.md
├── templates/     ← note templates (optional)
└── .obsidian/     ← vault config, plugins, workspace state
```

## Frontmatter conventions

Obsidian properties live in YAML frontmatter delimited by `---`. Reserved keys have typed behavior in the UI; custom keys are free-form.

| Property | Type | Required | Purpose |
|---|---|---|---|
| `title` | text | No | Display title when it differs from the filename |
| `created` | date | Recommended | ISO-8601 creation timestamp (UTC) |
| `updated` | date | Recommended | ISO-8601 modification timestamp |
| `tags` | list | Recommended | Hierarchical tags (`topic/subtopic`); enables dataview queries |
| `aliases` | list | No | Alternate names that resolve in wikilinks and search |
| `type` | text | Recommended | Custom discriminator (`concept`, `person`, `project`, `daily`) |

Reserved Obsidian keys: `aliases`, `tags`, `cssclasses`. Dates use `YYYY-MM-DD` or ISO-8601 with time; lists may use YAML block or flow syntax.

## Naming conventions

- Kebab-case filenames (`knowledge-graphs.md`), not snake_case or PascalCase. Wikilink-friendly.
- No date prefixes on topical notes — dates go in `created:` frontmatter, not the filename.
- Daily notes: `YYYY-MM-DD.md` under a dedicated `daily/` folder only.
- Avoid reserved characters: `:`, `/`, `\`, `?`, `*`, `"`, `<`, `>`, `|`. Obsidian rejects them on write.
- One concept per note — resist multi-topic dumps. Break out subtopics into linked notes.

## Agent patterns

- **Vault keeper** — dispatched subagent owning all vault I/O via the Obsidian CLI (bundled with the Obsidian installer since v1.12.7; CLI autocompletion available via `id=` parameter). Forbids direct `Edit`/`Write` so wikilinks and backlinks stay consistent. Reference: `.claude/agents/obsidian-vault-keeper.md`.
- **Frontmatter validator** — reads notes, checks required keys (`created`, `updated`, `tags`, `type`), reports missing/malformed entries. Read-only, Haiku-class model.
- **Tag normalizer** — scans `tags:` across the vault, flags near-duplicates (`ai`, `AI`, `artificial-intelligence`), proposes a canonical form. Read-only.
- **Ingester** — watches `raw/` for new files, summarizes into `wiki/` notes with backlinks into related concepts. Write-capable; dispatched only on explicit user request.

## Recommended layout

**`raw/` + `wiki/` (Karpathy LLM-Wiki pattern).** Exactly two top-level folders: `raw/` for ingested material, `wiki/` for curated, interlinked notes. Templates and daily notes go into dedicated subfolders (`templates/`, `daily/`) only when they are actually used. Vault ops are routed through the `obsidian-vault-keeper` subagent so the Obsidian CLI owns every write.

## Anti-patterns

- Deeply nested topical folders (`wiki/tech/programming/python/django/models/`) — defeats wikilinks, buries notes from the graph view.
- Mixing daily notes with topical notes in one folder — date prefixes pollute the index and the graph.
- Frontmatter type drift — `tags: "one, two"` (string) vs. `tags: [one, two]` (list) across notes breaks dataview queries.
- Editing vault files with plain `Edit`/`Write` or `mv` — skips Obsidian's link-rewrite logic and silently corrupts backlinks.
- Using the third-party Obsidian MCP for vault I/O — its tool schemas load into every session. Prefer the official CLI plus the vault-keeper subagent.
- Dumping raw source material into `wiki/` — `wiki/` is for curated notes only; raw inputs belong in `raw/`.
