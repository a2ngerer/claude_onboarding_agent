---
name: upgrade-setup
description: Power-user tool — normally invoked via /checkup. Re-apply current best practices to an existing onboarding-agent setup. Detects the original setup, computes per-section diffs against the latest templates, asks for per-change confirmation with a unified-diff preview, backs up everything it will touch, and never touches content outside the plugin's delimited sections. Supports --dry-run.
---

# Upgrade Setup — Selective Best-Practice Refresh

> **Power-user / internal tool.** Normal users run `/checkup`, which decides whether `/upgrade-setup` is the right action and invokes it automatically. Running `/upgrade-setup` directly still works — use it when you already know you want to re-apply current best practices.

Use this skill to bring an existing setup up to the current plugin's defaults **without destroying user customizations**. It is the non-audit counterpart to `/audit-setup`:

| Skill           | Read-only | Applies changes | Per-change confirmation | Backup       |
| --------------- | --------- | --------------- | ----------------------- | ------------ |
| `/audit-setup`  | yes       | no              | n/a                     | n/a          |
| `/upgrade-setup`| no        | yes             | yes (y/n/all/skip-rest) | yes          |

This skill is a protocol. Run every pass in order. Do not skip passes, and do not apply changes before Pass 3 confirms each one.

## Language

Detect language from the user's first message in this invocation and respond in it throughout. All file content written to disk stays in English (see the repo language rule in CLAUDE.md).

## Argument parsing

The invocation may contain `--dry-run` anywhere in the argument string (as a flag, not a value).

- If present: set `dry_run: true`. Pass 4 prints every diff but writes no files.
- Otherwise: set `dry_run: false`. Pass 4 runs normally.

If any other argument is passed, ignore it silently (forward compatibility — do not error).

---

## Pass 1 — Detect the existing setup

### Step 1.1 — Read the meta file

Read `./.claude/onboarding-meta.json` if it exists. Expected shape:

```json
{
  "setup_type": "coding",
  "skills_used": ["coding-setup"],
  "plugin_version": "0.9.0",
  "installed_at": "2026-04-01T12:00:00Z",
  "upgraded_at": null
}
```

If the file parses and `setup_type` is a recognized slug (one of: `coding`, `data-science`, `design`, `knowledge-base`, `devops`, `content-creator`, `office`, `research`, `academic-writing`), set:

- `detected_setup: <setup_type>`
- `detected_skills: <skills_used>`
- `installed_version: <plugin_version>`
- `meta_source: "meta-file"`

Go to Step 1.3.

### Step 1.2 — Fallback: scan CLAUDE.md for a marker

If no meta file (or malformed), read `./CLAUDE.md`. Search for the first line matching the regex:

```
<!--\s*onboarding-agent:start\s+setup=(?<setup>[a-z-]+)
```

- If a match is found: set `detected_setup: <setup>`, `detected_skills: [<setup>-setup]` (or `knowledge-base-setup` / `academic-writing-setup` — use the exact directory name under `skills/`), `installed_version: "unknown"`, `meta_source: "marker"`.
- If no match: no detection succeeded. Tell the user:

  > "I could not detect an onboarding-agent setup in this project (no `.claude/onboarding-meta.json` and no `setup=...` marker in CLAUDE.md). Run `/onboarding` first to create one — `/upgrade-setup` will then be able to refresh it without touching your custom content."

  Stop the skill. Do not modify anything.

### Step 1.3 — Read the current plugin version

Locate this plugin's `plugin.json`. In most environments the plugin is installed at `~/.claude/plugins/claude-onboarding-agent/.claude-plugin/plugin.json` (global) or `.claude/plugins/claude-onboarding-agent/.claude-plugin/plugin.json` (project-local). Try both, then fall back to the repo root if this skill is being run from inside the plugin repo itself (`./.claude-plugin/plugin.json`).

Parse the top-level `version` field → `current_version`.

If none of the paths resolve: set `current_version: "unknown"` and continue — upgrading still works, the version only affects the meta file.

### Step 1.4 — Announce findings

Print one compact block (adapt to detected language):

```
Detected setup:
  Type:            <detected_setup>
  Skills:          <detected_skills joined with ", ">
  Installed:       <installed_version>  (source: <meta_source>)
  Plugin current:  <current_version>
  Mode:            <"dry-run (no changes will be written)" if dry_run else "live (changes require per-item confirmation)">
```

### Step 1.5 — Legacy Layout Check

Before diffing or previewing upgrade changes, check for legacy rule-file layouts:

1. Read `skills/_shared/migrate-claude-instructions.md` and follow its **Detection** section.
2. If detection triggers, run the full migration procedure from the helper (Preview → user decision → Execution). The migration preview and the upgrade preview are separate — show the migration preview first and let the user decide, then proceed.
3. After the migration step completes, resume the normal upgrade flow. The rest of the upgrade diff will already reflect the post-migration layout.

---

## Pass 2 — Plan the changes

### Anchor responsibilities

`/upgrade-setup` does **not** write anchor-derived marker sections. Writing those sections is the sole responsibility of `/anchors`. During Pass 2, anchor-derived markers (`section=anchor-<slug>`) are detected but never added to `proposed_changes`, never diffed against fresh anchor content, and never rewritten in Pass 4. Pass 5 points the user at `/anchors` when any such markers exist on disk, so the two commands stay complementary: `/upgrade-setup` refreshes plugin-template-derived sections, `/anchors` refreshes anchor-derived sections.

For each skill in `detected_skills`, compute the **canonical current output** of that skill's generated sections. The canonical output is a function of:

- `setup_type` and the structured answers it would produce today (for upgrade, questions are NOT re-asked; the plan uses the *structure* of the generated files, not their context-question-dependent values)
- `current_version`

The upgrade skill treats every delimited section as a **structural template** — it proposes overwriting the marker body with the latest template but preserves any fields that were filled in from user answers (project stack, citation style, etc.). In practice this means: the LLM running this skill compares the on-disk marker body against the latest template from the relevant setup skill and proposes a structural-only diff. **Answer-derived values (Q1, Q2, …) are kept as-is — only the scaffolding around them changes.**

### Step 2.1 — Enumerate candidate files (via `repo-scanner` subagent)

Dispatch a `repo-scanner` subagent (defined in `.claude/agents/repo-scanner.md`) to enumerate, on disk, the universal candidate files that might carry plugin-owned delimited sections. The orchestrator stays out of the raw filesystem — it only needs the existence flags.

**Dispatch brief:**

```
Use the Agent tool with:
  subagent_type: repo-scanner
  description: "Enumerate candidate files for upgrade diffing"
  prompt: |
    Scan the project rooted at the current working directory.
    Return your standard JSON envelope (kind: "repo-scan"). The
    caller only needs these fields inside `data`:
      - existing_claude_md
      - existing_agents_md
      - signals (any string matching a candidate file path)
Expected output: one fenced ```json block per the subagent's output contract.
```

Parse the reply via `skills/_shared/parse-subagent-json.md` with `reply_kind: "repo-scan"` and `schema_path: ".claude/agents/schemas/repo-scan.schema.json"`. On success (`result.ok: true`), use `result.data.existing_claude_md`, `result.data.existing_agents_md`, and `result.data.signals` as the "scan report" below. On failure, jump to the Fallback subsection.

For each skill in `detected_skills`, read its `SKILL.md` from the plugin installation (resolved in Step 1.3) and cross-reference against the scan report to build the candidate list. The universal candidates are:

- `./CLAUDE.md`
- `./AGENTS.md` (if the skill generates one)
- `./.gitignore`
- `./.claude/settings.json` (if the skill generates one)
- `./.claude/rules/*.md` (if the skill generates any — data-science, academic-writing, web-development, knowledge-base-builder)

Skip any candidate file that the scan report indicates does not exist. Do not create new files here — Pass 2 is diff-only.

### Fallback (if the subagent fails)

Trigger the fallback when the shared parser returns a failure marker (`ok: false` with any `reason`) after one retry, or when the Agent tool itself errors. On dispatch error, do not retry — fall back immediately. Print:

> "⚠ repo-scanner subagent unavailable — enumerating candidate files inline."

Then enumerate inline exactly as above, but resolve file existence with direct filesystem checks (Glob / `test -f`) instead of via the scan report. The universal candidate list is identical — only the existence probe changes.

### Step 2.2 — For each candidate file, diff each section

Inside each candidate file, locate every delimited section owned by the onboarding-agent:

**Markdown files** (`CLAUDE.md`, `AGENTS.md`, `.claude/rules/*.md`):

```
<!-- onboarding-agent:start setup=<type> skill=<slug> section=<name> -->
...body...
<!-- onboarding-agent:end -->
```

Legacy form (no attributes) is also recognized for backwards compatibility:

```
<!-- onboarding-agent:start -->
...body...
<!-- onboarding-agent:end -->
```

**`.gitignore`**:

```
# onboarding-agent: <slug> — start
...
# onboarding-agent: <slug> — end
```

**`.claude/settings.json`**: no inline comments allowed. Use the side-channel:

```json
{
  "permissions": { "allow": ["..."] },
  "_onboarding_agent": {
    "<slug>": { "allow_owned": ["Bash(git *)", "..."] }
  }
}
```

The `allow_owned` list is the set of entries the onboarding-agent controls. On upgrade, entries listed in `allow_owned` that have drifted from the canonical set are proposed for update; any entry in `permissions.allow` that is NOT in `allow_owned` is **the user's own addition and must not be proposed for removal**.

For each located section, compute a unified diff against the canonical current template with 3 lines of context. If the diff is empty → skip (no change). If non-empty → add to `proposed_changes` as `{ change_id, setup_type, file, section, rationale, diff }`.

#### Anchor-derived sections

Marker sections whose `section=` attribute starts with `anchor-` are **anchor-derived**, not plugin-template-derived. `/upgrade-setup` does **not** rewrite these sections — writing anchor-derived marker bodies is the sole responsibility of `/anchors` (see the "Anchor responsibilities" note at the top of Pass 2).

Detection-only behavior during Pass 2:

1. Locate every marker whose `section=` attribute starts with `anchor-` inside the candidate files.
2. Do **not** fetch anchors, do **not** render excerpts, and do **not** add these markers to `proposed_changes`.
3. Record the count of anchor-derived markers found (`anchor_marker_count`) for the Pass 5 hand-off.

If `anchor_marker_count > 0`, Pass 5 will recommend `/anchors` as the follow-up command that actually refreshes those sections. This keeps the ownership boundary clear: `/upgrade-setup` touches template-derived sections only, and `/anchors` owns every anchor-derived write.

### Step 2.3 — (Removed)

Anchor-driven checks (deprecated model IDs and similar) now live in `/tipps` Pass 5. Anchor section refreshes are handled by `/anchors`, not by this skill — see the "Anchor responsibilities" note at the top of Pass 2. Nothing to do here.

### Step 2.4 — Project-Local Subagents

The plugin owns these subagent filenames under `.claude/agents/`:

| Slug | Owning Skill |
|---|---|
| `code-reviewer` | coding-setup |
| `component-auditor` | web-development-setup |
| `notebook-auditor` | data-science-setup |
| `writing-style-auditor` | academic-writing-setup |
| `obsidian-vault-keeper` | knowledge-base-builder |

Detection and preview rules:

- Read `./.claude/onboarding-meta.json` and collect `subagents_installed[]`. Cross-check against `.claude/agents/` on disk.
- For each slug in the catalog whose owning skill appears in `detected_skills`:
  - If the subagent file exists on disk: report it as "present — plugin-owned, not diffed (subagent bodies are user-editable after first install; re-install only via `/checkup --rebuild`)".
  - If the subagent file is missing but the owning skill ran AND the current plugin version introduces the slug as part of a new rollout: include it in the dry-run preview as a new file the user can opt into. This is the only path where `/upgrade-setup` emits a subagent; it never overwrites an existing one.
- Any file in `.claude/agents/` not on the catalog is user-authored and never touched.
- Subagent files are NOT added to `proposed_changes` for Pass 3 diff review — the opt-in happens as a single yes/no near the end of the preview. A "yes" dispatches the owning skill's emit step via `skills/_shared/emit-subagent.md` (which still honors collision-skip if the file appeared between preview and apply).

### Step 2.4b — Hook entries (`.claude/settings.json`)

For every skill in `detected_skills` that emits hooks (see catalog in `docs/superpowers/specs/2026-04-21-end-user-hooks-rollout-design.md`):

1. Read `./.claude/settings.json`. If missing or corrupt: flag the hook-refresh as unavailable for this skill and continue — do not block other refresh work.
2. Enumerate every entry in `settings.hooks.*[].hooks[]` where `_plugin == "claude-onboarding-agent"` AND `_skill == <detected_skill_slug>`. These are the plugin-owned entries for this skill.
3. Compare against the current canonical hook-entries list from the skill's hook catalog. Produce a unified diff at the JSON-object level (add / modify / remove per entry).
4. Add the diff as a per-section item in the Pass 3 confirmation list, next to CLAUDE.md and `.gitignore` items. The user can accept / skip it per section like any other refresh.

Hook entries without the `_plugin` marker are considered user-authored and are never diffed or rewritten.

### Step 2.5 — Early exit when nothing to do

If `proposed_changes` is empty, print:

```
Nothing to upgrade — your onboarding-agent sections already match plugin <current_version>.
```

Still update `.claude/onboarding-meta.json` with a fresh `upgraded_at` timestamp and `plugin_version: current_version` (unless `dry_run`), then stop.

---

## Pass 3 — Confirm each change

Print a one-line header:

```
Found <N> change(s) to review. Answer y / n / all / skip-rest for each.
```

For each entry in `proposed_changes` (stable order: by file path, then by section name):

```
[<change_id>] <setup_type> · <file> · <section>
Why: <rationale>

<unified diff with 3 lines of context>

apply? (y/n/all/skip-rest)
```

Interpret the user's reply:

- `y` / `yes` → mark this change `accepted: true`
- `n` / `no` → mark this change `accepted: false`
- `all` → mark this AND all remaining `accepted: true` without further prompting
- `skip-rest` / `skip rest` → mark this AND all remaining `accepted: false`; stop prompting
- any other reply → re-prompt the same change once, then default to `n` if still ambiguous

After the loop, print a one-line summary:

```
Accepted: <A> · Skipped: <S> · Total: <N>
```

If `A == 0`, stop here. Do not create a backup for a no-op. Skip Pass 4. Go to Pass 5.

---

## Pass 4 — Backup and apply

**If `dry_run: true`, skip this pass entirely.** Print: `Dry-run mode — no files written.` and go to Pass 5.

### Step 4.1 — Create the backup folder

Delegate to the shared helper: read `skills/_shared/backup-before-write.md` and follow it with `trigger: upgrade`. Capture the returned `rebuild_backup_path` (e.g. `.claude/backups/<timestamp>-upgrade/`) — every reference to `.claude/backups/<timestamp>/` in the rest of this pass and in Pass 5 resolves to that value.

The helper copies the canonical file list (`CLAUDE.md`, `AGENTS.md`, `.claude/settings.json`, `.claude/settings.local.json`, `.claude/onboarding-meta.json`, `.claude/rules/**`), which is a superset of the files this upgrade touches. Do not re-enumerate the accepted-changes set here — backing up the full canonical set is cheap and guarantees the restore point matches what onboarding and checkup produce.

If the helper signals failure, it has already printed the standardized warning. Stop immediately; do not proceed to Step 4.2. No file is written in this upgrade.

### Step 4.2 — Apply changes in-place

For each accepted change, rewrite **only the content between the delimiters**. Never touch bytes outside the delimiters.

Concrete rules by file type:

- **Markdown**: locate the marker pair, replace everything between them with the new body. Preserve the marker lines themselves — if the legacy form (no `setup=...` attribute) was present, upgrade the opening marker to the attributed form.
- **`.gitignore`**: locate the `# onboarding-agent: <slug> — start` / `— end` pair, replace the interior lines.
- **`.claude/settings.json`**: parse, compute the new `permissions.allow` set (union of user-owned entries + canonical onboarding-agent-owned entries), update `_onboarding_agent.<slug>.allow_owned`, serialize with 2-space indent. Preserve all other keys and ordering as best the JSON library allows.

If any single file write throws: STOP immediately. Do not attempt to continue. Print:

```
⚠ Write failed for <file>: <error>. Upgrade halted.
   Backup of the pre-upgrade state is at <rebuild_backup_path>
   Files already updated before this failure remain updated — review them against the backup.
```

Do not try to roll back on the fly. The backup folder is the recovery path.

### Step 4.2b — Applying hook-entry refreshes

If the user accepted the hook-entry refresh in Pass 3:

1. Follow `skills/_shared/emit-hook.md` Steps H2–H6 with `skill_slug = <detected_skill_slug>` and `hook_entries` = the canonical list computed in Pass 2. The helper rewrites only entries whose `_plugin == "claude-onboarding-agent"` AND `_skill == <detected_skill_slug>`.
2. The helper's remove-then-append procedure gives idempotent refresh without touching user-authored entries.
3. Record the outcome in the Pass 5 summary.

If rejected: leave the file untouched.

### Step 4.3 — Update the meta file

Read `./.claude/onboarding-meta.json` (create if missing). Update:

- `plugin_version`: `current_version`
- `upgraded_at`: ISO-8601 UTC timestamp (`YYYY-MM-DDTHH:MM:SSZ`)
- Leave `setup_type`, `skills_used`, `installed_at` untouched.

Write back with 2-space indent.

---

## Pass 5 — Summary

Print (adapt to detected language, keep technical fields in English):

```
✓ Upgrade <complete | dry-run complete>

Summary:
  Applied:      <applied_count>
  Skipped:      <skipped_count>
  Dry-run only: <dryrun_count>   (zero in live mode)

Backup folder: <<rebuild_backup_path> | n/a — nothing applied>

To restore everything to the pre-upgrade state:
  cp -R <rebuild_backup_path>. ./
  (this restores files in-place, overwriting what this upgrade wrote)

Next:
  - Run /checkup in a few weeks to see what drifted.
  - Re-run /upgrade-setup any time — it is idempotent and safe to repeat.
  - If <anchor_marker_count> > 0: run /anchors to refresh the <anchor_marker_count> anchor-derived section(s) — /upgrade-setup does not touch those.
```

If `applied_count == 0` (all rejected, or dry-run, or nothing found):

- Do not print a backup folder path.
- Do not print the restore command.
- Still recommend `/checkup`.
- Still recommend `/anchors` if `anchor_marker_count > 0`.

---

## Design notes for marker handling (reference)

**Canonical marker format** (emitted by all setup skills going forward):

```markdown
<!-- onboarding-agent:start setup=<setup-slug> skill=<skill-slug> section=<name> -->
...generated body — owned by the plugin, safe to rewrite on upgrade...
<!-- onboarding-agent:end -->
```

Where:

- `<setup-slug>` ∈ {coding, data-science, design, knowledge-base, devops, content-creator, office, research, academic-writing}
- `<skill-slug>` is the directory name under `skills/` (e.g. `coding-setup`, `knowledge-base-setup`, `academic-writing-setup`)
- `<name>` identifies the logical section inside the file (e.g. `claude-md`, `workflow`, `guidelines`, `agents-roles`, `settings-allow`). Skills can pick descriptive names; `/upgrade-setup` matches on the triple.

**Backwards compatibility:** the old form without attributes (`<!-- onboarding-agent:start -->`) is still recognized as a legacy marker. On upgrade, the opening tag is rewritten to the attributed form as part of the change.

**Never touch content outside the markers** — this is the load-bearing invariant of the upgrade flow. If a file has no markers at all, the upgrade skill reports that file as "no plugin-owned section found — nothing to upgrade here" and moves on. It does **not** insert new markers retroactively (that is the job of re-running the original setup skill, not the upgrade).
