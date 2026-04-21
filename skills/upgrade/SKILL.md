---
name: upgrade
description: Re-apply current best practices to an existing onboarding-agent setup. Detects the original setup, computes per-section diffs against the latest templates, asks for per-change confirmation with a unified-diff preview, backs up everything it will touch, and never touches content outside the plugin's delimited sections. Supports --dry-run.
---

# Upgrade — Selective Best-Practice Refresh

Use this skill to bring an existing setup up to the current plugin's defaults **without destroying user customizations**. It is the non-audit counterpart to `/tipps`:

| Skill     | Read-only | Applies changes | Per-change confirmation | Backup       |
| --------- | --------- | --------------- | ----------------------- | ------------ |
| `/tipps`  | yes       | no              | n/a                     | n/a          |
| `/upgrade`| no        | yes             | yes (y/n/all/skip-rest) | yes          |

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

- If a match is found: set `detected_setup: <setup>`, `detected_skills: [<setup>-setup]` (or `knowledge-base-builder` / `academic-writing-setup` — use the exact directory name under `skills/`), `installed_version: "unknown"`, `meta_source: "marker"`.
- If no match: no detection succeeded. Tell the user:

  > "I could not detect an onboarding-agent setup in this project (no `.claude/onboarding-meta.json` and no `setup=...` marker in CLAUDE.md). Run `/onboarding` first to create one — `/upgrade` will then be able to refresh it without touching your custom content."

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

---

## Pass 2 — Plan the changes

For each skill in `detected_skills`, compute the **canonical current output** of that skill's generated sections. The canonical output is a function of:

- `setup_type` and the structured answers it would produce today (for upgrade, questions are NOT re-asked; the plan uses the *structure* of the generated files, not their context-question-dependent values)
- `current_version`
- Any relevant realtime anchors (see Step 2.3)

The upgrade skill treats every delimited section as a **structural template** — it proposes overwriting the marker body with the latest template but preserves any fields that were filled in from user answers (project stack, citation style, etc.). In practice this means: the LLM running this skill compares the on-disk marker body against the latest template from the relevant setup skill and proposes a structural-only diff. **Answer-derived values (Q1, Q2, …) are kept as-is — only the scaffolding around them changes.**

### Step 2.1 — Enumerate candidate files

For each skill in `detected_skills`, read its `SKILL.md` from the plugin installation (resolved in Step 1.3) and list every file it generates that uses delimited sections. The universal candidates are:

- `./CLAUDE.md`
- `./AGENTS.md` (if the skill generates one)
- `./.gitignore`
- `./.claude/settings.json` (if the skill generates one)
- `./claude_instructions/*.md` (if the skill generates any — data-science, academic-writing)

Skip any candidate file that does not exist on disk. Do not create new files here — Pass 2 is diff-only.

### Step 2.2 — For each candidate file, diff each section

Inside each candidate file, locate every delimited section owned by the onboarding-agent:

**Markdown files** (`CLAUDE.md`, `AGENTS.md`, `claude_instructions/*.md`):

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

### Step 2.3 — Optional anchor-driven checks

If `detected_setup` is one of {coding, data-science, devops, design} AND any of the candidate files contain a string matching a known Claude model-ID pattern, fetch the `claude-models` anchor via `skills/_shared/fetch-anchor.md` (embed the same fallback snapshot used by `/tipps`).

For every deprecated ID found, emit a separate proposed change with `rationale: "Deprecated Claude model ID — replace per claude-models anchor"` and a diff that substitutes the deprecated ID with the current-family equivalent (Opus → current Opus, Sonnet → current Sonnet, Haiku → current Haiku).

If the anchor is unavailable (`anchor_markdown: null`), skip this step silently — do not block the upgrade.

### Step 2.4 — Early exit when nothing to do

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

Compute `timestamp = <YYYYMMDD-HHMMSS>` in local time (single value per invocation — all files in this upgrade share it). Create `./.claude/backups/<timestamp>/` via Bash (`mkdir -p`).

For every unique file in the accepted-changes set, copy the current on-disk content into the backup folder preserving relative paths:

- `./CLAUDE.md` → `./.claude/backups/<timestamp>/CLAUDE.md`
- `./.gitignore` → `./.claude/backups/<timestamp>/.gitignore`
- `./claude_instructions/writing-style.md` → `./.claude/backups/<timestamp>/claude_instructions/writing-style.md`
- `./.claude/settings.json` → `./.claude/backups/<timestamp>/.claude/settings.json`

Use Bash `cp --parents` where available, otherwise `mkdir -p` the parent and `cp` the file.

### Step 4.2 — Apply changes in-place

For each accepted change, rewrite **only the content between the delimiters**. Never touch bytes outside the delimiters.

Concrete rules by file type:

- **Markdown**: locate the marker pair, replace everything between them with the new body. Preserve the marker lines themselves — if the legacy form (no `setup=...` attribute) was present, upgrade the opening marker to the attributed form.
- **`.gitignore`**: locate the `# onboarding-agent: <slug> — start` / `— end` pair, replace the interior lines.
- **`.claude/settings.json`**: parse, compute the new `permissions.allow` set (union of user-owned entries + canonical onboarding-agent-owned entries), update `_onboarding_agent.<slug>.allow_owned`, serialize with 2-space indent. Preserve all other keys and ordering as best the JSON library allows.

If any single file write throws: STOP immediately. Do not attempt to continue. Print:

```
⚠ Write failed for <file>: <error>. Upgrade halted.
   Backup of the pre-upgrade state is at .claude/backups/<timestamp>/
   Files already updated before this failure remain updated — review them against the backup.
```

Do not try to roll back on the fly. The backup folder is the recovery path.

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

Backup folder: <.claude/backups/<timestamp>/ | n/a — nothing applied>

To restore everything to the pre-upgrade state:
  cp -R .claude/backups/<timestamp>/. ./
  (this restores files in-place, overwriting what this upgrade wrote)

Next:
  - Run /tipps to audit the updated setup.
  - Re-run /upgrade any time — it is idempotent and safe to repeat.
```

If `applied_count == 0` (all rejected, or dry-run, or nothing found):

- Do not print a backup folder path.
- Do not print the restore command.
- Still recommend `/tipps`.

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
- `<skill-slug>` is the directory name under `skills/` (e.g. `coding-setup`, `knowledge-base-builder`, `academic-writing-setup`)
- `<name>` identifies the logical section inside the file (e.g. `claude-md`, `workflow`, `guidelines`, `agents-roles`, `settings-allow`). Skills can pick descriptive names; `/upgrade` matches on the triple.

**Backwards compatibility:** the old form without attributes (`<!-- onboarding-agent:start -->`) is still recognized as a legacy marker. On upgrade, the opening tag is rewritten to the attributed form as part of the change.

**Never touch content outside the markers** — this is the load-bearing invariant of the upgrade flow. If a file has no markers at all, the upgrade skill reports that file as "no plugin-owned section found — nothing to upgrade here" and moves on. It does **not** insert new markers retroactively (that is the job of re-running the original setup skill, not the upgrade).
