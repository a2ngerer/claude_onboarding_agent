> Consumed by onboarding/SKILL.md (Step 1b), upgrade-setup/SKILL.md, and checkup/SKILL.md. Do not invoke directly.

# Backup Before Write — Unified Rebuild Backup Helper

This helper is the single source of truth for pre-write backups of onboarding-agent-managed files. Every consumer that mutates plugin-owned artifacts in bulk (full rebuild, selective upgrade, or checkup-triggered rebuild) reads this file and follows the procedure below. The goal is one canonical restore point per invocation, with a timestamp scheme that disambiguates multiple backups per minute from different triggers.

## Inputs (set by the calling skill before reading this file)

- `trigger` — one of:
  - `onboarding-rebuild` — `/onboarding --rebuild` before Step 2 runs.
  - `upgrade` — `/upgrade-setup` before Pass 4 writes anything.
  - `checkup-rebuild` — `/checkup` when verdict is `rebuild` AND the delegation to `/onboarding --rebuild` is NOT available in the installed plugin (fallback path only). See the exclusivity note below.

### Trigger exclusivity (no double backups)

When `/checkup` delegates to `/onboarding --rebuild` successfully, onboarding's Step 1b runs this helper with `trigger: onboarding-rebuild`. Checkup itself does NOT invoke this helper in that case — the onboarding-side backup is the canonical one, and a second call would create a redundant, near-simultaneous backup directory. Checkup only invokes this helper on its documented fallback paths where onboarding's `--rebuild` is unavailable.

## Outputs (returned to the caller)

- `rebuild_backup_path` — the absolute-relative path (`.claude/backups/<timestamp>/`) that was created. Callers print it in their completion summary so the user can locate the restore point.

## Step B1 — Compute the timestamp

Compute `now = YYYYMMDD-HHMMSS` in local time with second precision.

Map `trigger` to `trigger_short`:

| `trigger` | `trigger_short` |
|---|---|
| `onboarding-rebuild` | `onboarding` |
| `upgrade` | `upgrade` |
| `checkup-rebuild` | `checkup` |

Set `timestamp = <now>-<trigger_short>`. Example: `20260422-153045-onboarding`.

The trigger suffix disambiguates two backups that land in the same second (e.g. a user re-runs after a hot fix). Without it, consumers would collide on `.claude/backups/<YYYYMMDD-HHMMSS>/` and the second write would stomp the first.

Use `timestamp` as the single value for this invocation — every path under this backup shares it.

## Step B2 — Create the backup root

Run Bash: `mkdir -p .claude/backups/<timestamp>/`.

If `mkdir` itself fails (e.g. filesystem is read-only), treat this as a backup failure per Step B4 — the target path is the failing path.

## Step B3 — Enumerate and copy the canonical file list

The canonical file list is fixed across all triggers:

- `./CLAUDE.md`
- `./AGENTS.md`
- `./.claude/settings.json`
- `./.claude/settings.local.json` (user-modified — never discard without a copy)
- `./.claude/onboarding-meta.json`
- `./.claude/rules/` (recursive — include every `.md` under it)

For every path above that exists on disk, copy it into `.claude/backups/<timestamp>/` preserving the relative path:

- Prefer `cp --parents` where available (GNU coreutils).
- Otherwise run `mkdir -p "$(dirname <dest>)"` first, then `cp <src> <dest>` for files or `cp -R <src> <dest>` for directories (with parent creation as needed).

Paths that do not exist on disk are silently skipped — not every project has every file.

## Step B4 — Abort-on-failure semantics

If any single copy fails (non-zero exit from `cp`, `mkdir`, or an equivalent step), **stop immediately** before any consumer mutates a project file. Print the standardized warning (exact wording — adapt surrounding phrasing to the detected language, but keep the leading warning character and the path / error interpolation verbatim):

> "⚠ Backup failed for `<path>`: `<error>`. Aborting before any file is touched. Nothing has been modified. Re-run once the cause is fixed, or back up manually and try again."

After printing, return control to the caller with an explicit failure signal. The caller MUST NOT proceed to its next step — onboarding aborts before Step 2, upgrade aborts before Pass 4 writes, checkup aborts before any follow-up delegation. Do not attempt to clean up the partial `.claude/backups/<timestamp>/` directory; leaving it in place helps the user diagnose the cause.

## Step B5 — Return the backup path

On success, return `rebuild_backup_path = .claude/backups/<timestamp>/` to the caller.

The caller stores this value for its completion summary (e.g. onboarding's Step 6 rebuild backup notice, upgrade's Pass 5 restore hint). The printed path must match what this helper actually produced — consumers MUST NOT recompute the timestamp themselves.

## Idempotency and re-runs

This helper is safe to call twice in a row from the same trigger: the second call creates a new directory with a fresh timestamp (different seconds, or the same second with the trigger suffix still disambiguating against any other trigger that ran). Old backups are never pruned by this helper — users prune `.claude/backups/` manually when they no longer need historical restore points.
