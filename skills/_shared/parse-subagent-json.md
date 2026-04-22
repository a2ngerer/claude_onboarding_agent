# Parse Subagent JSON Protocol

> Consumed by `skills/onboarding/SKILL.md`, `skills/checkup/SKILL.md`, and `skills/upgrade-setup/SKILL.md` wherever they dispatch a plugin subagent. Do not invoke directly.

Every plugin-owned subagent (`repo-scanner`, `upgrade-planner`, `artifact-verifier`, `audit-collector`) returns one fenced ```json block with a uniform envelope. This helper defines the single parse-and-validate procedure. Consumer skills call it instead of hand-rolling regex / line-split parsing.

## Uniform envelope

Every subagent reply MUST contain exactly one fenced code block tagged `json`. The block contains one JSON object with this top-level shape:

```json
{
  "ok": true,
  "kind": "repo-scan | upgrade-plan | artifact-verify | audit-summary",
  "data": { "...subagent-specific payload..." },
  "notes": ["optional", "list", "of", "advisory", "strings"]
}
```

- `ok` — boolean. `true` on a successful reply from the subagent; `false` when the subagent itself detected a failure it could still report structurally (see each subagent's Failure Mode).
- `kind` — string enum, matches the schema filename stem under `.claude/agents/schemas/<kind>.schema.json`.
- `data` — object whose shape is defined by the per-kind schema.
- `notes` — optional array of strings; advisory remarks, not actionable data.

No prose before or after the fenced block. Only one fenced block per reply.

## Inputs (set by the calling skill before reading this file)

- `agent_reply` — the raw string the Agent tool returned.
- `reply_kind` — one of `repo-scan`, `upgrade-plan`, `artifact-verify`, `audit-summary`. The caller knows which subagent it dispatched, so it knows which kind to expect.
- `schema_path` — relative path to the schema: `.claude/agents/schemas/<reply_kind>.schema.json`.

## Procedure

Execute these steps in order. Stop and return the first failure marker encountered.

### P1 — Locate the fenced JSON block

Scan `agent_reply` for the first line matching ```` ```json ```` (optionally with trailing whitespace), then the following lines up to (but not including) the next line matching ```` ``` ```` on its own.

- If no ```` ```json ```` opener is found, or no matching closer is found, return:

  ```json
  { "ok": false, "reason": "missing_block", "detail": "no ```json fence in reply" }
  ```

- If more than one ```` ```json ```` block is found, use the first one and record `"detail": "multiple json fences — first one used"` in a `notes` field on the successful result (only if steps P2 and P3 succeed).

### P2 — Parse as JSON

Parse the extracted fence body as JSON. On parse failure return:

```json
{ "ok": false, "reason": "parse_failed", "detail": "<parser error message, trimmed to 200 chars>" }
```

### P3 — Validate against the schema

Read the schema file at `schema_path`. Validate the parsed object against it, applying these checks inline (Claude can read the schema body and evaluate):

1. Top-level `ok`, `kind`, `data` keys exist. `ok` is a boolean. `kind` equals `reply_kind`. `data` is an object.
2. Every field listed in the schema's `required` array for `data` is present.
3. Every field with an `enum` in the schema has a value inside the enum.
4. Every field with a declared `type` matches that type (string / integer / boolean / array / object).

Do NOT implement full JSON-Schema semantics — the four checks above are sufficient for every plugin schema. If any check fails return:

```json
{ "ok": false, "reason": "validation_failed", "detail": "<field path> — <what failed>" }
```

### P4 — Return the parsed object

On success, return the parsed object unchanged. The caller reads `parsed.data.<field>` to get the values it needs.

## Output contract

- On success: the parsed object (the same JSON the subagent emitted). The caller uses `result.data.*` to read subagent-specific fields.
- On failure: a structured failure marker with this exact shape:

  ```json
  { "ok": false, "reason": "missing_block | parse_failed | validation_failed", "detail": "<short explanation>" }
  ```

## Consumer obligations

- Callers MUST branch on `result.ok`. On `false`, they execute their own documented fallback — this helper does NOT decide fallback behaviour; it only reports success or failure in a uniform way.
- Callers MUST NOT retry the subagent more than once before falling back. A single retry followed by inline fallback is the standard pattern for every consumer.
- Callers MUST NOT silently coerce a failure marker into a partial success. A failure means the fallback inline path runs.

## Design decision record

- **Uniform envelope** (`ok` / `kind` / `data`) was chosen over per-subagent top-level shapes. Rationale: one parser, one set of failure marker semantics, and consumer skills can switch subagents without reworking their parse logic.
- **Schema-as-assertion** rather than full JSON-Schema evaluation. Rationale: Claude validates inline; no extra dependency; the four checks cover every field the plugin currently cares about.
- **````json` fence** (not ```` ```<kind> ````). Rationale: standard Markdown syntax, recognised by every editor, unambiguous for the extractor.
