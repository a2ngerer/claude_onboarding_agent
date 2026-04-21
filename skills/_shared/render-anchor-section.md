# Render-Anchor-Section Protocol

Shared protocol for rendering a curated excerpt of an anchor into a delimited marker section of a user's config file (typically `CLAUDE.md` or `AGENTS.md`). Called by primary setup skills during onboarding and by `/anchors` during refresh.

## Inputs

- `setup_type` — the user's setup slug (e.g. `coding`, `knowledge-base`).
- `skill_slug` — the calling skill's directory name (e.g. `coding-setup`, `anchors`).
- `anchor_slug` — the anchor to render (e.g. `claude-models`).
- `target_file` — absolute or project-relative path (e.g. `./CLAUDE.md`).
- `fallback_content` — an embedded anchor snapshot provided by the caller, passed through to `fetch-anchor.md`.

## Outputs

- `render_result` — one of `rendered`, `placeholder`, `unchanged`, `skipped`.

## Security invariants

- The full raw anchor markdown is NEVER written to the target file. Only the curated excerpt defined in Step R3 below.
- No URLs or code blocks from the anchor body are written without the excerpt-extraction step running first.
- `fetch-anchor.md` security invariants apply unchanged (only the pinned `raw.githubusercontent.com` URL, cache under `~/.claude/cache/anchors/`).

## Protocol Steps

### Step R1 — Fetch the anchor

Call `skills/_shared/fetch-anchor.md` with `anchor_name: <anchor_slug>` and `fallback_content: <fallback_content>`.

- If `anchor_markdown` is non-null → continue to Step R2.
- If `anchor_markdown` is null → set `render_result: placeholder` and skip to Step R4 with the excerpt body:
  ```
  <!-- anchor unavailable at render time — run /anchors to retry -->
  ```

### Step R2 — Parse the anchor body

Split `anchor_markdown` on the first two `---` fences into frontmatter + body. Parse the body into `## <Heading>` sections keyed by heading text.

### Step R3 — Extract the curated excerpt per anchor

Select the excerpt section by anchor slug (exact match required, falling back to a conservative default if the section is missing):

| `anchor_slug` | Primary section to extract | Fallback if missing |
|---|---|---|
| `claude-models` | `## Defaults` | first 20 lines of body |
| `mcp-servers` | `## Recommended` | `## Selection tips` |
| `claude-tools` | `## Recommendations` | `## Memory files` |
| `subagents` | `## Recommendations` | `## When to use a subagent` |
| `knowledge-base` | `## Recommended layout` | `## Vault layout` |

The excerpt is the content between the chosen `## <Heading>` line (exclusive) and the next `## ` line (or end of body). Strip trailing blank lines. If the extracted text exceeds 25 lines, truncate to 25 lines and append `<!-- excerpt truncated — see full anchor in cache -->` as the last line.

### Step R4 — Write the marker section

Construct the section block exactly (replace the three placeholders):

```
<!-- onboarding-agent:start setup=<setup_type> skill=<skill_slug> section=anchor-<anchor_slug> -->
<excerpt body>
<!-- onboarding-agent:end -->
```

Open `<target_file>`:

- If the file does not exist → create it with just the block. Set `render_result: rendered`.
- If the file exists and a section with the same three-attribute signature (`setup=...`, `skill=...`, `section=anchor-<anchor_slug>`) already exists → replace only the body between its start and end markers with the new excerpt body. The start and end marker lines themselves stay. If the resulting body is byte-identical to the prior body → set `render_result: unchanged` and do not rewrite the file. Otherwise set `render_result: rendered`.
- If the file exists but does not contain a matching marker section → append two blank lines then the block at the end of the file. Set `render_result: rendered`.

Never touch bytes outside the marker pair.

### Step R5 — Return

Return `render_result`.

## Notes for callers

- Setup skills call this protocol once per anchor in their mapped list. Each call is independent — if one anchor fetch fails, the others still run.
- `/anchors` uses this protocol only on files that already exist; it does not create `CLAUDE.md` or `AGENTS.md` from scratch. Section 4.3 of the spec is explicit that initial creation is the setup skill's job.
- `fallback_content` must be a plausible-shape markdown anchor (frontmatter + body) so Step R2 can parse it. If omitted, Step R1 may return null, leading to the placeholder path in Step R4.
