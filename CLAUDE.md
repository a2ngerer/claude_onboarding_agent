# Claude Onboarding Agent — Development Instructions

## What This Repo Is
A Claude Code plugin with 6 skills. Skills are markdown files in `skills/*/SKILL.md`. The plugin generates configuration files (CLAUDE.md, AGENTS.md, etc.) in users' projects.

## Key Paths
- `skills/` — all 6 skill files (one folder per skill, each with a `SKILL.md`)
- `.claude/commands/` — slash-command entry points
- `.claude-plugin/plugin.json` — plugin manifest (registers skills and commands)
- `scripts/install.sh` — GitHub installation script
- `docs/superpowers/specs/` — design documents
- `docs/superpowers/plans/` — implementation plans

## Adding a New Skill
1. Create `skills/[skill-name]/SKILL.md`
2. Follow the pattern from existing skills: language detection, handoff context consumption, installation method question, 3–7 context questions (one at a time), artifact generation, completion summary
3. Add the skill path to `skills[]` and the slash command to `commands[]` in `.claude-plugin/plugin.json`
4. Add the new path as an option in `skills/onboarding/SKILL.md` (Step 3 and Step 5)
5. Update `README.md` (What's Inside table)

## Skill Authoring Rules
- All SKILL.md content in English
- Skills detect user language at runtime and respond accordingly
- Superpowers is optional in all new skills — only `coding-setup` and `knowledge-base-builder` install it without asking
- Every skill must handle failed external dependency installation gracefully
- Never silently overwrite an existing CLAUDE.md — always extend with a new delimited section

## Spec
Full design decisions: `docs/superpowers/specs/2026-04-16-onboarding-agent-design.md`
