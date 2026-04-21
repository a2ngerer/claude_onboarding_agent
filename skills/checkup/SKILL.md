---
name: checkup
description: Decide whether an existing Claude setup should be rebuilt from scratch or selectively improved — then delegate. Routes to /onboarding --rebuild, /upgrade-setup, or a short "fine-as-is" summary. Does not audit, does not apply changes.
---

# Checkup — Rebuild vs Improve Router

This skill owns **one decision**: given an existing Claude setup, should the user **rebuild** it, **improve** it, or leave it **fine-as-is**? It then hands off to the appropriate skill. It does not audit (delegates to `/audit-setup`), does not apply changes (delegates to `/upgrade-setup`), does not scaffold (delegates to `/onboarding`).

The skill is a pure router. The only artifact it writes is an append-only line in `.claude/checkup-log.md` per invocation.

## Language

Detect language from the user's first message in this invocation and respond in it throughout. All file content and log lines stay in English (repo language rule).

## Argument parsing

The invocation may contain `--no-delegate` anywhere in the argument string (as a flag, not a value).

- If present: set `no_delegate: true`. Stages 1–5 run normally, but Stage 6 prints the verdict and exits without invoking `/onboarding`, `/upgrade-setup`, or `/audit-setup` for any follow-up. (Testing aid — does not suppress the Stage 3 `/audit-setup` audit call, which is required for a real verdict.)
- Otherwise: set `no_delegate: false`.

Any other argument is ignored silently (forward compatibility).

---

## Stage 1 — Detect the existing setup

### Step 1.1 — Meta file

Read `./.claude/onboarding-meta.json` if it exists. Expected shape (see `skills/_shared/write-meta.md`):

```json
{
  "setup_type": "coding",
  "skills_used": ["coding-setup"],
  "plugin_version": "1.0.0",
  "installed_at": "2026-04-01T12:00:00Z",
  "upgraded_at": null
}
```

- If the file parses and `setup_type` is a recognized slug (one of: `coding`, `data-science`, `design`, `knowledge-base`, `devops`, `content-creator`, `office`, `research`, `academic-writing`, `web-development`, `graphify`), set:
  - `meta_present: true`
  - `setup_type`, `skills_used`, `installed_version: plugin_version`, `installed_at`
- If the file exists but does not parse as JSON: set `meta_present: false`, `meta_corrupt: true`. (Treated by Stage 2 as a hard gate — rebuild.)
- If the file is absent: set `meta_present: false`.

### Step 1.2 — Delimiter scan (used when meta is absent, via `repo-scanner` subagent)

Only run this if `meta_present: false` AND `meta_corrupt` is not true.

Dispatch a `repo-scanner` subagent (defined in `.claude/agents/repo-scanner.md`) to check whether plugin-owned delimiters exist in the user project.

**Dispatch brief:**

```
Use the Agent tool with:
  subagent_type: repo-scanner
  description: "Check for plugin-owned delimiters in the current project"
  prompt: |
    Scan the project rooted at the current working directory for
    onboarding-agent-owned delimiters. Return your standard
    `repo-scan` fenced block. The caller only needs these fields:
      - existing_claude_md
      - existing_agents_md
      - signals (any string matching "onboarding-agent" or
        "_onboarding_agent" indicates a marker)
Expected output: one `repo-scan` fenced block per the subagent's output contract.
```

Parse the returned report. Set `delimiters_present: true` if `existing_claude_md: true` OR `existing_agents_md: true` AND any signal references `onboarding-agent` / `_onboarding_agent`, otherwise `delimiters_present: false`.

### Fallback (if the subagent fails)

Trigger the fallback when the subagent dispatch errors, returns no `repo-scan` block after one retry, or returns a block with missing fields. On dispatch error, do not retry — fall back immediately. Print:

> "⚠ repo-scanner subagent unavailable — falling back to inline delimiter scan."

Then scan these files if they exist:

- `./CLAUDE.md`
- `./AGENTS.md`
- `./.claude/settings.json` (search for `_onboarding_agent` key)

Look for the regex `<!--\s*onboarding-agent:start` (attributed or legacy form) in the markdown files, and the literal key `"_onboarding_agent"` in the JSON file.

- If at least one marker is found: set `delimiters_present: true`.
- Otherwise: set `delimiters_present: false`.

### Step 1.3 — No setup detected

If `meta_present: false` AND `delimiters_present: false` AND `meta_corrupt` is not true, print (adapt to detected language):

> "No Claude onboarding-agent setup detected in this project. Run `/onboarding` to create one. `/checkup` only makes sense on an existing setup."

Exit without logging.

---

## Stage 2 — Hard gates (deterministic)

Evaluate the gates in order. The **first** gate that fires forces `verdict = rebuild` and short-circuits Stages 3–4 — jump straight to Stage 5 with the triggering reason as `hard_gate_reason`.

### Gate G1 — Corrupt settings.json

If `./.claude/settings.json` exists but fails JSON parse → fire with reason: `"corrupt settings.json — /upgrade-setup cannot safely edit it"`.

### Gate G2 — Corrupt meta file

If `meta_corrupt: true` (from Step 1.1) AND `delimiters_present: false` → fire with reason: `"corrupt .claude/onboarding-meta.json and no delimiters found — no anchor for selective edits"`.

If `meta_corrupt: true` BUT `delimiters_present: true`, do NOT fire G2 — the markers still give `/upgrade-setup` an anchor. The meta file will be rewritten by `/upgrade-setup` later.

### Gate G3 — Plugin version downgrade

If `meta_present: true` AND `installed_version` is a valid semver AND `current_plugin_version` is a valid semver AND `installed_version > current_plugin_version` → fire with reason: `"meta records plugin v<installed_version> but v<current_plugin_version> is running — downgrade scenario, rebuild for consistency"`.

Resolve `current_plugin_version` by reading the plugin's own `plugin.json` in this order:
- `~/.claude/plugins/claude-onboarding-agent/.claude-plugin/plugin.json`
- `./.claude/plugins/claude-onboarding-agent/.claude-plugin/plugin.json`
- `./.claude-plugin/plugin.json` (when running inside the plugin repo)

If none resolve, set `current_plugin_version: "unknown"` and SKIP G3 (cannot compare).

### Gate G4 — Setup-type mismatch

Only run if `meta_present: true`. Compare `setup_type` from meta against a lightweight repo scan (mirrors `onboarding/SKILL.md` Step 2 heuristics):

- `coding` → fewer than 5 files total across `.py`/`.ts`/`.js`/`.go`/`.rs`/`.rb`/`.java`/`.cs` AND no manifest (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `requirements.txt`) → fire.
- `web-development` → no web-framework config (`next.config.*`, `vite.config.*`, `astro.config.*`, `svelte.config.*`, `nuxt.config.*`) AND no framework dep in `package.json` → fire.
- `data-science` → no `.ipynb` files AND no `notebooks/` dir AND no `data/raw/` dir AND no DS deps (`pandas`/`polars`/`numpy`/`scikit-learn`/`torch`/`jax`) in `pyproject.toml` → fire.
- `research` → no `.tex`, `.bib`, `.typ` files → fire.
- `academic-writing` → no `sections/`, no `bib/`, no `main.tex`/`main.typ`, no `.typ` alongside `.bib` → fire.
- `knowledge-base` → no `notes/`, `vault/`, `wiki/`, `obsidian/`, `raw/`, and no sizable markdown corpus (< 5 `.md` files outside the repo root) → fire.
- `office` → no `*.docx`/`*.pptx`/`*.pdf`/`*.xlsx` files → fire.
- `content-creator`, `devops`, `design`, `graphify` → no deterministic content signal; do NOT fire G4 for these types (let Stage 4 judge).

Fire reason format: `"setup_type=<type> but repo content does not match (missing: <short signal list>)"`.

If G4 fires, do NOT offer `--rebuild` without the user first confirming the setup type is actually wrong — the rebuild rationale will be surfaced in Stage 5.

### Short-circuit

If any gate fires, set `verdict: rebuild`, `hard_gate_fired: true`, `rationale: "<gate reason>"`, and jump to Stage 5. Skip Stages 3 and 4 entirely.

---

## Stage 3 — Audit (via `audit-collector` subagent)

### Step 3.1 — Dispatch `audit-collector`

Dispatch an `audit-collector` subagent (defined in `.claude/agents/audit-collector.md`) to run the audit skill and return a compact severity-bucketed summary.

**Dispatch brief:**

```
Use the Agent tool with:
  subagent_type: audit-collector
  description: "Run /audit-setup and summarize findings"
  prompt: |
    Invoke the audit skill named below and return your standard
    `audit-summary` fenced block with severity-bucketed counts.
    audit_skill: audit-setup
    max_top_titles: 3
Expected output: one `audit-summary` fenced block per the subagent's output contract.
```

Parse `total`, `high`, `medium`, `low`, `top_titles`. Store as `audit_findings: { total, high, medium, low, top_titles: [...] }`. Continue to Stage 4.

If the returned block's `top_titles` begins with an `error:` entry (the subagent's documented error signal), treat it as a subagent failure and use the Fallback below.

### Fallback (if the subagent fails)

Trigger the fallback when the subagent dispatch errors, returns no `audit-summary` block after one retry, or signals an error via `top_titles`. On dispatch error, do not retry — fall back immediately. Print:

> "⚠ audit-collector unavailable — running /audit-setup inline."

Then run the inline path as before:

1. Try to invoke the `audit-setup` skill. If it is not installed / not found / not available in this environment, print (adapt to detected language):

   > "`/checkup` requires `/audit-setup`. Install the onboarding-agent plugin (or re-install it) and retry."

   Exit without logging. Do NOT proceed to Stage 4 without findings.

2. Invoke the `audit-setup` skill inline. Capture the findings block it prints. Parse:

   - Count total findings.
   - Severity distribution: `high_count`, `medium_count`, `low_count`.
   - Titles of the top 3 findings (in the sort order `/audit-setup` printed them — HIGH first).

   Store as `audit_findings: { total, high, medium, low, top_titles: [...] }`.

   If `/audit-setup` returns its "nothing to improve" message (no findings at all), set `audit_findings: { total: 0, high: 0, medium: 0, low: 0, top_titles: [] }`.

---

## Stage 4 — LLM judgment (grey zone)

This stage only runs if Stage 2 did not fire a hard gate.

### Step 4.1 — Gather signals

Assemble the inputs:

- `audit_findings` — from Stage 3.
- `meta_age_days` — derived from `installed_at` (or `upgraded_at` if set and later): today's date minus installed/upgraded date, rounded down to days. If meta missing, use `delimiter_only: true` (no age signal).
- `repo_size_bucket` — rough bucket: `tiny` (< 20 non-hidden files), `small` (20–200), `medium` (200–2000), `large` (> 2000). Use Bash `find . -not -path './.*' -type f | wc -l` or equivalent.
- `anchor_deprecated_models` — list of deprecated model IDs referenced anywhere in `CLAUDE.md`, `AGENTS.md`, `.claude/settings.json`. Fetch `claude-models` anchor via `skills/_shared/fetch-anchor.md` with `anchor_name: claude-models` and the same embedded fallback used by `/audit-setup` Pass 5. If the anchor is unreachable (`anchor_markdown: null`), set this to `null` (do not block).
- `setup_type` and `skills_used` from meta (if present).

### Step 4.2 — Derive the verdict

Apply the following judgment (in this priority order — first match wins):

1. **rebuild** if any of:
   - `audit_findings.high >= 3` AND (one of those HIGHs is a structural failure — e.g. "Overly broad tool permissions" plus something at least one of: "Potential secret…", "Deprecated Claude model ID referenced")
   - `setup_type` clearly does not match `repo_signals` from a lightweight re-scan (soft mismatch — Stage 2 catches the hard one)
   - `meta_age_days` > 540 (≈ 18 months — templates will have moved meaningfully)
2. **improve** if any of:
   - `audit_findings.total >= 1` AND not caught by the rebuild branch
   - `anchor_deprecated_models` is a non-empty list (one deprecated ID alone is enough — `/upgrade-setup` can flip it)
3. **fine-as-is** if `audit_findings.total == 0` AND `anchor_deprecated_models` is empty or `null`.

### Step 4.3 — Rationale

Write a 2–3 sentence rationale that cites the **strongest 1–2 signals**. Examples:

- "3 HIGH findings — overly broad permissions, and a deprecated Claude model ID is still referenced in `.claude/settings.json`. `/upgrade-setup` can fix both without touching user-owned config." → `improve`
- "No findings from `/audit-setup`, meta is 12 days old, no deprecated model references. Your setup matches current plugin defaults." → `fine-as-is`
- "Meta records setup_type=coding but the repo has no source files or manifest. The setup no longer matches this project — starting over is faster than patching." → `rebuild`

Set `verdict` and `rationale`.

---

## Stage 5 — Confirmation

Print a compact block (adapt the framing to detected language; keep verdict / command / paths in English):

```
Checkup — Verdict

Verdict: <rebuild | improve | fine-as-is>
Rationale: <rationale>

Delegated command (if accepted):
  - rebuild     → /onboarding --rebuild   (backs up existing setup to .claude/backups/<timestamp>/)
  - improve     → /upgrade-setup          (per-change confirmation, backup, --dry-run available)
  - fine-as-is  → nothing — short summary, no changes

Accept verdict? (a = accept / r = rebuild / i = improve / f = fine / q = quit)
```

Interpret the reply:

- `a` / `accept` / `yes` / `y` → `chosen_verdict = verdict` (accepted).
- `r` → `chosen_verdict = rebuild` (override if verdict was something else).
- `i` → `chosen_verdict = improve`.
- `f` → `chosen_verdict = fine-as-is`.
- `q` / `quit` / `n` / `no` → abort; do not delegate, but still log the run (with `user_chose=quit`).
- Anything else → re-prompt once, then default to `q`.

### Step 5.1 — Override reason

If `chosen_verdict != verdict` (user overrode), prompt:

> "One-line reason for the override (optional — press Enter to skip):"

Accept any reply including an empty one. Normalize to a single line (replace newlines with spaces, collapse whitespace, cap at 200 chars). Store as `override_reason`.

If verdict was accepted as-is, set `override_reason = ""`.

### Step 5.2 — Log

Append one line to `./.claude/checkup-log.md` (create the file if missing — ensure `./.claude/` exists first via Bash `mkdir -p`). Format (exact, single line, UTF-8):

```
YYYY-MM-DD verdict=<v> user_chose=<v> reason="<override_reason>"
```

Where `YYYY-MM-DD` is today's local date. Always wrap `reason` in double quotes, even when empty (`reason=""`). Escape any internal `"` as `\"`. Never truncate a line across multiple lines.

If the file already has content, ensure the new line starts on a fresh line (prepend a newline only if the file does not already end with one).

---

## Stage 6 — Delegation

If `no_delegate: true`, skip this stage: just print the completion summary (Stage 7) and exit.

Otherwise dispatch according to `chosen_verdict`:

### 6a — `rebuild`

Invoke the `onboarding` skill with the `--rebuild` flag. Onboarding handles backup + re-run.

If `onboarding --rebuild` is not supported in the installed plugin version (detect by reading `skills/onboarding/SKILL.md` for the `--rebuild` keyword; if the skill file is not resolvable, attempt invocation and fall back on failure), fall back to:

1. Print: "`--rebuild` flag not supported by the installed `/onboarding`. Back up your existing setup manually (copy `CLAUDE.md`, `AGENTS.md`, `.claude/settings.json`, `.claude/onboarding-meta.json`, `claude_instructions/` somewhere safe) then run `/onboarding`."
2. Do NOT auto-invoke `/onboarding` — let the user do it after backing up.

### 6b — `improve`

Invoke the `upgrade-setup` skill. Pass no additional arguments (the user can re-run `/upgrade-setup --dry-run` themselves if they want).

If `/upgrade-setup` is not installed (not in the plugin's skills list), fall back:

1. Print the `/audit-setup` findings inline (re-use the block captured in Stage 3 — do not re-run the audit).
2. Print: "`/upgrade-setup` (issue #5) would automate these changes. Until it is installed, apply the fixes manually using the `How to apply` lines above."

### 6c — `fine-as-is`

No delegation. Print a short summary:

```
Your Claude setup looks current.

  Setup type:     <setup_type | unknown>
  Last upgraded:  <upgraded_at | installed_at — never upgraded | unknown>
  Meta path:      .claude/onboarding-meta.json

Run `/audit-setup` any time to re-audit. Run `/checkup` again after a major project change.
```

---

## Stage 7 — Completion summary

Always print this block at the end, regardless of path (skipped only if Stage 1 / Stage 3 aborted):

```
Checkup complete.

Verdict:          <verdict>
Chosen:           <chosen_verdict>
Override reason:  <override_reason or "(none)">
Delegated to:     <"/onboarding --rebuild" | "/upgrade-setup" | "(none — fine-as-is)" | "(none — --no-delegate)">
Log:              .claude/checkup-log.md
Backup:           <".claude/backups/<timestamp>/" when onboarding --rebuild ran | "(n/a)">
```

The `Backup:` path is only meaningful when onboarding with `--rebuild` actually ran and completed — if onboarding is still running when this skill returns, leave it as `"(see /onboarding output)"`.

---

## Manual test cases (from the spec — no automated tests)

1. **Fresh repo, no setup** → Stage 1 Step 1.3 exits with "no setup" message.
2. **Setup with meta, no findings, anchor clean** → verdict `fine-as-is`, Stage 6c.
3. **Setup without meta and without delimiters** → Gate G2 fires → `rebuild`.
4. **Corrupt settings.json** → Gate G1 fires → `rebuild`.
5. **Type mismatch (meta says coding, repo has no code)** → Gate G4 fires → `rebuild`.
6. **Meta present, 3 HIGH findings, one deprecated model ID** → `improve`, delegates to `/upgrade-setup`.
7. **`/audit-setup` not installed** → Stage 3.1 aborts with clear message.
8. **`/upgrade-setup` missing, verdict improve** → Stage 6b prints findings inline and points at issue #5.
9. **User overrides `fine-as-is` with `rebuild`** → override reason prompted; log line records `verdict=fine-as-is user_chose=rebuild reason="..."`.
10. **`/checkup --no-delegate`** → verdict printed, log written, no follow-up invocation.

## Design notes

- No attributed markers are written by this skill — it generates no content, only a log line and a verdict.
- `.claude/checkup-log.md` is append-only and never rotated by this skill; users can prune it manually.
- Verdict is not cached between invocations (deliberate — see issue #8 design notes). Every `/checkup` re-runs `/audit-setup` and re-judges.
