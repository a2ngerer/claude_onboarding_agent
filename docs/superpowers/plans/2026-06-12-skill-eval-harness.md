# Skill Trigger Eval Harness — Implementation Plan

Date: 2026-06-12
Spec: `docs/superpowers/specs/2026-06-12-skill-eval-harness-design.md`

## Steps

1. **Fixtures** — write `evals/<skill>.json` for all 16 skills (6 should-trigger prompts including one German, 4 should-not-trigger near-misses each). Authored in two parallel batches against the full catalog of frontmatter descriptions.
2. **Runner** — `scripts/run-skill-evals.sh`: catalog extraction from SKILL.md frontmatter, dual backend (Messages API via curl / `claude -p` in safe mode), parallel task execution, per-skill summary table, failure listing, JSON report, threshold gate.
3. **CI** — `.github/workflows/skill-evals.yml`: workflow_dispatch + weekly cron, uploads the JSON report as an artifact. Requires the `ANTHROPIC_API_KEY` secret.
4. **Guards** — extend `scripts/check-consistency.sh` (fixture presence, JSON validity, skill-field match, minimum counts) and `.claude/hooks/check-dependencies.sh` (fixture reminder on SKILL.md edits).
5. **Docs** — README section, CONTRIBUTING new-skill step, PR-template checklist item, CLAUDE.md authoring note.
6. **Baseline** — run the full suite once, record the baseline pass rate in the PR/commit description, fix any fixture bugs surfaced by the run (fixture bugs, not description rewrites — those are a follow-up).
7. **Release** — bump plugin.json to 1.2.0, add the RELEASE-NOTES entry, run consistency checks, commit, push.

## Non-goals in this pass

Description rewrites based on eval results. The harness lands first and produces a baseline; description optimization is a separate change with its own review.
