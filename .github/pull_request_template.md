## What does this PR do?

<!-- One sentence: what use case does this skill or change serve? -->

## Example output

<!-- Paste an example of the CLAUDE.md (or other artifact) this skill generates -->

## Checklist

### New skill
- [ ] `skills/[name]/SKILL.md` created following existing skill pattern
- [ ] Skill path added to `skills[]` in `.claude-plugin/plugin.json`
- [ ] Slash command added to `commands[]` in `.claude-plugin/plugin.json`
- [ ] New skill added as option in `skills/onboarding/SKILL.md` (Step 3 and Step 5)
- [ ] Row added to "What's Inside" table in `README.md`

### Standards
- [ ] SKILL.md content is in English (runtime language detection handles the rest)
- [ ] Superpowers installation is optional (explained with A/B/skip, never mandatory)
- [ ] Skill handles failed external dependency installation gracefully
- [ ] Skill never silently overwrites an existing CLAUDE.md
- [ ] Skill asks 3–7 context questions, one at a time

### Improving an existing skill
- [ ] Issue opened and discussed before this PR
- [ ] Change description explains why the existing behavior was a problem
