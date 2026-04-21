# Claude Onboarding Agent — Development Instructions

## What This Repo Is
A Claude Code plugin with 8 skills (1 orchestrator + 7 setup skills). Skills are markdown files in `skills/*/SKILL.md`. The plugin generates configuration files (CLAUDE.md, AGENTS.md, etc.) in users' projects.

## Key Paths
- `skills/` — all skill files (one folder per skill, each with a `SKILL.md`)
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

## Repository Language Rule
All public repo artifacts — GitHub issues, PR titles/descriptions, commit messages, code comments, docs — must be written in English, regardless of the conversation language. Conversation with the user may be in German; output that lands in the repo or on GitHub must not.

## Skill Authoring Rules
- All SKILL.md content in English
- Skills detect user language at runtime and respond accordingly
- Superpowers is optional in all new skills — only `coding-setup` and `knowledge-base-builder` install it without asking
- Every skill must handle failed external dependency installation gracefully
- Never silently overwrite an existing CLAUDE.md — always extend with a new delimited section

## Rule File Extraction

When a setup skill produces rule-like content for the user's project, apply this rule:

**Inline in CLAUDE.md if both hold:**
1. The topic is not on the extraction whitelist below, AND
2. The rule block is shorter than 25 lines total.

**Otherwise, extract to `.claude/rules/<filename>.md`.**

### Extraction Whitelist (always extracted, regardless of length)

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

**Topic exclusivity:** Each whitelist filename has exactly one owning skill. No two skills ever write the same filename. Adding a new topic or owner requires a spec update, not an ad-hoc skill change.

**Collision policy:** Skills must skip the write if the target file already exists, logging `Skipped .claude/rules/<name>.md (already exists)`. Explicit regeneration is only via `checkup --rebuild` or `upgrade`.

## Spec
Full design decisions: `docs/superpowers/specs/2026-04-16-onboarding-agent-design.md`
