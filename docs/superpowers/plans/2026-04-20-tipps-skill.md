# Tipps Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `onboarding-agent:tipps` skill — a standalone Claude setup auditor that prints a prioritized, actionable list of improvement suggestions.

**Architecture:** A single SKILL.md runs four named category passes (Claude Config, Git Hygiene, Project Tooling, MCP & Skills), collects findings in LLM context, then prints them sorted HIGH → MEDIUM → LOW. No file writes; suggest-only. Plain-text output allows `/checkup` to read findings via LLM conversation context without any structured contract.

**Tech Stack:** Markdown skill files (LLM-orchestrated), JSON (plugin.json)

---

## File Map

| Action | Path | Responsibility |
|---|---|---|
| Create | `skills/tipps/SKILL.md` | Core skill: language detection, 4 passes, output format |
| Modify | `.claude-plugin/plugin.json` | Register skill + slash command |
| Modify | `skills/onboarding/SKILL.md` | Add `/tipps` as option in Step 3 and Step 5 |
| Modify | `README.md` | Add row to "What's Inside" table |

---

## Task 1: Create `skills/tipps/SKILL.md`

**Files:**
- Create: `skills/tipps/SKILL.md`

- [ ] **Step 1: Create the file with the following exact content**

```markdown
---
name: tipps
description: Audit your current Claude setup and get a prioritized list of improvement suggestions — package manager hygiene, CLAUDE.md quality, permissions, git hygiene, MCP servers, and more.
---

# Tipps — Claude Setup Audit

Audit the current Claude setup and print a prioritized, actionable list of improvement suggestions.

**Language:** Detect language from the user's first message and respond in it throughout. All file content and finding text stays in English.

**Entry:** Run all four passes silently first. Collect every finding in context. Print once at the end, sorted HIGH → MEDIUM → LOW. Do not print pass-by-pass intermediate output.

---

## Pass 1 — Claude Config

Read these files if they exist: `CLAUDE.md`, `AGENTS.md`, `.claude/settings.json`. Skip any check whose required file is absent.

**Check 1.1 — Secrets in CLAUDE.md** `[HIGH]`
Condition: `CLAUDE.md` contains patterns that look like secrets — API keys (strings matching `sk-`, `ghp_`, `AIza`, `xox`), passwords (lines containing `password =` or `password:`), bearer tokens, or email addresses outside a comment.
Finding title: "Potential secret or personal data in CLAUDE.md"
Why: CLAUDE.md is often committed to version control. Secrets in it can be leaked publicly.
How to apply: Move secrets to `.env` or a secrets manager. Remove personal data from CLAUDE.md.

**Check 1.2 — Overly broad permissions** `[HIGH]`
Condition: `.claude/settings.json` exists and its `permissions.allow` array contains the string `"*"` or `"Bash(*)"`.
Finding title: "Overly broad tool permissions in settings.json"
Why: A wildcard allow entry lets any tool run without confirmation — including destructive ones.
How to apply: Replace `"*"` with an explicit allowedTools list. Run `/fewer-permission-prompts` to generate one.

**Check 1.3 — CLAUDE.md length** `[MEDIUM]`
Condition: `CLAUDE.md` exists and has more than 40 lines.
Finding title: "CLAUDE.md is [N] lines — aim for under 40"
Why: Long CLAUDE.md files dilute signal. Claude reads the whole file every turn; every extra line competes with the instructions that matter.
How to apply: Trim to pointers and principles. Move detail into referenced files or inline comments in the codebase.

**Check 1.4 — No allowedTools entries** `[MEDIUM]`
Condition: `.claude/settings.json` exists but `permissions.allow` is absent or an empty array.
Finding title: "No allowedTools configured in settings.json"
Why: Without an allowlist, every tool call prompts for permission — creating friction and making automation impossible.
How to apply: Run `/fewer-permission-prompts` to generate a minimal allowlist from your session history.

**Check 1.5 — No section delimiters in CLAUDE.md** `[LOW]`
Condition: `CLAUDE.md` exists and does not contain the string `<!-- onboarding-agent:start -->`.
Finding title: "CLAUDE.md has no section delimiters"
Why: Section delimiters allow `/upgrade` to make targeted edits to specific sections without touching the rest of the file.
How to apply: Add `<!-- onboarding-agent:start -->` and `<!-- onboarding-agent:end -->` around each generated section.

---

## Pass 2 — Git Hygiene

Check for `.git/` directory. If absent, skip this entire pass without mentioning it.

**Check 2.1 — Claude artifacts not gitignored** `[MEDIUM]`
Condition: `.gitignore` does not contain `.claude/` or `*.claude-*` (check both).
Finding title: "Claude artifacts not in .gitignore"
Why: `.claude/settings.local.json` and session files may contain local paths or tokens that should not be committed.
How to apply: Add these lines to `.gitignore`:
```
.claude/settings.local.json
*.claude-*
```

**Check 2.2 — No pre-commit hook** `[LOW]`
Condition: `.git/hooks/pre-commit` does not exist.
Finding title: "No pre-commit hook found"
Why: Pre-commit hooks catch formatting and lint errors before they reach CI.
How to apply: For Python: `pip install pre-commit && pre-commit install`. For Node: `npm install --save-dev husky && npx husky init`.

---

## Pass 3 — Project Tooling

Check for manifest files: `package.json`, `pyproject.toml`, `requirements.txt`, `Cargo.toml`, `go.mod`. If none exist, skip this entire pass without mentioning it.

Detect primary stack from the first manifest found:
- `pyproject.toml` or `requirements.txt` → Python
- `package.json` → Node
- `Cargo.toml` → Rust
- `go.mod` → Go

**Check 3.1 — Python: requirements.txt without uv** `[MEDIUM]`
Condition: Stack is Python AND `requirements.txt` exists AND `pyproject.toml` is absent.
Finding title: "Python project using requirements.txt — consider uv"
Why: `uv` is significantly faster than pip and produces a reproducible lockfile (`uv.lock`). `pyproject.toml` is the modern standard for Python project metadata.
How to apply: `pip install uv && uv init`. Then replace `requirements.txt` with `uv add <package>` calls.

**Check 3.2 — No linter configured** `[MEDIUM]`
Condition (Python): No `ruff.toml`, no `.flake8`, and `ruff` not present in `pyproject.toml` deps.
Condition (Node): No `.eslintrc`, no `.eslintrc.js`, no `.eslintrc.json`, no `biome.json`.
Condition (Rust): `clippy` is always available via `cargo clippy` — skip this check for Rust.
Condition (Go): `golangci-lint` not present in any config file — skip if not detectable.
Finding title: "No linter configured for [stack]"
Why: A linter catches bugs and enforces consistency automatically on every save or CI run.
How to apply (Python): `uv add --dev ruff` then add `[tool.ruff]` to `pyproject.toml`.
How to apply (Node): `npm install --save-dev eslint && npx eslint --init`.

**Check 3.3 — Node: npm lockfile instead of pnpm/bun** `[LOW]`
Condition: Stack is Node AND `package-lock.json` exists.
Finding title: "Using npm — pnpm or bun would be faster"
Why: `pnpm` uses a content-addressable store (saves disk space, faster installs). `bun` is significantly faster for most projects.
How to apply: `npm install -g pnpm && pnpm import` (converts existing lockfile). Or: `curl -fsSL https://bun.sh/install | bash`.

**Check 3.4 — Node: no TypeScript** `[LOW]`
Condition: Stack is Node AND `tsconfig.json` is absent AND more than 5 `.js` files exist in the project root or `src/`.
Finding title: "JavaScript project with no TypeScript"
Why: TypeScript catches type errors at compile time and dramatically improves IDE support for non-trivial projects.
How to apply: `npm install --save-dev typescript && npx tsc --init`.

---

## Pass 4 — MCP & Skills

Read `.claude/settings.json` if it exists.

**Check 4.1 — fewer-permission-prompts not installed** `[MEDIUM]`
Condition: The `plugins` section of settings.json does not contain `fewer-permission-prompts`, AND `permissions.allow` has fewer than 3 entries (or is absent).
Finding title: "fewer-permission-prompts skill not installed"
Why: This skill scans your session history and generates a minimal allowlist, reducing permission prompts without granting broad access.
How to apply: `/plugin install fewer-permission-prompts@claude-plugins-official`

**Check 4.2 — MCP servers without description** `[LOW]`
Condition: `mcpServers` in settings.json has one or more entries that lack a `"description"` field.
Finding title: "MCP server(s) have no description"
Why: Descriptions help Claude understand when to use each server, improving tool selection.
How to apply: Add a `"description": "..."` field to each MCP server entry in `.claude/settings.json`.

**Check 4.3 — Skills mismatched to project type** `[LOW]`
Condition: Installed skills (from settings.json plugins list) include a setup skill clearly mismatched to the detected project. Examples: `devops-setup` in a project with only frontend files; `research-setup` in a project with only code files.
Finding title: "Installed skill may not match your project type"
Why: Unused setup skills add noise to Claude's context without providing value.
How to apply: Remove unused skills via `/plugin uninstall <skill-name>`.

---

## Output

After all four passes, print the following block. Do not print anything before it.

```
## Claude Setup Audit

Scanned: [comma-separated list of files that were actually read]
Passes: [comma-separated list of passes that ran — omit any that were skipped]

---

[findings sorted HIGH first, then MEDIUM, then LOW; within each severity in pass order]

[HIGH] [Finding title]
Why: [why text]
How to apply: [how text]

[MEDIUM] [Finding title]
Why: [why text]
How to apply: [how text]

[LOW] [Finding title]
Why: [why text]
How to apply: [how text]

---
[N] finding(s): [X] HIGH · [Y] MEDIUM · [Z] LOW
```

If no findings at all: print exactly:
```
Your Claude setup looks clean — nothing to improve right now.
```
```

- [ ] **Step 2: Verify the file was created**

```bash
wc -l skills/tipps/SKILL.md
```
Expected: line count > 50

- [ ] **Step 3: Commit**

```bash
git add skills/tipps/SKILL.md
git commit -m "feat(tipps): add tipps skill — Claude setup auditor"
```

---

## Task 2: Register in `.claude-plugin/plugin.json`

**Files:**
- Modify: `.claude-plugin/plugin.json`

- [ ] **Step 1: Read the current file**

```bash
cat .claude-plugin/plugin.json
```

- [ ] **Step 2: Add `skills` and `commands` arrays**

The current plugin.json has no `skills[]` or `commands[]`. Add both, including entries for all existing skills and the new `tipps` skill.

Replace the entire file with:

```json
{
  "name": "claude-onboarding-agent",
  "description": "Guided setup for Claude Code — generates tailored CLAUDE.md, AGENTS.md, and config files for any use case in minutes.",
  "version": "1.0.0",
  "author": {
    "name": "Alexander Angerer",
    "email": "alexander.angerer@outlook.de"
  },
  "contributors": [
    {
      "name": "Maximilian Achenbach",
      "email": "Maximiliana28@gmail.com"
    }
  ],
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
  ],
  "skills": [
    "skills/onboarding/SKILL.md",
    "skills/coding-setup/SKILL.md",
    "skills/design-setup/SKILL.md",
    "skills/knowledge-base-builder/SKILL.md",
    "skills/devops-setup/SKILL.md",
    "skills/content-creator-setup/SKILL.md",
    "skills/office-setup/SKILL.md",
    "skills/research-setup/SKILL.md",
    "skills/tipps/SKILL.md"
  ],
  "commands": [
    { "name": "onboarding", "skill": "onboarding" },
    { "name": "coding-setup", "skill": "coding-setup" },
    { "name": "design-setup", "skill": "design-setup" },
    { "name": "build-knowledge-base", "skill": "knowledge-base-builder" },
    { "name": "devops-setup", "skill": "devops-setup" },
    { "name": "content-creator-setup", "skill": "content-creator-setup" },
    { "name": "office-setup", "skill": "office-setup" },
    { "name": "research-setup", "skill": "research-setup" },
    { "name": "tipps", "skill": "tipps" }
  ]
}
```

> **Note:** If the existing plugin.json already has `skills[]` or `commands[]` when you read it in Step 1, only add the new `tipps` entries to the existing arrays rather than replacing the whole file.

- [ ] **Step 3: Commit**

```bash
git add .claude-plugin/plugin.json
git commit -m "feat(tipps): register tipps skill and /tipps command in plugin.json"
```

---

## Task 3: Update `skills/onboarding/SKILL.md`

**Files:**
- Modify: `skills/onboarding/SKILL.md`

The onboarding skill presents a menu in Step 3 and routes in Step 5. Add `/tipps` as a standalone option available at any time, separate from the setup-type options.

- [ ] **Step 1: Read the full file**

```bash
cat skills/onboarding/SKILL.md
```

- [ ] **Step 2: Add tipps to the Step 3 option list**

Find the option list in Step 3 (the numbered list of setup types). Append a new entry after the last numbered option and before the closing `---`:

```
8. Already set up — audit my current Claude configuration (`/tipps`)
```

- [ ] **Step 3: Add tipps routing to Step 5 Dispatch**

In Step 5, add a routing entry:

```
- Already set up (audit) → invoke `tipps` skill
```

- [ ] **Step 4: Commit**

```bash
git add skills/onboarding/SKILL.md
git commit -m "feat(tipps): add /tipps as audit option in onboarding skill"
```

---

## Task 4: Update `README.md`

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Find the "What's inside" table**

```bash
grep -n "What's inside" README.md
```

- [ ] **Step 2: Add the tipps row**

In the `## What's inside` table, add a new row after the last existing row:

```markdown
| `/tipps` | Audits your existing Claude setup — permissions, CLAUDE.md quality, git hygiene, tooling — and returns a prioritized improvement list |
```

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: add /tipps to README What's inside table"
```

---

## Task 5: Manual Verification

No automated tests — manual test cases per repo convention. Run `/tipps` in each scenario and verify the expected output.

- [ ] **Test 1 — Clean setup**

Set up: a project with a well-configured `.claude/settings.json` (explicit allowedTools, no `*`), `CLAUDE.md` under 40 lines, no secrets, `.gitignore` includes `.claude/`, `ruff.toml` present (if Python).
Expected: `"Your Claude setup looks clean — nothing to improve right now."`

- [ ] **Test 2 — Secrets in CLAUDE.md**

Set up: add a line `API_KEY=sk-abc123` to a test `CLAUDE.md`.
Expected: `[HIGH] Potential secret or personal data in CLAUDE.md` appears first in output.

- [ ] **Test 3 — Wildcard permissions**

Set up: `.claude/settings.json` with `"permissions": { "allow": ["*"] }`.
Expected: `[HIGH] Overly broad tool permissions in settings.json` appears.

- [ ] **Test 4 — Python with requirements.txt only**

Set up: project with `requirements.txt`, no `pyproject.toml`.
Expected: `[MEDIUM] Python project using requirements.txt — consider uv` appears.

- [ ] **Test 5 — No .git directory**

Set up: run `/tipps` in a directory with no `.git/`.
Expected: Git Hygiene pass is silently skipped; no mention of git in output.

- [ ] **Test 6 — No manifest files**

Set up: run `/tipps` in a directory with only `CLAUDE.md` and `.claude/settings.json`.
Expected: Project Tooling pass is silently skipped.

- [ ] **Test 7 — Graceful degradation (no .claude/settings.json)**

Set up: project with only a `CLAUDE.md`, no `.claude/` directory at all.
Expected: Checks 1.2, 1.4, Pass 4 are silently skipped. No error output. Remaining checks run normally.

- [ ] **Test 8 — Output readable for /checkup**

Set up: run `/tipps` as part of a `/checkup` flow (or simulate by reading its output in the same conversation).
Expected: findings are structured text the LLM can parse inline; no files are written to disk.
