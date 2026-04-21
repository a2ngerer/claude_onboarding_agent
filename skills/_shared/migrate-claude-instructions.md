# Migrate claude_instructions/ → .claude/rules/

Shared procedure consumed by the `checkup` and `upgrade` skills. When a user project contains a legacy `claude_instructions/` folder, this procedure offers and executes the migration to the `.claude/rules/` convention. Read before offering migration.

## Detection

Check in this order:

1. If `.claude/.migration-declined` exists in the user's project, **silently skip this entire procedure**. The user has already declined.
2. If `claude_instructions/` does not exist as a directory at the project root, skip silently.
3. Otherwise, proceed to Preview.

## Whitelist (plugin-owned filenames)

Only these eight filenames are migrated. Any other file in `claude_instructions/` is considered user-custom and stays in place.

| Filename | Owning Skill |
|---|---|
| `writing-style.md` | academic-writing-setup |
| `citation-rules.md` | academic-writing-setup |
| `obsidian-cli.md` | knowledge-base-builder |
| `data-schema.md` | data-science-setup |
| `evaluation-protocol.md` | data-science-setup |
| `api-conventions.md` | web-development-setup |
| `component-structure.md` | web-development-setup |
| `env-vars.md` | web-development-setup |

## Preview (dry-run)

Before asking the user to confirm, present a block like this (replace the example rows with actual findings):

```
Detected legacy layout: claude_instructions/

Files to migrate to .claude/rules/:
- claude_instructions/writing-style.md → .claude/rules/writing-style.md
- claude_instructions/citation-rules.md → .claude/rules/citation-rules.md

Files to leave in place (not on plugin whitelist):
- claude_instructions/my-custom-notes.md

Target-file conflicts (source stays, manual reconciliation needed):
- .claude/rules/writing-style.md already exists

CLAUDE.md pointer rewrites:
- Line 42: "See claude_instructions/writing-style.md for voice" → ".claude/rules/writing-style.md"

Manual review needed (not auto-rewritten):
- Line 58: markdown link [rules](claude_instructions/writing-style.md)

After migration:
- claude_instructions/ will be removed only if empty.
- External references (wikis, blog posts) to claude_instructions/ will not be rewritten.
```

Then prompt exactly: `Proceed with migration? (yes/no)`

## Execution on "yes"

For **each file** on the whitelist present in `claude_instructions/`:

1. If `.claude/rules/<name>.md` already exists: skip this file and log `Skipped <name>.md (target exists, manual reconciliation needed)`.
2. Ensure the target directory exists: `mkdir -p .claude/rules`.
3. Check if the source is tracked by git:

   ```
   git ls-files --error-unmatch claude_instructions/<name>.md
   ```

   - Exit code `0` (tracked): `git mv claude_instructions/<name>.md .claude/rules/<name>.md`
   - Non-zero (untracked): plain `mv claude_instructions/<name>.md .claude/rules/<name>.md`

   Per-file decision; do not treat the folder as a unit. Mixed tracked/untracked is expected.

For CLAUDE.md pointer rewrites:

1. For each whitelist filename `<name>`, replace every exact-plaintext occurrence of `claude_instructions/<name>.md` with `.claude/rules/<name>.md`.
2. Match as a whole token — do not do substring regex. Example transformation:
   - Before: `See claude_instructions/writing-style.md for voice.`
   - After:  `See .claude/rules/writing-style.md for voice.`
3. Do **not** rewrite markdown link syntax (e.g., `[label](claude_instructions/foo.md)`), `./claude_instructions/` variants, or any other form. These are listed in the preview under "Manual review needed" and stay untouched.

After all files are processed:

1. If `claude_instructions/` is now empty, remove it (`rmdir claude_instructions`).
2. If it still contains files (user-custom leftovers), leave it in place and state that explicitly in the summary.

## Execution on "no"

1. Write marker file: `.claude/.migration-declined` (empty file; content ignored).
2. Tell the user: "Migration declined. Marker written to `.claude/.migration-declined`. Delete it to be asked again."

## Post-migration summary

Report to the user:

- Files migrated (count and list)
- Files left in place (user-custom, count and list)
- CLAUDE.md pointer rewrites applied (count)
- Manual-review items (count and list)
- Final state of `claude_instructions/` (removed / still present with N files)

## Re-prompt behavior

The skill consuming this helper MUST re-offer migration on every invocation as long as `claude_instructions/` exists AND `.claude/.migration-declined` does not exist. A single-session suppression is not enough.
