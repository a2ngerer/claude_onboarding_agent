# Rules Convention Migration — Design

**Date:** 2026-04-21
**Status:** Draft
**Scope:** Migrate plugin-generated rule files from `claude_instructions/` to the Claude-native `.claude/rules/` namespace, introduce an extraction threshold, and provide an opt-in migration path for existing user setups.

## Motivation

The plugin currently generates rule files into `claude_instructions/` at project root. That folder is a parallel universe to `.claude/` — the official namespace where Claude Code artifacts live (`.claude/settings.json`, `.claude/agents/`, `.claude/commands/`). Consolidating rules under `.claude/rules/` produces a single, consistent location for Claude-related project configuration and aligns the generated output with the conventions an experienced Claude Code user expects.

A secondary goal: reduce CLAUDE.md bloat by extracting rule content into dedicated files, while preventing over-fragmentation through a clear extraction threshold.

## Decision

### Target Convention

- Rules live in `.claude/rules/<topic>.md`.
- CLAUDE.md references them via a plain pointer: `See .claude/rules/<topic>.md for <topic>`.
- `claude_instructions/` is removed from new setups.

### Extraction Threshold

A rule block stays inline in CLAUDE.md if **both** hold:

1. The topic is **not on the extraction whitelist** (below), AND
2. The rule block is **shorter than 25 lines total**.

Otherwise the rules are extracted into `.claude/rules/<topic>.md`.

**Extraction whitelist (always extracted, regardless of length) — aligned with filenames skills currently generate:**

| Filename | Owning Skill | Purpose |
|---|---|---|
| `writing-style.md` | academic-writing-setup | Voice, tense, section rules |
| `citation-rules.md` | academic-writing-setup | `.bib` conventions, no-invented-citations |
| `obsidian-cli.md` | knowledge-base-builder | CLI command reference (read-on-demand) |
| `data-schema.md` | data-science-setup | Datasets, columns, lineage |
| `evaluation-protocol.md` | data-science-setup | Metrics, splits, baselines |
| `api-conventions.md` | web-development-setup | Route layout, error shape, auth |
| `component-structure.md` | web-development-setup | Atomic/container split, colocation |
| `env-vars.md` | web-development-setup | Public-prefix rules, secret stores |

Skill authors MUST NOT extend the whitelist opportunistically — the list is fixed in skill-authoring documentation to prevent drift. Non-whitelisted topics follow the pure line-count rule; no discretionary "might as well extract" exceptions.

**Whitelist-vs-threshold resolution:** If a whitelist filename would contain fewer than 25 lines, it still gets extracted. The whitelist wins over the length threshold. Extraction inverts only for non-whitelist topics.

### CLAUDE.md Pointer Format

Rules section template for generated CLAUDE.md:

```
## Rules
- Writing style: see .claude/rules/writing-style.md
- API conventions: see .claude/rules/api-conventions.md
- <inline short rule, no file reference>
```

Inline rules and file pointers coexist in the same section.

## Plugin File Ownership & Collision Handling

The plugin does **not** own the `.claude/rules/` directory. It owns only the filenames listed in the extraction-whitelist table above. Any file in `.claude/rules/` not on that list is considered user-authored and is never read or modified by the plugin.

**Topic exclusivity:** Each whitelist filename has exactly one owning skill (see the Owning Skill column). No two skills ever write the same filename. If a future skill needs to generate rules on an existing topic, the spec must be updated to either (a) assign the topic to a new owner or (b) introduce a new disambiguated filename (e.g., `data-env-vars.md` alongside `env-vars.md`).

**Write-time collision policy:** When a skill is about to write a whitelist file and the target already exists:

- **Default:** Skip the write. The skill logs `Skipped .claude/rules/<name>.md (already exists)` and continues.
- **Rationale:** Setup-generators run once; overwriting would destroy user edits from subsequent sessions. Prompting would block non-interactive runs. Delimited in-file sections would re-bloat rule files, defeating extraction.
- **Explicit regenerate:** Users who want to regenerate rules invoke `checkup --rebuild` or `upgrade`, which MAY overwrite after an explicit dry-run preview (consistent with the existing `--rebuild` behavior of those skills).

**Edge case: user manually emptied a whitelist file.** The skip policy preserves the empty file. The user's intent is ambiguous — they may want regenerate, or they may want the file to stay empty. Resolution: `checkup --rebuild` is the documented path for regeneration; silent auto-refill is never done.

## Migration Path for Existing Setups

The `checkup` and `upgrade` skills detect the presence of `claude_instructions/` and offer a migration:

1. **Detection:** If `claude_instructions/` exists in the user's project, the skill proposes migration during its normal flow.

2. **Migration scope (whitelist-only):** Only the filenames in the extraction whitelist are migrated. Files in `claude_instructions/` that do not match a whitelist filename are considered user-custom and are left in place. Rationale: the plugin only owns files it generates (see Plugin File Ownership); touching user-custom files would violate that ownership model. This intentionally leaves `claude_instructions/` in place as long as user-custom files remain — the folder is removed only when empty.

3. **Preview (dry-run):** Shows the user:
   - Files that will move from `claude_instructions/<name>.md` to `.claude/rules/<name>.md` (whitelist only)
   - Files that will stay (non-whitelist, flagged as user-custom)
   - Target-file conflicts: if `.claude/rules/<name>.md` already exists, migration skips that file and flags it for manual reconciliation
   - CLAUDE.md pointer rewrites (old path → new path)
   - Removal of the `claude_instructions/` folder only if empty after migration
   - Warning: "External references (e.g., links in external docs or markdown link syntax like `[label](claude_instructions/...)`) to `claude_instructions/` will not be rewritten — verify and update manually."

4. **User decision:**
   - **Confirm:** Migration runs. File-by-file: if the source is tracked by git, `git mv` is used to preserve history; otherwise a plain filesystem move. Mixed-mode (some tracked, some not) is handled per-file, not per-folder. Pointers in CLAUDE.md are rewritten.
   - **Decline:** A marker file `.claude/.migration-declined` is written. No further action.

5. **Marker file location:** The marker lives at `.claude/.migration-declined`. It sits inside `.claude/` because it is a plugin-state artifact (alongside `.claude/onboarding-meta.json`). Placing it inside `.claude/rules/` would conflate it with rule files; placing it at repo root would pollute the project tree.

6. **Re-prompting behavior:** Without the marker file, the prompt re-appears on every `checkup` or `upgrade` invocation. With the marker file, the skill silently skips the prompt. The user can delete the marker to be asked again.

7. **Pointer-rewrite pattern:** Only the exact plugin-generated plaintext form is rewritten: `claude_instructions/<name>.md` → `.claude/rules/<name>.md`, matched as a whole token (not regex on substrings). Markdown link syntax (`[…](claude_instructions/…)`), relative-path variants (`./claude_instructions/`), and any other user-authored reference forms are left untouched and listed in the dry-run output under a "manual review needed" header. Rationale: broader regex risks false positives in user prose; plaintext-exact is deterministic and auditable.

8. **No dual-read fallback:** Once migrated, the plugin does not read from `claude_instructions/`. Users who decline stay on the old path until they explicitly migrate.

`onboarding` (new setups) writes directly to `.claude/rules/` with no legacy-path check.

## Affected Skills

Seven skills reference or generate `claude_instructions/` today and must be updated. They split by role:

**Generators (write whitelist files — must switch target path from `claude_instructions/` to `.claude/rules/`):**

- `web-development-setup` — generates `api-conventions.md`, `component-structure.md`, `env-vars.md`
- `knowledge-base-builder` — generates `obsidian-cli.md`
- `data-science-setup` — generates `data-schema.md`, `evaluation-protocol.md`
- `academic-writing-setup` — generates `writing-style.md`, `citation-rules.md`

**Migration-aware (detect legacy setups and offer migration):**

- `checkup` — detection + migration offer
- `upgrade` — detection + migration offer

**Bootstrap (routing references only, no migration offer):**

- `onboarding` — writes new setups directly to `.claude/rules/`; removes all `claude_instructions/` references from its routing logic

Shared scaffolding in `skills/_shared/*` and `README.md` must be audited for path references and updated.

## Out of Scope

- Semantic restructuring of rule content — this is a location migration only.
- Path-scoped auto-loading (e.g., `paths: ["src/**/*.ts"]`) — not a verified Claude Code feature; explicitly not assumed by this design.
- Retroactive edits to historical spec documents in `docs/superpowers/specs/`.
- AGENTS.md, `.gitignore`, `.claude/settings.json`, and pre-commit hook generation — none reference `claude_instructions/` today.

## Authoring Documentation

To prevent threshold drift, the skill-authoring conventions must be updated with:

- The fixed extraction whitelist (verbatim list above)
- The 25-line threshold rule
- An explicit ban on discretionary whitelist extensions

Location: a dedicated section in this repository's `CLAUDE.md` (under "Skill Authoring Rules"). CLAUDE.md is already the canonical entry point for plugin-development conventions; no new file is introduced.

## Risks & Edge Cases

- **External references break.** Users who link to `claude_instructions/` from external docs, wikis, or blog posts will get broken links after migration. Mitigated by the preview warning; not automatically redirected.
- **Markdown-link references untouched.** User-authored links like `[rules](claude_instructions/foo.md)` are deliberately not rewritten (false-positive risk too high). They appear in the dry-run's manual-review list.
- **Manual CLAUDE.md edits.** Users who have hand-edited CLAUDE.md may have pointers the migration does not recognize (e.g., reformatted pointer lines). Anything outside the exact plaintext pattern is flagged for manual review, not silently skipped.
- **Marker-file drift.** A user who writes `.claude/.migration-declined` and later changes their mind must delete it manually. This is intentional — the marker exists to make declination explicit, not silent.
- **Parallel folders after partial migration.** If `claude_instructions/` contains user-custom files alongside plugin files, the plugin folder is not removed. Users end up with both `claude_instructions/` (custom only) and `.claude/rules/` (plugin). Documented in migration output so it does not look like a broken migration.
- **User-authored shadow file.** If a user manually created `.claude/rules/writing-style.md` with the same name as a plugin whitelist file, the plugin still treats it as plugin-owned by filename. The skip-on-exists policy prevents data loss, but the ownership-by-filename assumption is a known limit — documented, not mitigated in v1.
- **Threshold subjectivity.** The 25-line rule cuts cleanly; the whitelist is the subjective part. Fixing it in authoring docs is the only mitigation — any future additions must go through a spec update, not an ad-hoc skill decision.

## Success Criteria

- **Code-level:** Grep across `skills/` returns zero occurrences of `claude_instructions/` in generator and bootstrap skills (`onboarding`, `web-development-setup`, `knowledge-base-builder`, `data-science-setup`, `academic-writing-setup`). Only `upgrade` and `checkup` retain references, and only for migration detection.
- **Migration detection:** In a test project with `claude_instructions/{writing-style,citation-rules}.md`, invoking `checkup` offers migration; accepting it produces `.claude/rules/{writing-style,citation-rules}.md`, a rewritten CLAUDE.md, and removal of the now-empty source folder.
- **Migration decline:** Declining produces `.claude/.migration-declined`; re-running `checkup` skips the prompt; deleting the marker causes the prompt to reappear.
- **Whitelist-only migration:** In a test project where `claude_instructions/` also contains `my-custom.md`, migration leaves `my-custom.md` in place, migrates only whitelist files, and does not remove the folder.
- **Collision behavior:** Running a setup skill twice on the same project does not overwrite the existing rule file; the skill logs a skip message.
- **Authoring doc:** `CLAUDE.md` of this repository contains the extraction whitelist (table form) and the 25-line threshold rule, both copy-pasteable and verbatim.
