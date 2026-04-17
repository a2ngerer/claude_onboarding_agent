---
name: knowledge-base-builder
description: Set up Claude to build and maintain a structured knowledge base using the Karpathy LLM Wiki pattern — works with codebases, personal notes, or both. Supports Obsidian MCP for direct vault integration.
---

# Knowledge Base Builder

This skill configures Claude to build and maintain a structured, interlinked knowledge base using the Karpathy LLM Wiki pattern.

**Language:** Use `detected_language` from handoff context, or detect from the user's first message and use it throughout.

**Existing CLAUDE.md:** If `existing_claude_md: true` in handoff context, or if CLAUDE.md exists in the filesystem, extend it by appending a new section (`## Claude Onboarding Agent — Knowledge Base`) rather than overwriting.

## Step 1: Install Dependencies

Read `skills/_shared/installation-protocol.md` and follow it for each dependency below.

Note: Process Superpowers and Karpathy Guidelines here. The Obsidian MCP is conditional on the user's answer in Step 2 — process it immediately after Step 2, question 2.

Dependencies:
- Superpowers (required) — marketplace-id: `superpowers@claude-plugins-official`, github: `https://github.com/obra/superpowers`, name: `superpowers`
- Karpathy Guidelines (optional) — github only: `https://github.com/forrestchang/andrej-karpathy-skills`, name: `karpathy-skills`

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

   After the user answers question 2: if they chose Option A (Obsidian), immediately run the installation protocol for:
   - Obsidian MCP (conditional: true — always project-local, configured via settings.json not plugin install)
     - Already-installed check: look for `obsidian` key in `.claude/settings.json` under `mcpServers`
     - If not found: add the following to `.claude/settings.json`:
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
     - Set `obsidian_mcp_installed: true` on success, `false` on failure

3. "What is the path to your target folder?
   - Obsidian users: your vault path (e.g., `/Users/you/Documents/MyVault`)
   - Others: any folder you choose (e.g., `~/my-wiki`)"

4. "What language are your source files in? (for code: the programming language; for notes: the human language, e.g., English, German)"

## Step 3: Generate Artifacts

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

## Step 4: Completion Summary

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
  [✓/⚠] Superpowers [via superpowers_method (superpowers_scope) / failed — install manually]
  [✓/⚠] Karpathy Guidelines [via karpathy_method (karpathy_scope) / failed — optional, skipped]
  [✓ Obsidian MCP configured / using plain markdown files]

Next steps:
  Drop files into [target]/raw/
  Start a new Claude session and say: "Ingest the files in raw/ and build the wiki"
```
