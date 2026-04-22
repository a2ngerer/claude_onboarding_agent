# content-voice-setup — Narrowing and Rename

- **Date:** 2026-04-22
- **Status:** Accepted
- **Related issue:** #32
- **Decision:** Option A — narrow the skill to voice-only guidance and rename it from `content-creator-setup` to `content-voice-setup`.

## Context

`content-creator-setup` previously advertised itself as a workflow setup for "creating content." In practice its three questions only produced brand-voice, platform-preference, and audience context — everything else a creator actually needs (publishing cadence, analytics, thumbnails, media production, monetization, platform-specific APIs) was out of scope. The advertised surface was wider than the delivered surface.

Users taking the skill at face value went in expecting a content-production workflow and came out with a CLAUDE.md block that only shaped writing style. That mismatch is the same failure mode `office-setup` had before #31's refocus.

## Decision

Narrow the skill's advertised scope to match what it actually does, and rename the slug to signal that narrower shape:

- `content-creator-setup` → `content-voice-setup`
- Frontmatter description and user-facing intro explicitly limit scope to voice and audience guidance for writing-oriented creator work.
- Publishing, analytics, thumbnails, platform APIs, media production, and monetization are explicitly out of scope and named as such.

Per-platform rule-file emission (following the `academic-writing-setup` + `writing-style-auditor` pattern) makes the narrow scope concrete: Q1 is multi-select across `{YouTube, shortform, newsletter, podcast}`, and each selected platform gets its own `.claude/rules/<platform>.md` with format rules, tone guidelines, and do-not sections. The `brand_voice` (Q2) and `target_audience` (Q3) answers are injected into every emitted rule file.

## Rationale

1. **Advertised surface matches delivered surface.** The old name overpromised; the new name tells the user exactly what they will get.
2. **Per-platform rule files are an idiomatic fit.** Writing for YouTube is not writing for a newsletter. Splitting guidance across named rule files lets subagents or future audits target the correct platform without ambiguity.
3. **Consistent with the project's topic-exclusivity rule.** Each rule-file filename is owned by exactly one skill; `.claude/rules/youtube.md` etc. belong to this skill only.
4. **Parallel to #31's office-setup refocus.** Same pattern: advertised scope was broader than the delivered scope, so we narrowed the advertised scope rather than expanding the skill.

## Migration

- Users who previously ran `/content-creator-setup` have `setup_type: content-creator` in their `onboarding-meta.json`. That slug is legacy. `/upgrade-setup` and `/checkup` do not rewrite it — they read it for compatibility but do not emit it for new runs. New runs write `setup_type: content-voice`.
- Anchor mapping, schemas, helper enums, and the repo-scanner enum all migrate to `content-voice`.
- Historical specs and plans (dated before 2026-04-22) retain the old slug as a frozen record of what was true at that time.

## Acceptance criteria

1. The skill directory and slug are renamed everywhere in live infrastructure:
   - `skills/content-voice-setup/SKILL.md`
   - `.claude-plugin/plugin.json` (skill path + command entry)
   - `docs/schemas/handoff-context.schema.json` `inferred_use_case` enum
   - `.claude/agents/schemas/repo-scan.schema.json` `inferred_use_case` enum
   - `.claude/agents/repo-scanner.md` use-case list
   - `skills/_shared/anchor-mapping.md` row
   - `skills/_shared/write-meta.md` `setup_slug` enum
   - `skills/onboarding/SKILL.md` Step 3 / Step 4 / Step 5 / routing JSON
   - `skills/upgrade-setup/SKILL.md`, `skills/checkup/SKILL.md`, `skills/anchors/SKILL.md`
   - `.claude/hooks/check-dependencies.sh`
   - `README.md` What's Inside table (both rows)
2. The skill's frontmatter `description:` names publishing / analytics / media production as explicitly out of scope.
3. Q1 is multi-select across `{YouTube, shortform, newsletter, podcast}`, stored as `selected_platforms`.
4. For each selected platform, `.claude/rules/<platform>.md` is emitted with Format / Tone / Do-not sections, with `[brand_voice]` and `[target_audience]` injected.
5. Collision policy follows the shared rule-extraction rule: skip on existing file, log `Skipped .claude/rules/<name>.md (already exists)`.
6. CLAUDE.md block is slimmed to brand summary + scope statement + pointers to the emitted rule files, with a short shared guidelines section.

## Risks

- **Discoverability drift.** Users searching for "creating content" no longer find this skill by its name. Mitigation: the orchestrator's Step 3 list keeps the human-readable "Creator brand voice" label and Step 4's routing Q still surfaces the skill under content-creation intents.
- **Legacy meta files.** Projects with `setup_type: content-creator` in `onboarding-meta.json` from older runs will not crash; `/upgrade-setup` and `/checkup` tolerate the legacy slug without rewriting it. This is deliberate — rewriting a meta file to a new slug could mask drift in other places.
- **Perception that this is a rename without a scope change.** It is both. The narrowing is load-bearing; the rename exists to prevent the mismatch from recurring under a different owner.
