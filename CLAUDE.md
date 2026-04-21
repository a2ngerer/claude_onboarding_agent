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
- Superpowers is optional in all new skills — only `coding-setup` and `knowledge-base-setup` install it without asking
- Every skill must handle failed external dependency installation gracefully
- Never silently overwrite an existing CLAUDE.md — always extend with a new delimited section

## Subagent Authoring Rules

The plugin ships its own read-only subagents under `.claude/agents/<name>.md`. They are discovered by Claude Code convention — do NOT register them in `.claude-plugin/plugin.json`. Current catalog: `repo-scanner`, `upgrade-planner`. Adding a new subagent requires a spec update.

### File format

Each subagent has YAML frontmatter and a Markdown body:

```
---
name: <kebab-case-name, matches filename>
description: <one sentence, include "read-only" if applicable>
tools: <comma-separated whitelist — required>
model: opus
---

# <Human-readable name>

## Role
## Inputs
## Output Contract
## Constraints
## Failure Mode
```

The five body sections are mandatory. The Output Contract section MUST include at least one fenced code block showing the exact reply shape (not placeholders like `<output>`).

### Tool-set policy

- Plugin subagents are **read-only** by default. Do not include `Write`, `Edit`, or `NotebookEdit` in the `tools:` frontmatter.
- `Bash` is permitted for read-only operations (`find`, `ls`, `wc`, `git ls-files`). The body prompt MUST forbid destructive bash explicitly (no `rm`, `mv`, `cp`, redirects into project files, git state changes).
- Any write-capable subagent requires its own spec with a tool-set carve-out.

### Invocation pattern (for consumer skills)

Consumer skills dispatch via the Agent tool. Example:

```
Use the Agent tool with:
  subagent_type: repo-scanner
  description: "Scan the current project for use-case signals"
  prompt: |
    Scan the project rooted at the current working directory.
    Return your standard `repo-scan` fenced block.
```

Consumers parse the contracted fenced block from the reply and validate every expected field. If the parse fails, the consumer MUST fall back to its previous inline behavior, not proceed with partial data.

### Forbidden patterns

- Subagents dispatching other subagents — nested dispatch blows up context budgets.
- Subagents writing user files — reserved for a future spec.
- Consumer skills invoking subagents without parsing the contracted output — "run it and hope" is not acceptable.

## Spec
Full design decisions: `docs/superpowers/specs/2026-04-16-onboarding-agent-design.md`
