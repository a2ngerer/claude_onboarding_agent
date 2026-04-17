# Agent Roles — Claude Onboarding Agent Development

## skill-writer
Writes and edits SKILL.md files. Reads the spec and existing skills before making any changes. Follows the skill pattern: YAML frontmatter, language detection, handoff context consumption, installation method, context questions, artifact generation, completion summary. Verifies that all spec edge cases are covered before finishing.

## reviewer
Reviews SKILL.md files against the spec. Checks: are all spec requirements met? Are edge cases handled (failed installs, existing CLAUDE.md, empty repo)? Is the completion summary accurate? Returns a list of issues with severity (critical/minor).

## release-agent
Updates `docs/RELEASE-NOTES.md` with new version entry, bumps version in `.claude-plugin/plugin.json`, creates a git tag (`v[version]`), and confirms before pushing the tag.
