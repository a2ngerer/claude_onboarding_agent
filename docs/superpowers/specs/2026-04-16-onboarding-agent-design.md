# Claude Onboarding Agent — Design Spec
**Date:** 2026-04-16  
**Status:** Approved

---

## Overview

A Claude Code plugin that guides new users through a personalized setup process, automatically generating all necessary configuration files (CLAUDE.md, AGENTS.md, hooks, .claudeignore etc.) based on their use case. Experienced users can call individual setup skills directly without going through the orchestrator.

---

## Architecture

### Approach: Orchestrator + Independent Setup Skills

A lightweight `onboarding` orchestrator skill scans the current repo, infers the most likely use case, and dispatches to one of 5 specialized setup skills. Each setup skill is fully standalone — callable directly via slash command without the orchestrator.

### Skill List

| Slash Command | Skill | Description |
|---|---|---|
| `/onboarding` | `onboarding` | Orchestrator — scans repo, suggests path, dispatches |
| `/coding-setup` | `coding-setup` | Dev workflow with Superpowers + iterative coding methodology |
| `/build-knowledge-base` | `knowledge-base-builder` | Karpathy-pattern wiki from codebases or notes → Obsidian |
| `/office-setup` | `office-setup` | Email, meetings, reports, business productivity |
| `/research-setup` | `research-setup` | Literature, papers, academic writing |
| `/content-creator-setup` | `content-creator-setup` | Social media, YouTube, newsletters |

---

## Orchestrator Flow

1. **Detect language** from first user message — all subsequent communication in that language
2. **Scan repository** (shallow): dominant file types, package manifests (package.json, pyproject.toml, Cargo.toml, go.mod), existing CLAUDE.md/AGENTS.md, notes/vault folders, office documents (.docx, .pptx, .pdf), academic files (.tex, .bib)
3. **Infer most likely path** → place at position 1 with a short explanation ("Looks like a Python project — suggesting Coding Setup")
4. **Present all 5 options** — inferred path first, plus "Not sure — help me decide"
5. **User selects path** → orchestrator dispatches and steps back

### Edge Cases
- **Existing CLAUDE.md detected:** Orchestrator warns the user, offers to extend (append a new section) rather than overwrite. Extension is in scope for v1. Mechanism: the setup skill reads the existing file, appends a clearly delimited new section (`## Claude Onboarding Agent — [Use Case]`), never modifies existing content above it.
- **Empty repo:** All 5 paths listed equally, "Not sure — help me decide" prominent at top.

### "Not sure — help me decide" Flow
The orchestrator asks 3 yes/no questions:
1. "Are you primarily using Claude for writing code or working with a codebase?" → yes → Coding Setup
2. "Are you trying to build a structured knowledge base or wiki from documents/notes/code?" → yes → Knowledge Base Builder
3. "Do you work mostly with documents, emails, reports, or presentations?" → yes → Office Setup

If no answer matches after 3 questions → default to presenting all 5 options with brief descriptions for manual selection.

---

## Orchestrator → Skill Handoff Contract

When the orchestrator dispatches to a setup skill, it passes the following context as part of the invocation prompt (not via files or environment variables — Claude passes it inline as skill input):

```
HANDOFF_CONTEXT:
  detected_language: "de"           # ISO 639-1 code
  existing_claude_md: true/false    # whether CLAUDE.md was found
  inferred_use_case: "coding"       # the orchestrator's inference (informational only)
  repo_signals: ["pyproject.toml", "*.py files"] # what triggered the inference
```

When a setup skill is called **directly** (bypassing the orchestrator), it detects language independently from the user's first message and assumes no existing CLAUDE.md unless it finds one by reading the filesystem.

---

## Setup Skill Flow (all 5 skills follow this pattern)

1. **Language:** Use `detected_language` from handoff context, or detect from first user message if called directly
2. **Existing CLAUDE.md check:** Use handoff context or read filesystem if called directly
3. **Installation method question:** "How would you like to install external skills like Superpowers? A) Plugin Marketplace (recommended, one command) B) GitHub (more control, works offline after clone)"
4. **Use-case-specific context questions** (3–7 questions, see per-skill section below)
5. **Install external dependencies** with explicit verification:
   - Run install command
   - Verify success (check for expected files/commands)
   - If verification fails: warn the user clearly, do NOT write dependency-dependent instructions into CLAUDE.md, offer to continue without that dependency or abort
6. **Generate artifacts** fully automatically
7. **Print completion summary** of everything that was set up, including any skipped dependencies

---

## Installation Method: What Changes

### Option A — Plugin Marketplace
```
/plugin install superpowers@claude-plugins-official
```
Verification: Check that `/superpowers` skill responds after install.

### Option B — GitHub
```bash
git clone https://github.com/obra/superpowers ~/.claude/plugins/superpowers
```
`scripts/install.sh` automates this. It:
1. Detects the OS and shell
2. Creates `~/.claude/plugins/` if it does not exist
3. Clones the target repo(s)
4. Prints confirmation of what was installed and where

Verification: Check that the cloned directory exists and contains expected skill files.

Both paths result in functionally identical skills. CLAUDE.md content is the same regardless of installation method.

---

## Generated Artifacts

### All Paths
- `CLAUDE.md` — tailored to use case and answered context questions
- `.gitignore` — use-case-appropriate (see per-path definitions below)

### Coding Setup — Additional Artifacts
- `AGENTS.md` — subagent role definitions: coder, reviewer, git-agent
- `.claude/settings.json` — allowed tools and hooks
- **CLAUDE.md includes:**
  - Superpowers `using-superpowers` skill required at start of every new conversation *(only written if Superpowers installation was verified)*
  - Iterative workflow: brainstorm → write-plan → subagents → code-review → commit
  - Stack-specific instructions (from context questions)
- **.gitignore:** standard for detected stack (Node: node_modules/, Python: __pycache__/ .venv/, etc.) + `.claude/` secrets

### Knowledge Base Builder — Additional Artifacts
- **CLAUDE.md includes:**
  - Superpowers `using-superpowers` required at start of every new conversation *(only if verified)*
  - Karpathy-pattern instructions: maintain `raw/` for source material, `wiki/` for organized notes, every wiki note has a one-line summary and tags, notes link to related notes using `[[wikilinks]]`
  - Instructions for ingesting new sources: read raw file → extract key concepts → create/update wiki note → link to related notes
- **Obsidian MCP config** (if user has Obsidian + chooses MCP path): adds MCP server entry to `.claude/settings.json` pointing to the Obsidian vault path
- **Folder structure** (fallback or if Obsidian not installed): creates `raw/` and `wiki/` directories with a `wiki/README.md` explaining the structure
- **Karpathy Guidelines skill** (from `forrestchang/andrej-karpathy-skills`): installed via chosen method, adds four coding principles to CLAUDE.md context
- **.gitignore:** excludes `raw/` large files (*.pdf, *.docx), keeps `wiki/` tracked

### Office Setup — Additional Artifacts
- **CLAUDE.md includes:** writing style preferences (tone, formality, language), common document types used, company/team context (from context questions)
- **.gitignore:** excludes *.tmp, ~$* (Office lock files), .DS_Store

### Research Setup — Additional Artifacts
- **CLAUDE.md includes:** academic writing style, citation format preference, research domain context
- **.gitignore:** excludes *.aux, *.log, *.bbl (LaTeX artifacts if applicable), large PDF files

### Content Creator Setup — Additional Artifacts
- **CLAUDE.md includes:** brand voice, target platforms, content formats, audience description
- **.gitignore:** excludes large media files (*.mp4, *.mov, *.psd, *.ai)

---

## Superpowers Integration

| Path | Superpowers Behavior |
|---|---|
| Coding Setup | Always installed (no question), mandatory for CLAUDE.md instruction |
| Knowledge Base Builder | Always installed (no question), mandatory for CLAUDE.md instruction |
| Office Setup | Agent explains benefits, user decides |
| Research Setup | Agent explains benefits, user decides |
| Content Creator Setup | Agent explains benefits, user decides |

**Failure handling for mandatory paths:** If Superpowers installation fails, the skill warns the user, skips the `using-superpowers` CLAUDE.md instruction, and completes setup with everything else. It prints a clear note in the summary: "⚠ Superpowers installation failed — please install manually and add [instruction] to your CLAUDE.md."

---

## Context Questions Per Skill

### Coding Setup (4 questions)
1. What is your primary programming language / stack?
2. Do you work solo or in a team?
3. Do you use GitHub, GitLab, or another git host?
4. Which IDE? (VS Code / JetBrains / Neovim / other)

### Knowledge Base Builder (4 questions)
1. Are you documenting an existing codebase, personal notes, or both?
2. Do you have Obsidian installed? (→ if yes: recommend MCP, explain it enables direct vault writing; if no: explain markdown fallback works fine but MCP opens more doors)
3. What is the path to your target folder / Obsidian vault?
4. What language are your sources in?

### Office Setup (3 questions)
1. What types of documents do you create most? (emails / reports / presentations / all)
2. What is your preferred writing style? (formal / semi-formal / casual)
3. Any company or team context Claude should always know? (optional)

### Research Setup (3 questions)
1. What is your research domain?
2. What citation format do you use? (APA / MLA / Chicago / other)
3. Do you write in LaTeX or Word/Google Docs?

### Content Creator Setup (3 questions)
1. What platforms do you primarily create for? (YouTube / Instagram / newsletter / blog / all)
2. How would you describe your brand voice? (e.g., professional, casual, educational, entertaining)
3. Who is your target audience?

---

## External Skills Sourced From

- **Superpowers:** `obra/superpowers` — via `/plugin install superpowers@claude-plugins-official` or GitHub clone
- **Karpathy Guidelines:** `forrestchang/andrej-karpathy-skills` — optional, used in Knowledge Base Builder path

---

## Repository Structure

**Note:** Files at the repo root (CLAUDE.md, AGENTS.md, .gitignore) are for developing this plugin itself. They are distinct from the artifacts that setup skills generate in the user's project.

```
claude_onboarding_agent/
├── .claude-plugin/
│   └── plugin.json             ← Plugin manifest (Claude Code plugin format)
│                                 Required fields: name, version, description,
│                                 skills[], commands[], homepage_url
├── .claude/
│   └── commands/               ← Slash-command definitions (checked into git)
├── skills/
│   ├── onboarding/
│   │   └── SKILL.md            ← Orchestrator skill content
│   ├── coding-setup/
│   │   └── SKILL.md
│   ├── knowledge-base-builder/
│   │   └── SKILL.md
│   ├── office-setup/
│   │   └── SKILL.md
│   ├── research-setup/
│   │   └── SKILL.md
│   └── content-creator-setup/
│       └── SKILL.md
├── docs/
│   └── superpowers/specs/      ← Design documents
├── scripts/
│   └── install.sh              ← GitHub installation script (clones plugin to ~/.claude/plugins/)
├── README.md
├── CLAUDE.md                   ← Instructions for developing this repo (not generated for users)
├── AGENTS.md                   ← Agent guidance for this repo (not generated for users)
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── LICENSE                     ← MIT
├── RELEASE-NOTES.md
└── .gitignore                  ← For this plugin's own development
```

---

## README Structure (for maximum discoverability)

1. **Problem Statement** — "Claude is powerful, but only if set up right"
2. **What's Inside** — the 5 setup skills with one-line descriptions
3. **Installation** — Plugin Marketplace (one command) + GitHub (clone)
4. **How It Works** — orchestrator flow with ASCII visualization
5. **Direct Skill Usage** — for users who know what they want
6. **Contributing**
7. **License & Community**

---

## Language Handling

All skill content (prompts, instructions, SKILL.md files) is written in English. At runtime, language is detected from the user's first message. All responses and generated file content comments are in the detected language. Generated CLAUDE.md technical field names (keys, paths, tool names) remain in English regardless of language.

---

## Non-Goals (v1)

- No CI/CD integration
- No automatic silent overwrite of existing CLAUDE.md (extension only, with explicit section delimiter)
- No multi-skill chaining beyond orchestrator → single setup skill
- No GUI beyond Claude's terminal interface
- No telemetry or usage tracking
