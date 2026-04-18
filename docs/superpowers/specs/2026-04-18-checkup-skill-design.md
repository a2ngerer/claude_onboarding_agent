# Checkup Skill — Design

**Date:** 2026-04-18
**Status:** Draft
**Related issues:** #1 (`/tipps`), #2 (realtime anchor), #5 (`/upgrade`)

## Purpose

A new skill `checkup` (slash command `/checkup`) that inspects an existing Claude setup and decides whether the user should **rebuild from scratch** or **selectively improve** it — then delegates to the appropriate skill.

`checkup` itself owns only the decision logic. It does not audit (that is `/tipps`), apply changes (that is `/upgrade`), or scaffold new setups (that is `/onboarding`).

## Non-goals

- Auditing configuration files (delegated to `/tipps`).
- Applying fixes or diffs (delegated to `/upgrade`).
- Running a full new onboarding (delegated to `/onboarding`).
- Automated CI tests for skills (not the pattern in this repo).

## Dependencies

- **Blocking:** #1 `/tipps` and #5 `/upgrade` must be implemented first. `checkup` refuses to run without `/tipps`; `improve` verdict requires `/upgrade`.
- **Recommended:** #2 realtime anchor infrastructure. If present, the LLM judgment stage includes current best-practice anchor data; if absent, judgment runs on local signals only.

## Entry Flow

Two entry points, both converging on the same decision flow:

### Standalone — `/checkup`

1. User invokes `/checkup` directly.
2. Skill checks for an existing setup: a `CLAUDE.md` file or a non-empty `.claude/` directory.
3. If none → message: "No existing Claude setup found. Run `/onboarding` to create one." Exit.
4. If present → proceed to Decision Flow.

### Auto-Routing from `/onboarding`

1. `/onboarding` gains a new first step: *Detect existing setup*.
2. If `CLAUDE.md` or `.claude/` is present, `/onboarding` asks the user: "Existing setup detected — should I check it (`/checkup`) or rebuild from scratch?"
3. On "check" → build a handoff context (repo scan results so `checkup` does not re-scan), then delegate to `checkup`.
4. On "rebuild" → continue as `/onboarding --rebuild` (see Flag section).

Both entry points terminate in the same Decision Flow.

## Decision Flow (Hybrid)

### Stage 1 — Hard Gates (deterministic)

Any of these conditions forces a **rebuild** verdict without invoking the LLM judgment stage:

- **No metadata, no delimiters:** No `.claude/onboarding-meta.json` **and** no `<!-- onboarding-agent:start -->` delimiters in `CLAUDE.md`. `/upgrade` has no anchor for selective edits.
- **Setup-type mismatch:** Metadata declares a setup type that clearly contradicts the repo content. Concrete heuristic: for `coding-setup`, fewer than 5 code files *or* code files make up less than 20% of non-hidden files. Equivalent per-type thresholds are pinned down in the implementation plan.
- **Corrupt config:** `CLAUDE.md` or `.claude/settings.json` is not parseable.

If a hard gate fires, skip to Stage 4 with verdict = `rebuild` and the triggering reason.

### Stage 2 — Audit

Invoke `/tipps` internally. Receive the prioritised findings list (HIGH / MEDIUM / LOW).

If `/tipps` is not installed, abort with message: "`/checkup` requires `/tipps` (see issue #1)."

### Stage 3 — LLM Judgment (grey zone)

Provide the following to Claude:

- Findings list from `/tipps`.
- Contents of `.claude/onboarding-meta.json`.
- Anchor data from `docs/anchors/*` (if #2 is implemented and reachable).
- Brief repo context: detected primary language, rough file count, presence of frameworks.

Claude returns a JSON object with the following contract:

```json
{
  "verdict": "rebuild | improve | fine-as-is",
  "rationale": "2-3 sentence explanation"
}
```

Verdict meanings:

- `rebuild` — setup is structurally incompatible with current project state.
- `improve` — setup is salvageable; `/upgrade` can bring it current.
- `fine-as-is` — no meaningful improvements available right now.

### Stage 4 — User Confirmation

Present verdict, rationale, and planned next action. User can:

- Accept (`y`).
- Reject (`n`) → exit without action.
- Override with a different verdict → accepted, reason logged.

An override to `rebuild` always runs `/onboarding --rebuild` (with backup), never a plain `/onboarding` — so an override cannot accidentally overwrite the existing setup without a backup.

### Stage 5 — Delegation

- `rebuild` → invoke `/onboarding --rebuild`.
- `improve` → invoke `/upgrade`.
- `fine-as-is` → print short summary ("Your setup looks current against today's best practices.") and exit.

## Fallback Behaviour

- **`/tipps` missing:** abort (see Stage 2).
- **`/upgrade` missing and verdict is `improve`:** display the `/tipps` findings list inline and let the user apply changes manually. Surface an explicit message that `/upgrade` (issue #5) would automate this.
- **User overrides verdict:** accepted; the override and reason are logged in the skill's summary output.
- **Anchor fetch fails (offline / #2 not implemented):** Stage 3 proceeds without anchor data.

## Artifacts

### New files

- `skills/checkup/SKILL.md` — follows the pattern of existing skills: runtime language detection, handoff-context consumption, graceful degradation, English content.
- `.claude/commands/checkup.md` — slash command entry point.

### Modified files

- `.claude-plugin/plugin.json` — add `checkup` to `skills[]` and `/checkup` to `commands[]`.
- `README.md` — add a row to the "What's Inside" table.
- `skills/onboarding/SKILL.md`:
  - New first step: *Detect existing setup → offer `/checkup`*.
  - Build handoff context and delegate when user accepts.
  - Support a `--rebuild` flag: skip detection, back up the existing setup to `.claude/backups/<timestamp>/`, then run the normal flow. The backup includes `CLAUDE.md`, all plugin-generated artifacts, **and** `.claude/settings.json` and `.claude/settings.local.json` if present — user-modified settings files are never discarded without a copy.

### Out of scope (covered by other issues)

- Writing `.claude/onboarding-meta.json` from `/onboarding` — handled as part of #5.
- Retrofitting delimiter sections in all generated artifacts — handled as part of #5.
- Anchor files and fetch helper — handled as part of #2.

## Manual Test Cases

Documented in the skill for manual verification (no automated tests, matching repo convention):

1. **Fresh repo, no setup:** `/checkup` standalone reports "no setup"; auto-routing shows normal onboarding flow.
2. **Setup with meta-file, matching type, few findings:** verdict `fine-as-is`.
3. **Setup without meta-file and without delimiters:** hard gate → `rebuild`.
4. **Setup type mismatch (e.g. `coding-setup` in a Markdown-only repo):** hard gate → `rebuild`.
5. **Mediocre setup, meta-file present:** LLM judgment → `improve` → delegation to `/upgrade`.
6. **`/tipps` not installed:** abort with clear message.
7. **`/upgrade` not installed, verdict `improve`:** inline findings fallback.
8. **User overrides `fine-as-is` with `rebuild`:** accepted, reason logged.

## Language Rule

All artifacts (SKILL.md, slash command, README updates, code comments) are written in English per repository policy. The skill detects user language at runtime and responds accordingly.
