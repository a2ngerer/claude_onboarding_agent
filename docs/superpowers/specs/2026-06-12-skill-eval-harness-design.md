# Skill Trigger Eval Harness — Design

Date: 2026-06-12
Status: accepted
Plan: `docs/superpowers/plans/2026-06-12-skill-eval-harness.md`

## Problem

Skill routing in Claude Code is driven entirely by the frontmatter `description:` of each SKILL.md. When a description changes, a new skill with overlapping scope is added, or a model update shifts routing behavior, nothing in this repo detects that `/checkup`-style requests suddenly land in `audit-setup`, or that `research-setup` swallows `academic-writing-setup` traffic. The June 2026 ecosystem audit identified this as the main gap versus the state of the art: `anthropics/skills` measures description trigger rates with should-trigger/should-not-trigger prompt sets, and `wshobson/agents` runs a three-gate PluginEval. This repo has no automated trigger-accuracy signal at all.

## Scope (v1)

- **Description-level trigger evals.** A judge model receives the exact catalog the router sees — skill names plus frontmatter descriptions — and one user message, and picks one skill or `none`.
- **Out of scope for v1:** full-session end-to-end evals, output-quality judging of generated artifacts, Monte Carlo repetition with confidence intervals, and automatic description optimization. See Future Extensions.

This is an approximation of real routing (the live session model also sees conversation context), but it tests the artifact this repo actually owns: the descriptions.

## Fixtures

- Location: `evals/<skill-name>.json`, one file per skill. Every entry in plugin.json `skills[]` must have one (enforced by `scripts/check-consistency.sh`).
- The `evals/` directory lives at the repo root and is not shipped to users (`install.sh` links `skills/*/` only).

Schema:

```json
{
  "skill": "<skill-name>",
  "should_trigger": ["<prompt>", "..."],
  "should_not_trigger": ["<prompt>", "..."]
}
```

Authoring rules:

1. `should_trigger`: at least 5 realistic user messages that must route to exactly this skill and could not legitimately route to any other catalog entry. At least one prompt is non-English (skills detect language at runtime; routing must be language-robust).
2. `should_not_trigger`: at least 3 near-miss prompts from adjacent domains that a sloppy description would wrongly catch — they must route to anything other than this skill (another skill or `none`). Good near-miss types: a neighboring skill's request, a request to USE the domain rather than to SET UP Claude for it, and a generic non-setup question.
3. No prompt may contain the skill's directory name or slash command — that would test string matching, not the description.
4. The `skill` field must equal the filename without `.json`.

## Runner

`scripts/run-skill-evals.sh` — bash + jq, no other dependencies.

- Flags: `--skill <name>` (single suite), `--model <alias-or-id>` (default `haiku`), `--threshold <0..1>` (default `0.90`), `--jobs <n>` (default 4), `--report <file>` (JSON report).
- Backends: the Anthropic Messages API via curl when `ANTHROPIC_API_KEY` is set (CI), otherwise the local `claude` CLI in print mode with `CLAUDE_CODE_SAFE_MODE=1` (clean judging without project context, plugins, or hooks).
- Judge contract: the model replies with exactly one token — a catalog skill name or `none`. Any unparseable reply is normalized to `none`.
- Scoring: a `should_trigger` prompt passes iff the predicted skill equals the fixture's skill; a `should_not_trigger` prompt passes iff it does not.
- Output: a per-skill pass-rate table, a list of every failing prompt with its predicted skill, and an optional JSON report.
- Exit code: 0 iff the overall pass rate is at or above the threshold, otherwise 1.

Default judge model is `haiku`: it is the cheapest tier and a stricter test — a description that routes correctly on haiku will route correctly on stronger session models.

## CI

`.github/workflows/skill-evals.yml` — `workflow_dispatch` (with a model input) plus a weekly cron. Requires the `ANTHROPIC_API_KEY` repository secret. Not run on every PR: each full run is ~160 judged prompts and costs real tokens; the consistency workflow already enforces fixture presence and validity on every PR for free.

## Maintenance integration

- `scripts/check-consistency.sh` verifies for every skill: fixture exists, is valid JSON, `skill` field matches the filename, and minimum prompt counts are met.
- `.claude/hooks/check-dependencies.sh` reminds Claude to revisit `evals/<skill>.json` whenever a SKILL.md is modified.
- CONTRIBUTING.md and the PR template require a fixture for every new skill.

## Future extensions

- Repeat runs per prompt (Monte Carlo) with pass-rate confidence intervals.
- Optional `also_acceptable` alternates for prompts with two legitimate routes.
- A description-optimization loop: hold out 40% of prompts, let a model propose description rewrites, accept only on held-out improvement (the `anthropics/skills` skill-creator pattern).
- Output-quality evals for generated artifacts (CLAUDE.md sections, rules files) — requires its own spec.
