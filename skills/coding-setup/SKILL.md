---
name: coding-setup
description: Set up Claude for software development — installs Superpowers, configures an iterative coding workflow (brainstorm → plan → subagents → review → commit), and generates CLAUDE.md, AGENTS.md, and settings.json tailored to your stack.
---

# Coding Setup

This skill sets up Claude Code for professional software development using a proven iterative workflow.

**Language:** If a HANDOFF_CONTEXT is present, use `detected_language`. Otherwise detect language from the user's first message and use it throughout.

**Existing CLAUDE.md:** If `existing_claude_md: true` in handoff context, or if CLAUDE.md exists in the filesystem, extend it by appending a new section (`## Claude Onboarding Agent — Coding Setup`) rather than overwriting.

## Step 1: Installation Method

Ask the user:

> "How would you like to install Superpowers — the external skills library this setup requires?
>
> **A) Plugin Marketplace** (recommended) — one command: `/plugin install superpowers@claude-plugins-official`
> **B) GitHub** — clone directly from github.com/obra/superpowers (more control, works offline after clone)"

Store the choice as `install_method`.

## Step 2: Context Questions

Ask these 4 questions one at a time. Wait for each answer before asking the next:

1. "What is your primary programming language or tech stack? (e.g., Python, TypeScript/React, Go, Rust)"
2. "Do you work solo or in a team?"
3. "Which git host do you use? (GitHub / GitLab / Bitbucket / other / none)"
4. "Which IDE or editor do you use? (VS Code / JetBrains / Neovim / other)"

## Step 3: Install Superpowers

Execute the chosen installation method:

**If Plugin Marketplace (A):**
```
/plugin install superpowers@claude-plugins-official
```
Verify by checking that the superpowers plugin is listed as installed.

**If GitHub (B):**
```bash
git clone https://github.com/obra/superpowers ~/.claude/plugins/superpowers
```
Verify by checking that `~/.claude/plugins/superpowers/skills/` directory exists.

**If installation fails:**
- Warn the user clearly: "⚠ Superpowers installation failed. Setup will continue, but the workflow instructions referencing Superpowers will be omitted from CLAUDE.md. Please install Superpowers manually: https://github.com/obra/superpowers"
- Set `superpowers_installed: false` and continue.

If installation succeeds, set `superpowers_installed: true`.

## Step 4: Generate Artifacts

Generate the following files automatically:

### CLAUDE.md

```markdown
# Claude Instructions

## Project Context
[Stack from Q1] project. [Solo/Team from Q2]. Git host: [Q3 answer]. IDE: [Q4 answer].

## Development Workflow
[Include this entire section ONLY if superpowers_installed is true]

At the start of every new conversation, invoke the `using-superpowers` skill.

Follow this iterative workflow for all features and bug fixes:
1. **Brainstorm** — use `superpowers:brainstorming` to explore requirements before writing any code
2. **Plan** — use `superpowers:writing-plans` to create a step-by-step implementation plan
3. **Implement** — use `superpowers:subagent-driven-development` to dispatch subagents per task
4. **Review** — use `superpowers:requesting-code-review` before merging
5. **Commit** — atomic commits with descriptive messages after each verified task

## Code Standards
- Write minimal code. YAGNI: do not add features not explicitly requested.
- No speculative abstractions. Three similar lines beat a premature helper.
- Validate only at system boundaries (user input, external APIs).
- No error handling for scenarios that cannot happen.

## Testing
- Write tests before implementation (TDD).
- Tests must run against real dependencies — avoid mocks unless unavoidable.
```

Adapt the "Project Context" section based on the detected stack:
- Python → mention `uv` as package manager if applicable
- Node/TypeScript → mention npm/yarn/pnpm as appropriate
- Go/Rust → note the standard build tools

### AGENTS.md

```markdown
# Agent Roles

## coder
Implements features and bug fixes. Works from a written plan. Makes atomic commits after each verified task. Does not refactor code unrelated to the current task.

## reviewer
Reviews code changes against the implementation plan and coding standards. Checks for correctness, security (OWASP Top 10), and spec alignment. Returns a list of issues with severity (critical/minor).

## git-agent
Handles all git operations: staging, committing, pushing. Writes descriptive commit messages. Never force-pushes to main. Confirms before any destructive git operation.
```

### .claude/settings.json

Create `.claude/settings.json` with stack-appropriate tool permissions:

```json
{
  "permissions": {
    "allow": [
      "Bash(git *)"
    ]
  }
}
```

Extend the `allow` list based on detected stack:
- Python → add `"Bash(uv *)"`, `"Bash(python *)"`, `"Bash(pytest *)"`
- Node/TypeScript → add `"Bash(npm *)"`, `"Bash(node *)"`, `"Bash(npx *)"`
- Go → add `"Bash(go *)"`
- Rust → add `"Bash(cargo *)"`

### .gitignore

Generate a `.gitignore` appropriate for the detected stack. Always include `.claude/settings.local.json`.

- Python: `__pycache__/`, `.venv/`, `*.pyc`, `dist/`, `.env`, `.claude/settings.local.json`
- Node: `node_modules/`, `dist/`, `.env`, `*.log`, `.claude/settings.local.json`
- Go: `*.exe`, `*.test`, `vendor/`, `.claude/settings.local.json`
- Rust: `target/`, `.claude/settings.local.json`
- Generic fallback: `.env`, `*.log`, `.DS_Store`, `.claude/settings.local.json`

## Step 5: Optional Community Skills

> "Would you like to install additional community skills?
>
> A) frontend-design (official Anthropic) — avoids AI-generic UI, bold design decisions (277k installs)
> B) mcp-builder — create MCP servers for external API integrations
> C) webapp-testing — Playwright-based UI testing
> D) security-suite — Trail of Bits CodeQL/Semgrep analysis
> E) All of the above
> F) None
>
> (Multiple selections via comma, e.g. 'A, C')"

For each selected skill, run: `/plugin install <skill>@claude-plugins-official`

On failure for any skill: warn clearly ("⚠ Could not install [skill] — skipping. Install manually later.") and continue. Never block the setup.

Add the list of successfully installed optional skills to the Completion Summary under a new line: `Optional community skills: [list or "none selected"]`

## Step 6: Completion Summary

```
✓ Coding setup complete! Here's what was configured:

Files created:
  CLAUDE.md            — project context + [workflow instructions / ⚠ omitted — Superpowers not installed]
  AGENTS.md            — coder, reviewer, and git-agent role definitions
  .claude/settings.json — tool permissions for [stack]
  .gitignore           — [stack]-appropriate ignore rules

External skills:
  [✓ Superpowers installed via Plugin Marketplace / GitHub]
  [⚠ Superpowers installation failed — install manually: https://github.com/obra/superpowers]

Optional community skills: [list of installed skills, or "none selected"]

Next steps:
  Start a new Claude session and run: /superpowers:using-superpowers
  Then try: /superpowers:brainstorming "describe your first feature"
```
