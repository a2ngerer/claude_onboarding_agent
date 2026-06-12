# Release Notes

## v1.2.1 — 2026-06-12

Skill description sharpening, driven by trigger-eval findings.

- `audit-setup` description now leads with its read-only, report-only nature instead of "normally invoked via /checkup", which steered the eval judge (and users browsing the catalog) to `/checkup`
- `checkup` description no longer mentions running `/audit-setup` internally; it now emphasizes the decide-and-act contract ("checked and fixed, not just a findings report")
- `research-setup` description is scoped to the input side of academic research (literature reviews, paper screening, Zotero reference management, reading notes) and points manuscript drafting to `academic-writing-setup` — removes the overlap that caused flaky routing of literature prompts
- README tables updated to match the new positioning
- Eval fixtures unchanged — descriptions were verified against the existing fixtures per the optimization loop in the eval-harness design doc

## v1.2.0 — 2026-06-12

Skill trigger eval harness.

- Trigger-eval fixtures for all 16 skills under `evals/` (should-trigger and should-not-trigger prompts, including non-English samples)
- `scripts/run-skill-evals.sh`: judges every prompt against the live skill catalog (Anthropic API or local `claude` CLI in safe mode), per-skill pass rates, failure listing, JSON report, threshold gate
- `.github/workflows/skill-evals.yml`: weekly + on-demand eval runs (requires the `ANTHROPIC_API_KEY` secret)
- `scripts/check-consistency.sh` now enforces fixture presence, validity, and minimum prompt counts on every PR
- New-skill checklists (CLAUDE.md, CONTRIBUTING, PR template) require a fixture; the dependents hook reminds about fixtures on SKILL.md edits
- Design: `docs/superpowers/specs/2026-06-12-skill-eval-harness-design.md`

## v1.1.0 — 2026-06-12

June 2026 state-of-the-art refresh.

- Anchors updated to the current Claude model lineup (Fable 5, Opus 4.8)
- Concrete MCP install commands in setup skills
- Consistency fixes across the maintenance chain: `/tipps` phantom references removed, `knowledge-base-builder` rename to `knowledge-base-setup` completed, `web-development` slug recognized by `upgrade-setup`
- Plugin manifest migrated to the current schema: `skills[]` now lists skill directories (`./skills/<name>`), the legacy `commands[]` field is removed (slash commands derive from skill directory names), `displayName` added; `claude plugin validate` passes
- Portable dependency hook: repo root derived from `CLAUDE_PROJECT_DIR`/git instead of a hardcoded absolute path; dead `installation.md` case pattern fixed
- Subagent model tiering: haiku for lightweight read-only agents, sonnet for mid-tier tasks — opus no longer used everywhere
- Self-hosted plugin marketplace: `marketplace.json` added; `/plugin marketplace add a2ngerer/claude_onboarding_agent` now works
- Modernized stack defaults in setup skills: Create React App dropped in favor of Vite/Next.js, Python minimum bumped to 3.12, pre-commit revisions unpinned
- Removed frozen install-count claims from documentation

## v1.0.1 — 2026-04-24

Documentation and maintenance update.

### Improvements
- Aligned release-notes command names with the current plugin command catalog
- Clarified command registry source of truth in `CLAUDE.md`
- Hardened install/uninstall scripts for safer symlink handling on macOS/Linux
- Added a consistency check script and CI workflow to prevent manifest/docs drift
- Expanded contributing guidance for maintenance changes and pre-PR checks

## v1.0.0 — 2026-04-16

Initial release.

### Skills
- `/onboarding` — Orchestrator with repo scanning and path inference
- `/coding-setup` — Coding workflow with Superpowers integration
- `/knowledge-base-setup` — Karpathy-pattern knowledge base builder with Obsidian support
- `/office-setup` — Office and business productivity setup
- `/research-setup` — Academic research and writing setup
- `/content-voice-setup` — Content creation workflow setup
