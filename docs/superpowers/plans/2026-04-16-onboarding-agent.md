# Claude Onboarding Agent — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Claude Code plugin with 6 skills (1 orchestrator + 5 setup skills) that auto-configures Claude for any user's use case by generating tailored CLAUDE.md, AGENTS.md, and supporting files.

**Architecture:** Lightweight orchestrator skill scans the repo, infers use case, dispatches to one of 5 standalone setup skills. Each setup skill asks 3-7 context questions, installs Superpowers (always or optionally), and generates all config artifacts automatically. Skills are standalone and callable directly via slash command.

**Tech Stack:** Markdown skill files (SKILL.md), JSON plugin manifest, bash install script, no runtime dependencies beyond Claude Code.

---

## File Map

| File | Responsibility |
|------|---------------|
| `.claude-plugin/plugin.json` | Plugin manifest — registers plugin name, version, author |
| `skills/onboarding/SKILL.md` | Orchestrator — repo scan, language detect, path inference, dispatch |
| `skills/coding-setup/SKILL.md` | Coding path — Superpowers install, CLAUDE.md + AGENTS.md + settings.json generation |
| `skills/knowledge-base-builder/SKILL.md` | KB path — Karpathy pattern, Obsidian MCP or fallback, Superpowers install |
| `skills/office-setup/SKILL.md` | Office path — writing style prefs, optional Superpowers |
| `skills/research-setup/SKILL.md` | Research path — academic writing, citation format, optional Superpowers |
| `skills/content-creator-setup/SKILL.md` | Content path — brand voice, platform setup, optional Superpowers |
| `scripts/install.sh` | GitHub installation — clones plugin to ~/.claude/plugins/ |
| `README.md` | Discoverability — problem statement, install instructions, feature overview |
| `CLAUDE.md` | Dev instructions for this repo (not generated for users) |
| `AGENTS.md` | Subagent guidance for this repo |
| `CONTRIBUTING.md` | How to add new setup skills |
| `CODE_OF_CONDUCT.md` | Contributor code of conduct |
| `LICENSE` | MIT license |
| `RELEASE-NOTES.md` | Version changelog |
| `.gitignore` | Ignore OS/editor artifacts for this repo |

---

## Task 1: Repo Scaffolding

**Files:**
- Create: `LICENSE`
- Create: `.gitignore`
- Create: `RELEASE-NOTES.md`
- Create: `CODE_OF_CONDUCT.md`

- [ ] **Step 1: Create directory structure**

```bash
cd /Users/angeral/Repositories/claude_onboarding_agent
mkdir -p .claude-plugin .claude/commands skills/onboarding skills/coding-setup skills/knowledge-base-builder skills/office-setup skills/research-setup skills/content-creator-setup scripts
```

- [ ] **Step 2: Create LICENSE (MIT)**

```
MIT License

Copyright (c) 2026 Alexander Angerer

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 3: Create .gitignore**

```gitignore
# OS
.DS_Store
Thumbs.db

# Editors
.vscode/
.idea/
*.swp
*.swo

# Claude local settings
.claude/settings.local.json
```

- [ ] **Step 4: Create RELEASE-NOTES.md**

```markdown
# Release Notes

## v1.0.0 — 2026-04-16

Initial release.

### Skills
- `/onboarding` — Orchestrator with repo scanning and path inference
- `/coding-setup` — Coding workflow with Superpowers integration
- `/build-knowledge-base` — Karpathy-pattern knowledge base builder with Obsidian support
- `/office-setup` — Office and business productivity setup
- `/research-setup` — Academic research and writing setup
- `/content-creator-setup` — Content creation workflow setup
```

- [ ] **Step 5: Create CODE_OF_CONDUCT.md**

```markdown
# Contributor Covenant Code of Conduct

## Our Pledge

We as contributors and maintainers pledge to make participation in our project a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, sex characteristics, gender identity and expression, level of experience, education, socio-economic status, nationality, personal appearance, race, religion, or sexual identity and orientation.

## Our Standards

Examples of behavior that contributes to a positive environment:
- Using welcoming and inclusive language
- Being respectful of differing viewpoints and experiences
- Gracefully accepting constructive criticism
- Focusing on what is best for the community

Examples of unacceptable behavior:
- The use of sexualized language or imagery
- Trolling, insulting or derogatory comments
- Public or private harassment
- Publishing others' private information without explicit permission

## Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be reported by opening an issue in this repository.

This Code of Conduct is adapted from the [Contributor Covenant](https://www.contributor-covenant.org), version 2.1.
```

- [ ] **Step 6: Commit**

```bash
git add LICENSE .gitignore RELEASE-NOTES.md CODE_OF_CONDUCT.md
git commit -m "chore: initial repo scaffolding — license, gitignore, release notes"
```

---

## Task 2: Plugin Manifest

**Files:**
- Create: `.claude-plugin/plugin.json`

- [ ] **Step 1: Create plugin.json**

```json
{
  "name": "claude-onboarding-agent",
  "description": "Guided setup for Claude Code — generates tailored CLAUDE.md, AGENTS.md, and config files for any use case in minutes.",
  "version": "1.0.0",
  "author": {
    "name": "Alexander Angerer",
    "email": "alexander.angerer@outlook.de"
  },
  "homepage": "https://github.com/a2ngerer/claude_onboarding_agent",
  "repository": "https://github.com/a2ngerer/claude_onboarding_agent",
  "license": "MIT",
  "keywords": [
    "onboarding",
    "setup",
    "claude-code",
    "skills",
    "knowledge-base",
    "obsidian",
    "superpowers",
    "productivity"
  ]
}
```

- [ ] **Step 2: Verify JSON is valid**

```bash
python3 -c "import json; json.load(open('.claude-plugin/plugin.json')); print('Valid JSON')"
```
Expected: `Valid JSON`

- [ ] **Step 3: Commit**

```bash
git add .claude-plugin/plugin.json
git commit -m "feat: add Claude Code plugin manifest"
```

---

## Task 3: Install Script

**Files:**
- Create: `scripts/install.sh`

- [ ] **Step 1: Create install.sh**

```bash
#!/usr/bin/env bash
set -e

PLUGIN_DIR="${HOME}/.claude/plugins"
PLUGIN_NAME="claude-onboarding-agent"
REPO_URL="https://github.com/a2ngerer/claude_onboarding_agent.git"

echo "Installing Claude Onboarding Agent..."

# Create plugins directory if it does not exist
mkdir -p "$PLUGIN_DIR"

TARGET="${PLUGIN_DIR}/${PLUGIN_NAME}"

if [ -d "$TARGET" ]; then
  echo "Plugin already installed at ${TARGET}. Updating..."
  git -C "$TARGET" pull
else
  echo "Cloning into ${TARGET}..."
  git clone "$REPO_URL" "$TARGET"
fi

echo ""
echo "✓ Claude Onboarding Agent installed to ${TARGET}"
echo ""
echo "Next steps:"
echo "  Start a new Claude Code session and run: /onboarding"
echo "  Or jump directly to a setup skill:"
echo "    /coding-setup"
echo "    /build-knowledge-base"
echo "    /office-setup"
echo "    /research-setup"
echo "    /content-creator-setup"
```

- [ ] **Step 2: Make executable and verify**

```bash
chmod +x scripts/install.sh
bash -n scripts/install.sh && echo "Script syntax OK"
```
Expected: `Script syntax OK`

- [ ] **Step 3: Commit**

```bash
git add scripts/install.sh
git commit -m "feat: add GitHub installation script"
```

---

## Task 4: Onboarding Orchestrator Skill

**Files:**
- Create: `skills/onboarding/SKILL.md`

This is the most complex skill. Read the spec at `docs/superpowers/specs/2026-04-16-onboarding-agent-design.md` sections "Orchestrator Flow" and "Orchestrator → Skill Handoff Contract" before writing.

- [ ] **Step 1: Write skills/onboarding/SKILL.md**

```markdown
---
name: onboarding
description: Guided onboarding orchestrator — scans your repo, infers your use case, and dispatches to the right setup skill. Run this if you're new to Claude Code and want a personalized setup.
---

# Claude Onboarding Agent

Welcome to the Claude Onboarding Agent. This skill will scan your project, ask you one question, and then set up Claude exactly the way you need it.

**Detect language first:** Read the user's first message. Detect the language (e.g., English, German, Spanish, French). Respond in that language for the entire session. All generated file content comments also use that language. Technical field names, tool names, and code remain in English regardless.

## Step 1: Scan the Repository

Before asking anything, silently scan the current directory:

- Count file extensions: `.py`, `.ts`, `.js`, `.go`, `.rs`, `.rb`, `.java`, `.cs` → coding signal
- Look for package manifests: `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `requirements.txt` → strong coding signal
- Look for `.tex`, `.bib` files → research signal
- Look for `*.docx`, `*.pptx`, `*.pdf`, `*.xlsx` files → office signal
- Look for a `notes/`, `vault/`, `wiki/`, `obsidian/` directory → knowledge base signal
- Check if `CLAUDE.md` already exists → set `existing_claude_md: true`
- Check if `AGENTS.md` already exists

**Infer the most likely use case** based on the strongest signal. If no signal: no inference.

**If CLAUDE.md exists:** Before presenting options, inform the user: "I found an existing CLAUDE.md. The setup skill will extend it (adding a new section) rather than overwriting it."

## Step 2: Present Options

Present all 5 options. Place the inferred use case at position 1 with a brief note explaining the inference. If no inference, present all options equally.

Format (adapt wording to detected language):

---

**Which setup would you like?**

1. [Inferred: Coding Setup] ← looks like a Python project (pyproject.toml detected)
2. Knowledge Base & Documentation — build a structured wiki from code or notes
3. Office & Business Productivity — emails, reports, presentations
4. Research & Academic Writing — literature, papers, LaTeX
5. Content Creation — YouTube, social media, newsletters
6. Not sure — help me decide

---

## Step 3: Handle "Not Sure"

If the user picks option 6, ask these 3 yes/no questions one at a time:

1. "Are you primarily using Claude to work with code or a codebase?" → yes → recommend Coding Setup
2. "Are you trying to organize documents, notes, or code into a structured knowledge base or wiki?" → yes → recommend Knowledge Base Builder
3. "Do you mostly work with documents, emails, reports, or presentations?" → yes → recommend Office Setup

If none match after 3 questions, present all 5 options again with one-line descriptions and ask them to pick a number.

## Step 4: Dispatch

Once the user confirms a choice, pass the following handoff context inline to the chosen skill and invoke it:

```
HANDOFF_CONTEXT:
  detected_language: "[ISO 639-1 code, e.g. en, de, es]"
  existing_claude_md: [true/false]
  inferred_use_case: "[coding|knowledge-base|office|research|content-creator|unknown]"
  repo_signals: ["[list of detected signals, e.g. pyproject.toml, *.py files]"]
```

Then invoke the appropriate skill:
- Coding Setup → invoke `coding-setup` skill
- Knowledge Base → invoke `knowledge-base-builder` skill
- Office → invoke `office-setup` skill
- Research → invoke `research-setup` skill
- Content Creator → invoke `content-creator-setup` skill

Step back completely. The setup skill handles everything from here.
```

- [ ] **Step 2: Self-check against spec**

Verify the skill covers:
- [ ] Language detection
- [ ] Repo scan with all 6 signal types
- [ ] Existing CLAUDE.md edge case
- [ ] All 5 options + "not sure"
- [ ] "Not sure" 3-question flow with fallback
- [ ] Handoff context with all 4 fields
- [ ] Dispatch to all 5 skills

- [ ] **Step 3: Commit**

```bash
git add skills/onboarding/SKILL.md
git commit -m "feat: add onboarding orchestrator skill"
```

---

## Task 5: Coding Setup Skill

**Files:**
- Create: `skills/coding-setup/SKILL.md`

Read spec sections: "Setup Skill Flow", "Coding Setup" artifacts, "Superpowers Integration", "Installation Method: What Changes".

- [ ] **Step 1: Write skills/coding-setup/SKILL.md**

```markdown
---
name: coding-setup
description: Set up Claude for software development — installs Superpowers, configures an iterative coding workflow (brainstorm → plan → subagents → review → commit), and generates CLAUDE.md, AGENTS.md, and settings.json tailored to your stack.
---

# Coding Setup

This skill sets up Claude Code for professional software development using a proven iterative workflow.

**Language:** If a HANDOFF_CONTEXT is present, use `detected_language`. Otherwise detect language from the user's first message and use it throughout.

**Existing CLAUDE.md:** If `existing_claude_md: true` in handoff context, or if CLAUDE.md exists in the filesystem, extend it (append a new section) rather than overwriting.

## Step 1: Installation Method

Ask the user:

> "How would you like to install Superpowers (the external skills library this setup uses)?
>
> **A) Plugin Marketplace** (recommended) — one command: `/plugin install superpowers@claude-plugins-official`
> **B) GitHub** — clone directly from github.com/obra/superpowers (more control, works offline after clone)"

Store the choice as `install_method`.

## Step 2: Context Questions

Ask these 4 questions one at a time. Do not ask the next question until the current one is answered:

1. "What is your primary programming language or tech stack? (e.g., Python, TypeScript/React, Go, Rust)"
2. "Do you work solo or in a team?"
3. "Which git host do you use? (GitHub / GitLab / Bitbucket / other / none)"
4. "Which IDE or editor do you use? (VS Code / JetBrains / Neovim / other)"

## Step 3: Install Superpowers

Execute the chosen installation method:

**If Plugin Marketplace:**
```
/plugin install superpowers@claude-plugins-official
```
Verify by checking that the superpowers plugin is listed in installed plugins.

**If GitHub:**
```bash
git clone https://github.com/obra/superpowers ~/.claude/plugins/superpowers
```
Verify by checking that `~/.claude/plugins/superpowers/skills/` directory exists.

**If installation fails:**
- Warn the user clearly: "⚠ Superpowers installation failed. The setup will continue, but the workflow instructions that reference Superpowers will be omitted from your CLAUDE.md. Please install Superpowers manually later."
- Set `superpowers_installed: false`
- Continue to Step 4

If installation succeeds, set `superpowers_installed: true`.

## Step 4: Generate Artifacts

Generate the following files automatically without further prompting:

### CLAUDE.md

```markdown
# Claude Instructions

## Project Context
[Stack from question 1] project. [Solo/Team from question 2]. Git host: [answer 3]. IDE: [answer 4].

## Development Workflow
[Include this section ONLY if superpowers_installed is true]

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
- Tests must run against real dependencies, not mocks, unless mocking is the only option.
```

### AGENTS.md

```markdown
# Agent Roles

## coder
Implements features and bug fixes. Works from a written plan. Makes atomic commits after each verified task. Does not refactor code that is not related to the current task.

## reviewer
Reviews code changes against the implementation plan and coding standards. Checks for correctness, security (OWASP Top 10), and spec alignment. Returns a list of issues with severity (critical/minor).

## git-agent
Handles all git operations: staging, committing, pushing. Writes descriptive commit messages. Never force-pushes to main. Confirms before any destructive git operation.
```

### .claude/settings.json

```json
{
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(npm *)",
      "Bash(python *)",
      "Bash(uv *)"
    ]
  }
}
```
Adapt `allow` list based on detected stack (Python → uv/python, Node → npm/node, etc.).

### .gitignore

Generate a `.gitignore` appropriate for the detected stack:
- Python: `__pycache__/`, `.venv/`, `*.pyc`, `dist/`, `.env`
- Node: `node_modules/`, `dist/`, `.env`, `*.log`
- Go: `*.exe`, `*.test`, `vendor/`
- Generic fallback: `.env`, `*.log`, `.DS_Store`

Always append: `.claude/settings.local.json`

## Step 5: Completion Summary

Print a summary of everything created:

```
✓ Setup complete! Here's what was configured:

Files created:
  CLAUDE.md          — project context + [workflow instructions if Superpowers installed]
  AGENTS.md          — coder, reviewer, and git-agent role definitions
  .claude/settings.json — tool permissions for your stack
  .gitignore         — [stack]-appropriate ignore rules

External skills:
  [✓ Superpowers installed via [method]] OR [⚠ Superpowers not installed — see note above]

Next steps:
  Start a new Claude conversation and run: /superpowers:using-superpowers
  Then try: /superpowers:brainstorming "describe your first feature"
```
```

- [ ] **Step 2: Self-check against spec**

Verify the skill covers:
- [ ] Handoff context consumption (language + existing CLAUDE.md)
- [ ] Installation method question
- [ ] All 4 context questions
- [ ] Superpowers install + verification + failure handling
- [ ] CLAUDE.md with `using-superpowers` instruction (only if install verified)
- [ ] AGENTS.md with 3 agent roles
- [ ] .claude/settings.json with stack-appropriate permissions
- [ ] .gitignore per stack
- [ ] Completion summary with skipped items noted

- [ ] **Step 3: Commit**

```bash
git add skills/coding-setup/SKILL.md
git commit -m "feat: add coding setup skill"
```

---

## Task 6: Knowledge Base Builder Skill

**Files:**
- Create: `skills/knowledge-base-builder/SKILL.md`

Read spec sections: "Knowledge Base Builder" artifacts, Obsidian MCP handling, Karpathy pattern.

- [ ] **Step 1: Write skills/knowledge-base-builder/SKILL.md**

```markdown
---
name: knowledge-base-builder
description: Set up Claude to build and maintain a structured knowledge base using the Karpathy LLM Wiki pattern — works with codebases, personal notes, or both. Supports Obsidian MCP for direct vault integration.
---

# Knowledge Base Builder

This skill configures Claude to build and maintain a structured, interlinked knowledge base using the Karpathy LLM Wiki pattern.

**Language:** Use `detected_language` from handoff context, or detect from first user message.

**Existing CLAUDE.md:** If `existing_claude_md: true` or CLAUDE.md exists on filesystem, extend rather than overwrite.

## Step 1: Installation Method

Ask the user:

> "How would you like to install Superpowers and the Karpathy Guidelines (the skill libraries this setup uses)?
>
> **A) Plugin Marketplace** (recommended) — one command each
> **B) GitHub** — clone directly from their repositories"

## Step 2: Context Questions

Ask one at a time:

1. "What are you primarily building this knowledge base from?
   A) An existing codebase
   B) Personal notes and documents
   C) Both"

2. "Do you have Obsidian installed?
   
   Obsidian is a local markdown editor with graph view and wiki-style linking. With the Obsidian MCP integration, Claude can write directly into your Obsidian vault — enabling a richer, more connected knowledge base. Without it, Claude still creates well-organized markdown files you can open in any editor.
   
   A) Yes, I have Obsidian installed — set up the MCP integration
   B) No / I'll skip this for now — use plain markdown files"

3. "What is the path to your target folder? (This is where the knowledge base will be built. For Obsidian users: your vault path. Others: any folder you choose.)"
   Example: `~/Documents/my-wiki` or `/Users/alex/vault`

4. "What language are your source files written in? (for code: the programming language; for notes: the human language)"

## Step 3: Install Dependencies

### Install Superpowers

**Marketplace:** `/plugin install superpowers@claude-plugins-official`
**GitHub:** `git clone https://github.com/obra/superpowers ~/.claude/plugins/superpowers`

Verify: Check skills directory exists. On failure: warn, set `superpowers_installed: false`, continue.

### Install Karpathy Guidelines (optional enhancement)

**Marketplace:** `/plugin install andrej-karpathy-skills`
**GitHub:** `git clone https://github.com/forrestchang/andrej-karpathy-skills ~/.claude/plugins/karpathy-skills`

Verify: Check directory exists. On failure: warn and continue — this is optional.

### Set up Obsidian MCP (if user chose option A in question 2)

Add to `.claude/settings.json`:
```json
{
  "mcpServers": {
    "obsidian": {
      "command": "npx",
      "args": ["-y", "mcp-obsidian", "[vault_path_from_question_3]"]
    }
  }
}
```
Inform the user: "The Obsidian MCP server will be available in new Claude sessions. Make sure Obsidian is open when using Claude for knowledge base tasks."

## Step 4: Generate Artifacts

### Folder Structure

Create in the target path:
```
[target_path]/
├── raw/          ← Drop source material here (articles, PDFs, code files)
└── wiki/
    └── README.md ← Overview of the wiki structure
```

`wiki/README.md` content:
```markdown
# Knowledge Base

Built with Claude using the Karpathy LLM Wiki pattern.

## How to Use

**Adding sources:** Drop files into `raw/`. Then ask Claude: "Ingest the new files in raw/ and update the wiki."

**Wiki structure:** Each note in `wiki/` covers one concept, person, project, or topic. Notes link to related notes using [[wikilinks]].

**Note format:**
- First line: one-sentence summary
- Tags on second line: `tags: #topic #subtopic`
- Body: structured content with headers
- Bottom: `## Related: [[linked-note-1]], [[linked-note-2]]`
```

### CLAUDE.md

```markdown
# Claude Instructions — Knowledge Base

## Setup
Target knowledge base path: [answer from question 3]
Source material: [answer from question 1]
Source language: [answer from question 4]

## Workflow — Karpathy LLM Wiki Pattern

[Include ONLY if superpowers_installed is true]
At the start of every new conversation, invoke the `using-superpowers` skill.

### Knowledge Base Structure
- `raw/` — source material (do not modify files here)
- `wiki/` — organized, interlinked knowledge notes

### Note Format
Every wiki note must have:
1. First line: one-sentence summary of the topic
2. Second line: `tags: #tag1 #tag2`
3. Body: structured content with H2/H3 headers
4. Last section: `## Related: [[note1]], [[note2]]`

### Ingestion Process
When asked to ingest new material from raw/:
1. Read the source file
2. Extract key concepts, facts, and insights
3. Create or update wiki notes — one note per concept
4. Link new notes to related existing notes using [[wikilinks]]
5. Update existing notes if new material adds to them
6. Do NOT delete or overwrite existing wiki content — only extend it

### For Codebases
When documenting code:
1. Create one wiki note per module/package/component
2. Note: purpose, public API, dependencies, key design decisions
3. Link to notes about dependencies
4. Add a `wiki/architecture.md` overview that links to all component notes
```

### .gitignore

```gitignore
# Large source files in raw/
raw/*.pdf
raw/*.docx
raw/*.pptx
raw/*.mp4
raw/*.zip

# OS
.DS_Store
Thumbs.db
```

## Step 5: Completion Summary

```
✓ Knowledge Base setup complete!

Files created:
  CLAUDE.md          — Karpathy-pattern instructions
  [target]/raw/      — drop source material here
  [target]/wiki/     — organized knowledge notes will be built here
  [target]/wiki/README.md — how to use your knowledge base
  [if Obsidian MCP] .claude/settings.json — Obsidian MCP configured

External skills:
  [✓/⚠] Superpowers [method]
  [✓/⚠] Karpathy Guidelines [method]
  [✓/⚠] Obsidian MCP [or: using plain markdown fallback]

Next steps:
  Drop files into [target]/raw/
  Start a new Claude session and say: "Ingest the files in raw/ and build the wiki"
```
```

- [ ] **Step 2: Self-check against spec**

- [ ] Handoff context consumption
- [ ] Installation method question
- [ ] All 4 context questions
- [ ] Obsidian MCP explanation + both paths
- [ ] Superpowers install + failure handling
- [ ] Karpathy Guidelines install (optional, failure handled)
- [ ] Folder structure created
- [ ] CLAUDE.md with full Karpathy pattern instructions
- [ ] `using-superpowers` only if install verified
- [ ] .gitignore
- [ ] Completion summary

- [ ] **Step 3: Commit**

```bash
git add skills/knowledge-base-builder/SKILL.md
git commit -m "feat: add knowledge base builder skill"
```

---

## Task 7: Office Setup Skill

**Files:**
- Create: `skills/office-setup/SKILL.md`

- [ ] **Step 1: Write skills/office-setup/SKILL.md**

```markdown
---
name: office-setup
description: Set up Claude for office and business productivity — configures your writing style, document preferences, and company context so Claude always produces on-brand, appropriately formal output.
---

# Office Setup

This skill configures Claude for business and office work.

**Language:** Use `detected_language` from handoff, or detect from first message.

**Existing CLAUDE.md:** Extend rather than overwrite if present.

## Step 1: Superpowers (Optional)

Explain Superpowers to the user:

> "Superpowers is a free skills library for Claude Code used by 94,000+ developers. It adds structured workflows for brainstorming, planning, and debugging. While it's primarily aimed at coding, its thinking and planning skills are valuable for any complex task.
>
> Would you like to install Superpowers?
> A) Yes — install via Plugin Marketplace (one command)
> B) Yes — install via GitHub
> C) Skip for now"

If A or B: install and verify. On failure: warn and continue.

## Step 2: Context Questions

Ask one at a time:

1. "What types of documents do you create most often?
   A) Emails and messages
   B) Reports and proposals
   C) Presentations
   D) All of the above / mix"

2. "What writing style do you prefer?
   A) Formal (corporate tone, complete sentences, no contractions)
   B) Semi-formal (professional but approachable)
   C) Casual (conversational, direct)"

3. "Is there any company, team, or project context that Claude should always keep in mind? (Optional — e.g., 'We are a SaaS company selling to enterprise HR teams' or 'I work in legal compliance')"

## Step 3: Generate Artifacts

### CLAUDE.md

```markdown
# Claude Instructions — Office & Business

## Context
[Context from question 3, or "No specific context provided."]

## Writing Style
Preferred style: [answer from question 2]
Primary document types: [answer from question 1]

## Guidelines
- Always match the specified writing style
- For emails: include a clear subject line suggestion when drafting
- For reports: use headers, executive summary, and clear section breaks
- For presentations: suggest slide structure with one idea per slide
- Proofread for grammar and clarity before presenting output
- Ask for the audience and purpose if not specified for longer documents

[Include ONLY if Superpowers installed]
Superpowers is installed. For complex multi-step tasks (research + write + format), use superpowers:brainstorming to structure the approach first.
```

### .gitignore

```gitignore
# Office temp files
~$*
*.tmp
Thumbs.db
.DS_Store
```

## Step 4: Completion Summary

```
✓ Office setup complete!

Files created:
  CLAUDE.md — writing style + context instructions
  .gitignore — office temp file rules

[If Superpowers installed] External skills: ✓ Superpowers installed
[If skipped] Superpowers: skipped (you can install later with /plugin install superpowers@claude-plugins-official)

Next steps:
  Start a new Claude session and say: "Draft an email to [recipient] about [topic]"
```
```

- [ ] **Step 2: Commit**

```bash
git add skills/office-setup/SKILL.md
git commit -m "feat: add office setup skill"
```

---

## Task 8: Research Setup Skill

**Files:**
- Create: `skills/research-setup/SKILL.md`

- [ ] **Step 1: Write skills/research-setup/SKILL.md**

```markdown
---
name: research-setup
description: Set up Claude for academic research and writing — configures citation format, writing domain, and LaTeX or Word preferences so Claude supports your research workflow from literature review to final paper.
---

# Research Setup

This skill configures Claude for academic and research work.

**Language:** Use `detected_language` from handoff, or detect from first message.

**Existing CLAUDE.md:** Extend rather than overwrite if present.

## Step 1: Superpowers (Optional)

> "Superpowers is a free skills library for Claude Code with 94,000+ users. Its brainstorming and planning skills work well for structuring research arguments and literature reviews.
>
> Would you like to install it?
> A) Yes — Plugin Marketplace
> B) Yes — GitHub
> C) Skip"

If A or B: install and verify.

## Step 2: Context Questions

1. "What is your research domain? (e.g., machine learning, economics, biology, history)"

2. "What citation format do you use?
   A) APA
   B) MLA
   C) Chicago / Turabian
   D) IEEE
   E) Vancouver
   F) Other (specify)"

3. "What do you write in?
   A) LaTeX
   B) Word / Google Docs
   C) Markdown
   D) Mix"

## Step 3: Generate Artifacts

### CLAUDE.md

```markdown
# Claude Instructions — Research & Academic Writing

## Domain
Research domain: [answer 1]
Citation format: [answer 2]
Writing tool: [answer 3]

## Guidelines
- Always use [citation format] for all references
- When asked to summarize a paper, include: main contribution, methodology, key results, limitations
- For literature reviews: group papers thematically, not chronologically
- When drafting arguments: state the claim, cite evidence, address the strongest counterargument
- [If LaTeX] Format citations as BibTeX entries. Use \cite{} in text.
- [If Word/Docs] Format references in [citation format] style at end of document
- Flag when information is from your training data vs. a provided source — never fabricate citations

[Include ONLY if Superpowers installed]
Superpowers is installed. For complex writing tasks, use superpowers:brainstorming to outline structure before drafting.
```

### .gitignore

```gitignore
# LaTeX artifacts
*.aux
*.log
*.bbl
*.blg
*.out
*.toc
*.fdb_latexmk
*.fls
*.synctex.gz

# Large files
*.pdf
*.zip
.DS_Store
```

## Step 4: Completion Summary

```
✓ Research setup complete!

Files created:
  CLAUDE.md — domain, citation format, and writing guidelines
  .gitignore — LaTeX and document artifacts

Next steps:
  Start a new Claude session and say: "Summarize this paper: [paste abstract or upload PDF]"
```
```

- [ ] **Step 2: Commit**

```bash
git add skills/research-setup/SKILL.md
git commit -m "feat: add research setup skill"
```

---

## Task 9: Content Creator Setup Skill

**Files:**
- Create: `skills/content-creator-setup/SKILL.md`

- [ ] **Step 1: Write skills/content-creator-setup/SKILL.md**

```markdown
---
name: content-creator-setup
description: Set up Claude for content creation — configures your brand voice, target platforms, and audience so Claude helps you write scripts, posts, newsletters, and ideas that sound like you.
---

# Content Creator Setup

This skill configures Claude for content creation work.

**Language:** Use `detected_language` from handoff, or detect from first message.

**Existing CLAUDE.md:** Extend rather than overwrite if present.

## Step 1: Superpowers (Optional)

> "Superpowers is a free skills library for Claude Code with 94,000+ users. Its brainstorming skill is particularly useful for generating content ideas and structuring scripts before writing.
>
> Would you like to install it?
> A) Yes — Plugin Marketplace
> B) Yes — GitHub
> C) Skip"

If A or B: install and verify.

## Step 2: Context Questions

1. "Which platforms do you primarily create content for?
   A) YouTube (long-form video)
   B) Instagram / TikTok (short-form)
   C) Newsletter / blog
   D) Podcast
   E) Multiple / all of the above"

2. "How would you describe your brand voice? (Be as specific as possible — e.g., 'educational but casual, like explaining things to a smart friend', 'professional thought leader in fintech', 'funny and irreverent tech commentary')"

3. "Who is your target audience? (e.g., 'developers aged 25–40 interested in AI', 'small business owners', 'fitness enthusiasts')"

## Step 3: Generate Artifacts

### CLAUDE.md

```markdown
# Claude Instructions — Content Creation

## Brand
Platform(s): [answer 1]
Brand voice: [answer 2]
Target audience: [answer 3]

## Guidelines
- Always write in the specified brand voice — never sound generic or AI-generated
- For YouTube scripts: Hook (first 30 seconds), problem setup, solution walkthrough, call to action
- For short-form: Hook in first line, one idea per post, strong ending or question
- For newsletters: subject line suggestion, personal opener, one core idea, actionable takeaway
- Repurposing: when asked to repurpose content, adapt format and length for the target platform — do not just copy-paste
- Suggest content ideas proactively when given a topic, not just one option

[Include ONLY if Superpowers installed]
Superpowers is installed. For ideation sessions, use superpowers:brainstorming to explore angles before committing to a direction.
```

### .gitignore

```gitignore
# Large media files
*.mp4
*.mov
*.avi
*.psd
*.ai
*.sketch
*.fig
.DS_Store
Thumbs.db
```

## Step 4: Completion Summary

```
✓ Content Creator setup complete!

Files created:
  CLAUDE.md — brand voice, platform, and audience instructions
  .gitignore — media file rules

Next steps:
  Start a new Claude session and say: "Give me 5 video ideas about [your topic]"
  Or: "Write a YouTube script about [topic] in my brand voice"
```
```

- [ ] **Step 2: Commit**

```bash
git add skills/content-creator-setup/SKILL.md
git commit -m "feat: add content creator setup skill"
```

---

## Task 10: Repo Config Files (CLAUDE.md, AGENTS.md, CONTRIBUTING.md)

These files describe how to develop and contribute to **this plugin's own repo** — not files generated for users.

**Files:**
- Create: `CLAUDE.md`
- Create: `AGENTS.md`
- Create: `CONTRIBUTING.md`

- [ ] **Step 1: Create CLAUDE.md (for this repo)**

```markdown
# Claude Onboarding Agent — Development Instructions

## What This Repo Is
A Claude Code plugin with 6 skills. Skills are markdown files in `skills/*/SKILL.md`. The plugin generates configuration files (CLAUDE.md, AGENTS.md, etc.) in users' projects.

## Key Paths
- `skills/` — all 6 skill files
- `docs/superpowers/specs/` — design documents
- `docs/superpowers/plans/` — implementation plans
- `scripts/install.sh` — GitHub installation script
- `.claude-plugin/plugin.json` — plugin manifest

## Adding a New Skill
1. Create `skills/[skill-name]/SKILL.md`
2. Follow the pattern from existing skills: language detection, handoff context, installation method, context questions, artifact generation, completion summary
3. Add the new slash command to `.claude-plugin/plugin.json`
4. Update `skills/onboarding/SKILL.md` to include the new path
5. Update `README.md`

## Spec
See `docs/superpowers/specs/2026-04-16-onboarding-agent-design.md` for full design decisions.
```

- [ ] **Step 2: Create AGENTS.md (for this repo)**

```markdown
# Agent Roles — Claude Onboarding Agent Development

## skill-writer
Writes and edits SKILL.md files. Follows the skill pattern: frontmatter, language detection, handoff context, steps, artifact generation, completion summary. Reads the spec before modifying any skill.

## reviewer
Reviews SKILL.md files against the spec. Checks: does the skill handle all edge cases from the spec? Is the completion summary complete? Are failure paths handled?

## release-agent
Updates RELEASE-NOTES.md, bumps version in plugin.json, creates git tag.
```

- [ ] **Step 3: Create CONTRIBUTING.md**

```markdown
# Contributing to Claude Onboarding Agent

Thank you for your interest in contributing!

## Adding a New Setup Skill

1. **Fork and clone** this repository
2. **Create the skill directory:** `skills/[your-skill-name]/`
3. **Write `SKILL.md`** following the existing skill pattern:
   - YAML frontmatter with `name` and `description`
   - Language detection section
   - Handoff context section  
   - Optional: Superpowers installation step
   - 3–7 context questions (one at a time)
   - Artifact generation (at minimum: CLAUDE.md)
   - Completion summary
4. **Update the orchestrator:** Add your skill as an option in `skills/onboarding/SKILL.md`
5. **Update README.md** with a description of the new skill
6. **Open a pull request** with a description of the use case your skill serves

## Improving Existing Skills

Open an issue first to discuss the change, then submit a PR with a clear description.

## Standards

- All skill content in English
- Skills detect user language at runtime and respond accordingly
- Superpowers installation is always offered (never mandatory in new skills — only Coding Setup and Knowledge Base Builder install it without asking)
- Every skill must handle the case where external dependency installation fails
```

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md AGENTS.md CONTRIBUTING.md
git commit -m "docs: add repo development instructions and contributing guide"
```

---

## Task 11: README.md

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write README.md**

```markdown
# Claude Onboarding Agent

**Claude is powerful. But only if set up right.**

Most people start a new Claude session and just... start typing. No context, no workflow, no structure. The results are inconsistent, the setup is forgotten the next time, and Claude never really learns how you work.

This plugin fixes that. Run `/onboarding` once and Claude will ask you a few questions, then automatically generate everything you need: a tailored `CLAUDE.md`, subagent role definitions, tool permissions, and workflow instructions — based on exactly how you plan to use it.

Already know what you need? Call the setup skills directly.

---

## What's Inside

| Skill | Command | Description |
|-------|---------|-------------|
| Onboarding Orchestrator | `/onboarding` | Scans your repo, infers your use case, guides you to the right setup |
| Coding Setup | `/coding-setup` | Installs Superpowers, sets up iterative dev workflow (brainstorm → plan → subagents → review → commit) |
| Knowledge Base Builder | `/build-knowledge-base` | Builds a Karpathy-pattern wiki from your codebase or notes, with optional Obsidian MCP integration |
| Office Setup | `/office-setup` | Configures writing style, document preferences, and company context |
| Research Setup | `/research-setup` | Sets up citation format, research domain, and academic writing guidelines |
| Content Creator Setup | `/content-creator-setup` | Configures brand voice, platform preferences, and audience context |

---

## Installation

### Option 1: Plugin Marketplace (recommended)

```
/plugin install claude-onboarding-agent
```

### Option 2: GitHub

```bash
curl -fsSL https://raw.githubusercontent.com/a2ngerer/claude_onboarding_agent/main/scripts/install.sh | bash
```

Or manually:

```bash
git clone https://github.com/a2ngerer/claude_onboarding_agent.git ~/.claude/plugins/claude-onboarding-agent
```

---

## How It Works

```
/onboarding
     │
     ▼
Scan repo → detect files, manifests, existing config
     │
     ▼
Suggest most likely use case (or ask if empty repo)
     │
     ├── Coding Setup ──────────────────────────────────────────────┐
     ├── Knowledge Base Builder ──────────────────────────────────┐ │
     ├── Office Setup ────────────────────────────────────────┐   │ │
     ├── Research Setup ────────────────────────────────────┐ │   │ │
     └── Content Creator Setup ────────────────────────┐   │ │   │ │
                                                        ▼   ▼ ▼   ▼ ▼
                                               Ask 3–7 context questions
                                                        │
                                                        ▼
                                           Install Superpowers (+ more)
                                                        │
                                                        ▼
                                        Generate CLAUDE.md + config files
                                                        │
                                                        ▼
                                              Print completion summary
```

**Already know what you want?** Skip the orchestrator and call the skill directly:

```
/coding-setup
/build-knowledge-base
/office-setup
/research-setup
/content-creator-setup
```

---

## What Gets Generated

Every setup skill generates a tailored `CLAUDE.md` for your project. Coding and Knowledge Base setups also install [Superpowers](https://github.com/obra/superpowers) — a proven Claude Code workflow library with 94,000+ users — and add structured workflow instructions that make every future Claude session more reliable.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add new setup skills.

---

## License

MIT — see [LICENSE](LICENSE)
```

- [ ] **Step 2: Verify all links in README exist**

Check that CONTRIBUTING.md and LICENSE exist in the repo.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: add README with full feature overview and installation instructions"
```

---

## Task 12: Push to GitHub

- [ ] **Step 1: Verify all expected files exist**

```bash
ls -la
ls skills/*/
```

Expected files: `.claude-plugin/plugin.json`, `skills/*/SKILL.md` (6 files), `scripts/install.sh`, `README.md`, `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `LICENSE`, `RELEASE-NOTES.md`, `.gitignore`

- [ ] **Step 2: Check git log**

```bash
git log --oneline
```

Expected: 10+ commits covering all tasks above.

- [ ] **Step 3: Set remote and push**

```bash
git remote add origin git@github.com:a2ngerer/claude_onboarding_agent.git
git branch -M main
git push -u origin main
```

- [ ] **Step 4: Verify on GitHub**

Open `https://github.com/a2ngerer/claude_onboarding_agent` and confirm:
- All files visible
- README renders correctly
- Skills directory shows all 6 skill folders

---

## Completion Checklist

- [ ] Task 1: Repo scaffolding (LICENSE, .gitignore, RELEASE-NOTES.md, CODE_OF_CONDUCT.md)
- [ ] Task 2: Plugin manifest (.claude-plugin/plugin.json)
- [ ] Task 3: Install script (scripts/install.sh)
- [ ] Task 4: Onboarding orchestrator skill
- [ ] Task 5: Coding setup skill
- [ ] Task 6: Knowledge base builder skill
- [ ] Task 7: Office setup skill
- [ ] Task 8: Research setup skill
- [ ] Task 9: Content creator setup skill
- [ ] Task 10: Repo config files (CLAUDE.md, AGENTS.md, CONTRIBUTING.md)
- [ ] Task 11: README.md
- [ ] Task 12: Push to GitHub
