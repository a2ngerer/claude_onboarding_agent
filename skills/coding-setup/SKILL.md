---
name: coding-setup
description: Set up Claude for software development — installs Superpowers, configures an iterative coding workflow (brainstorm → plan → subagents → review → commit), and generates CLAUDE.md, AGENTS.md, and settings.json tailored to your stack.
---

# Coding Setup

This skill sets up Claude Code for professional software development using a proven iterative workflow.

**Language:** If a HANDOFF_CONTEXT is present, use `detected_language`. Otherwise detect language from the user's first message and use it throughout.

**Existing CLAUDE.md:** If `existing_claude_md: true` in handoff context, or if CLAUDE.md exists in the filesystem, DO NOT overwrite it. Append a new delimited section at the end of the file:

```
<!-- onboarding-agent:start setup=coding skill=coding-setup section=claude-md -->
## Claude Onboarding Agent — Coding Setup
...generated content...
<!-- onboarding-agent:end -->
```

If the delimited block already exists from a previous run, replace only the content between the markers; leave the rest of the file untouched. Use the same marker pattern (`# onboarding-agent: coding — start` / `— end`) around generated `.gitignore` blocks so `/upgrade-setup` can refresh them non-destructively.

## Step 1: Install Dependencies

Read `skills/_shared/installation-protocol.md` and follow it for each dependency below.

Dependencies:
- Superpowers (required) — marketplace-id: `superpowers@claude-plugins-official`, github: `https://github.com/obra/superpowers`, name: `superpowers`

## Step 2: Context Questions

Ask these 4 questions one at a time. Wait for each answer before asking the next:

1. "What is your primary programming language or tech stack? (e.g., Python, TypeScript/React, Go, Rust)"
2. "Do you work solo or in a team?"
3. "Which git host do you use? (GitHub / GitLab / Bitbucket / other / none)"
4. "Which IDE or editor do you use? (VS Code / JetBrains / Neovim / other)"

## Step 3: Offer GitHub MCP (conditional)

Read `skills/_shared/offer-mcp.md` and follow it with these parameters:

- `mcp_slug`: `github`
- `trigger_condition`: project is git-initialized AND has a GitHub remote. Check via Bash:
  `git remote -v 2>/dev/null | grep -q 'github.com' && echo YES || echo NO`
  If `NO`, skip this step entirely — no prompt, no CLAUDE.md change.
- `capability_line`: "Access GitHub issues, PRs, and reviews directly via the GitHub API instead of shelling out to `gh`."
- `install_command`: `claude mcp add github npx -- -y @modelcontextprotocol/server-github`
- `auth_type`: `api_token`
- `auth_detail`: `GITHUB_PERSONAL_ACCESS_TOKEN` (generate at https://github.com/settings/tokens — scope `repo` for private repos, else `public_repo`)
- `pointer_link`: `https://github.com/modelcontextprotocol/servers/tree/main/src/github`

Record `github_installed` in skill state for use by the CLAUDE.md generator and completion summary.

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

[Include ONLY if github_installed is true OR github_deferred is true — emitted per skills/_shared/offer-mcp.md Step 5]
## Configured MCP servers
- github: [see _shared/offer-mcp.md Step 5 for the exact per-state line format]
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

## Step 6: Optional Graphify Integration

Ask ONCE (adapt to detected language):

> "Install Graphify knowledge-graph integration now?
>
> Graphify indexes your project (code via tree-sitter for 25 languages, plus Markdown, PDFs, diagrams, images, audio/video) into a local graph and registers a PreToolUse hook that consults the graph BEFORE Claude runs Grep / Glob / Read. This dramatically cuts token cost on large codebases. It also adds a `/graphify` slash command for natural-language queries. See https://github.com/safishamsi/graphify.
>
> (yes / no / later)"

- **yes** → set `host_setup_slug: "coding"`, `host_skill_slug: "coding-setup"`, `run_initial_build: true`, `install_git_hook: true`. Read `skills/_shared/graphify-install.md` and follow steps G1–G9 in order. The shared protocol handles prerequisites (Python >= 3.10, `uv` or `pipx`), install (`uv tool install graphifyy` preferred, `pipx install graphifyy` fallback — never `pip install`), `graphify install`, hook verification, optional initial build + git hook, and appends the attributed CLAUDE.md section with `setup=coding skill=graphify-setup section=graphify`. Record the protocol's output variables for the completion summary.
- **no** → do not mention Graphify further. Set `graphify_installed: false` and skip to Step 7.
- **later** → invoke `skills/_shared/graphify-install.md` in "later" mode: skip Steps G1–G7 and only write the short deferred pointer block into CLAUDE.md (`"Knowledge graph: run /graphify-setup when ready."`). Set `graphify_installed: false`, `graphify_deferred: true`.

## Step 7: Write Upgrade Metadata

Set `setup_slug: coding`, `skill_slug: coding-setup`. Resolve `plugin_version` from the plugin's own `plugin.json`. Then follow `skills/_shared/write-meta.md` to create or merge `./.claude/onboarding-meta.json`. If Step 5 installed Graphify, `skills_used` will automatically pick up `graphify-setup` via the shared protocol's own write-meta call — this step records `coding-setup` alongside it.

## Step 8: Render Anchor Sections

Read `skills/_shared/anchor-mapping.md`. Locate the row for `setup_type: coding`. For each anchor slug in that row:

1. Call `skills/_shared/render-anchor-section.md` with:
   - `setup_type: coding`
   - `skill_slug: coding-setup`
   - `anchor_slug: <slug>`
   - `target_file: ./CLAUDE.md`
   - `fallback_content: <embedded fallback from skills/anchors/SKILL.md for that slug>`
2. If a `./AGENTS.md` file was generated earlier in this skill, repeat the call with `target_file: ./AGENTS.md`.

Do not fail if any single `render-anchor-section.md` call returns `placeholder` — that is the designed offline path. Collect the list of rendered / placeholder slugs to mention in the completion summary.

## Step 9: Completion Summary

```
✓ Coding setup complete! Here's what was configured:

Files created:
  CLAUDE.md                     — project context + [workflow instructions / ⚠ omitted — Superpowers not installed]
  AGENTS.md                     — coder, reviewer, and git-agent role definitions
  .claude/settings.json         — tool permissions for [stack]
  .gitignore                    — [stack]-appropriate ignore rules
  .claude/onboarding-meta.json  — setup marker for /upgrade-setup

External skills:
  [✓ Superpowers installed via superpowers_method (superpowers_scope)]
  [⚠ Superpowers installation failed — install manually: https://github.com/obra/superpowers]

Optional community skills: [list of installed skills, or "none selected"]

Graphify (knowledge graph):
  [✓ installed via <installer>, /graphify + PreToolUse hook registered | ⚠ installed but hook not verified — run /graphify in a new session | — skipped: <reason> | — deferred: run /graphify-setup when ready | — not offered]

MCP servers:
  [one line per MCP considered, formatted per skills/_shared/offer-mcp.md Step 6 — omit if github trigger condition was false]

Next steps:
  Start a new Claude session and run: /superpowers:using-superpowers
  Then try: /superpowers:brainstorming "describe your first feature"
  [If Graphify installed] Try: /graphify query "where does auth happen in this repo?"
  - Run `/anchors` any time to refresh the anchor-derived sections. If any section was rendered as a placeholder due to offline mode, re-run `/anchors` once you are back online.
```
