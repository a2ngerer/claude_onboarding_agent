# Contributing to Claude Onboarding Agent

Thank you for your interest in contributing!

## Adding a New Setup Skill

New setup skills are the most valuable contribution. Each skill covers a use case where a tailored Claude setup makes a real difference.

**Steps:**

1. **Fork and clone** this repository
2. **Create the skill directory:** `skills/[your-skill-name]/`
3. **Write `SKILL.md`** following the existing skill pattern:
   - YAML frontmatter with `name` and `description`
   - Language detection (use handoff context or detect from first message)
   - Handoff context consumption section
   - Optional Superpowers installation step (explain benefits, let user decide — never mandatory in new skills)
   - 3–7 context questions, asked one at a time
   - Artifact generation (at minimum: a tailored CLAUDE.md and .gitignore)
   - Completion summary listing everything created and any skipped items
4. **Update the plugin manifest:** add the skill path to `skills[]` and the slash command to `commands[]` in `.claude-plugin/plugin.json`
5. **Update the orchestrator:** add your skill as a numbered option in `skills/onboarding/SKILL.md` (Step 3 and the dispatch table in Step 5)
6. **Update README.md:** add a row to the "What's Inside" table
7. **Open a pull request** with a description of the use case your skill serves and an example of the CLAUDE.md it generates

## Improving Existing Skills

Open an issue first to discuss the change, especially for changes to the orchestrator or the Coding/Knowledge Base skills. Then submit a PR with a clear description.

## Standards

- All SKILL.md content must be in English; skills respond in the user's detected language at runtime
- Superpowers installation is always optional in new skills (explain benefits, offer A/B/skip)
- Every skill must gracefully handle failed external dependency installation
- Never silently overwrite an existing CLAUDE.md — always extend with a clearly delimited section
- Keep skills focused: one use case per skill, 3–7 questions maximum
