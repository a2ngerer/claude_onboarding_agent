---
name: knowledge-base-builder
description: Set up Claude to build and maintain a structured knowledge base using the Karpathy LLM Wiki pattern — works with codebases, personal notes, or both. Supports Obsidian MCP for direct vault integration.
---

# Knowledge Base Builder

This skill configures Claude to build and maintain a structured, interlinked knowledge base using the Karpathy LLM Wiki pattern.

**Language:** Use `detected_language` from handoff context, or detect from the user's first message and use it throughout.

**Existing CLAUDE.md:** If `existing_claude_md: true` in handoff context, or if CLAUDE.md exists in the filesystem, extend it by appending a new section (`## Claude Onboarding Agent — Knowledge Base`) rather than overwriting.

## Step 1: Installation Method

Ask the user:

> "How would you like to install Superpowers and the Karpathy Guidelines — the skill libraries this setup uses?
>
> **A) Plugin Marketplace** (recommended) — one command each
> **B) GitHub** — clone directly from their repositories (more control, works offline after clone)"

Store as `install_method`.

## Step 2: Context Questions

Ask one at a time, waiting for each answer:

1. "What are you primarily building this knowledge base from?
   A) An existing codebase
   B) Personal notes and documents
   C) Both"

2. "Do you have Obsidian installed?

   Obsidian is a free, local-first markdown editor with graph view and wiki-style linking. With the Obsidian MCP integration, Claude can write notes directly into your Obsidian vault — creating a richer, more connected knowledge base with automatic backlinks and graph visualization.

   Without Obsidian, Claude creates well-organized markdown files you can open in any text editor — this works great and unlocks the same core workflow.

   **Recommendation: Option A opens more doors** — the Obsidian graph view makes it much easier to navigate a large knowledge base.

   A) Yes, I have Obsidian installed — set up the MCP integration
   B) No / skip for now — use plain markdown files"

3. "What is the path to your target folder?
   - Obsidian users: your vault path (e.g., `/Users/you/Documents/MyVault`)
   - Others: any folder you choose (e.g., `~/my-wiki`)"

4. "What language are your source files in? (for code: the programming language; for notes: the human language, e.g., English, German)"

## Step 3: Install Dependencies

### Install Superpowers

**If Plugin Marketplace:**
```
/plugin install superpowers@claude-plugins-official
```

**If GitHub:**
```bash
git clone https://github.com/obra/superpowers ~/.claude/plugins/superpowers
```

Verify: check that `~/.claude/plugins/superpowers/skills/` exists. On failure: warn the user, set `superpowers_installed: false`, continue.

### Install Karpathy Guidelines

**If Plugin Marketplace:**
```
/plugin install andrej-karpathy-skills
```

**If GitHub:**
```bash
git clone https://github.com/forrestchang/andrej-karpathy-skills ~/.claude/plugins/karpathy-skills
```

Verify: check that the directory exists. On failure: warn and continue — this is an optional enhancement.

### Set Up Obsidian MCP (only if user chose Option A in question 2)

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

Inform the user: "The Obsidian MCP server is configured. Make sure Obsidian is open when using Claude for knowledge base tasks — Claude writes directly into your vault."

## Step 4: Generate Artifacts

### Folder Structure

Create the following in the target path from question 3:
```
[target_path]/
├── raw/          ← drop source material here (articles, code files, PDFs, notes)
└── wiki/
    └── README.md ← overview of the wiki structure
```

`wiki/README.md`:
```markdown
# Knowledge Base

Built with Claude using the Karpathy LLM Wiki pattern.

## How to Use

**Adding sources:** Drop files into `raw/`. Then ask Claude: "Ingest the new files in raw/ and update the wiki."

**Wiki structure:** Each note in `wiki/` covers one concept, person, project, or topic. Notes link to related notes using [[wikilinks]].

**Note format:**
- First line: one-sentence summary
- Second line: `tags: #topic #subtopic`
- Body: structured content with headers
- Last section: `## Related: [[linked-note-1]], [[linked-note-2]]`
```

### CLAUDE.md

```markdown
# Claude Instructions — Knowledge Base

## Setup
Target path: [answer from Q3]
Source material: [answer from Q1]
Source language: [answer from Q4]

## Workflow — Karpathy LLM Wiki Pattern
[Include ONLY if superpowers_installed is true]
At the start of every new conversation, invoke the `using-superpowers` skill.

### Structure
- `raw/` — source material (never modify files here)
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
2. Note: purpose, public API, key dependencies, important design decisions
3. Link to notes about dependencies
4. Maintain a `wiki/architecture.md` overview that links to all component notes

## Obsidian
[Include if MCP was configured] Obsidian MCP is active. Claude writes directly into your vault when Obsidian is open.
[Include if plain markdown] Using plain markdown files. Open the wiki/ folder in Obsidian or any markdown editor.
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

# Claude local settings
.claude/settings.local.json
```

## Step 5: Completion Summary

```
✓ Knowledge Base setup complete!

Files created:
  CLAUDE.md                    — Karpathy-pattern workflow instructions
  [target]/raw/                — drop source material here
  [target]/wiki/               — your knowledge base will be built here
  [target]/wiki/README.md      — how to use your knowledge base
  [if Obsidian MCP] .claude/settings.json — Obsidian MCP configured
  .gitignore                   — excludes large source files

External skills:
  [✓/⚠] Superpowers [via method / failed — install manually]
  [✓/⚠] Karpathy Guidelines [via method / failed — optional, skipped]
  [✓ Obsidian MCP configured / using plain markdown files]

Next steps:
  Drop files into [target]/raw/
  Start a new Claude session and say: "Ingest the files in raw/ and build the wiki"
```
