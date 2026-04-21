---
name: audit-setup
description: Audit your current Claude setup and get a prioritized list of improvement suggestions — package manager hygiene, CLAUDE.md quality, permissions, git hygiene, MCP servers, and more.
---

# Audit Setup — Claude Setup Audit

Audit the current Claude setup and print a prioritized, actionable list of improvement suggestions.

**Language:** Detect language from the user's first message and respond in it throughout. All file content and finding text stays in English.

**Entry:** Run all four passes silently first. Collect every finding in context. Print once at the end, sorted HIGH → MEDIUM → LOW. Do not print pass-by-pass intermediate output.

---

## Pass 1 — Claude Config

Read these files if they exist: `CLAUDE.md`, `AGENTS.md`, `.claude/settings.json`. Skip any check whose required file is absent.

**Check 1.1 — Secrets in CLAUDE.md** `[HIGH]`
Condition: `CLAUDE.md` contains patterns that look like secrets — API keys (strings matching `sk-`, `ghp_`, `AIza`, `xox`), passwords (lines containing `password =` or `password:`), or bearer tokens.
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
Why: Section delimiters allow automated tools to make targeted edits to specific sections without touching the rest of the file.
How to apply: Add `<!-- onboarding-agent:start -->` and `<!-- onboarding-agent:end -->` around each generated section.

---

## Pass 2 — Git Hygiene

Check for `.git/` directory. If absent, skip this entire pass without mentioning it.

**Check 2.1 — Claude artifacts not gitignored** `[MEDIUM]`
Condition: `.gitignore` is missing either entry — fire if `.claude/` is absent OR `*.claude-*` is absent (or both).
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

Check for manifest files in this order: `pyproject.toml`, `requirements.txt`, `package.json`, `Cargo.toml`, `go.mod`. Use the first match to determine the primary stack. If none exist, skip this entire pass without mentioning it.

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
How to apply (Go): `curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin && golangci-lint run`
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
Why: Descriptions help Claude understand when to use each server, improving tool selection. Note: the "description" field is not part of the official mcpServers schema but is a convention this plugin promotes for documentation purposes.
How to apply: Add a `"description": "..."` field to each MCP server entry in `.claude/settings.json`.

**Check 4.3 — Skills mismatched to project type** `[LOW]`
Condition: Installed skills (from settings.json plugins list) include a setup skill clearly mismatched to the detected project. Examples: `devops-setup` in a project with only frontend files; `research-setup` in a project with only code files.
Finding title: "Installed skill may not match your project type"
Why: Unused setup skills add noise to Claude's context without providing value.
How to apply: Remove unused skills via `/plugin uninstall <skill-name>`.

**Check 4.4 — Use case suggests MCP that is not registered** `[LOW]`
Condition: `.claude/onboarding-meta.json` records `setup_slug` in {`coding`, `web-development`, `design`, `office`} AND the corresponding recommended MCP (per spec 2026-04-21-mcp-server-integration-design.md) is NOT in `claude mcp list`.
Mapping:
- `coding` → `github` (only if project has a GitHub remote)
- `web-development` → `github` (only if project has a GitHub remote)
- `design` → `figma-context` (only if the recorded design tool is Figma; skip otherwise)
- `office` → `gmail`, `google-calendar`, `google-drive` — flag only the ones whose trigger conditions match the recorded office Q1 answer
Finding title: "Declared use case suggests MCP server(s) that are not registered"
Why: The setup skill offered these MCPs at onboarding time; the user may have declined or deferred. Informational reminder, not an error.
How to apply: Re-run the relevant setup skill to re-offer, or run the `claude mcp add` command directly (see the anchor doc at `docs/anchors/mcp-servers.md`).

---

## Pass 5 — Realtime Anchors

Read `./.claude/onboarding-meta.json` if present → `setup_type`. If the file is absent or malformed, skip this pass entirely (today's behavior for untracked projects is preserved by falling through).

Read `skills/_shared/anchor-mapping.md` → extract the list of anchor slugs mapped to `setup_type` → `anchors_for_setup`. If the mapping yields no anchors (unknown setup_type), skip this pass.

For each `anchor_slug` in `anchors_for_setup`, fetch the anchor via `skills/_shared/fetch-anchor.md` (embedded fallback: use the snapshot declared in `skills/anchors/SKILL.md` for that slug). If `fetch-anchor` returns `anchor_markdown: null`, skip that slug and continue.

Run the anchor-specific check defined below. Each check is `LOW` severity and produces at most one finding per anchor.

### Check 5.1 — `claude-models` deprecated-ID reference `[MEDIUM]`

(Unchanged from prior behavior.) From the fetched `claude-models` anchor, parse the `## Deprecated` section into a list of deprecated model IDs. If any of the already-scanned files (`CLAUDE.md`, `AGENTS.md`, `.claude/settings.json`) contains a string exactly matching one of those IDs, emit a MEDIUM finding: "Deprecated Claude model ID referenced in config. Replace with the current equivalent from the anchor's `## Model IDs` table."

### Check 5.2 — `mcp-servers` not in recommended list `[LOW]`

Only runs if `.claude/settings.json` exists and has a non-empty `mcpServers` object. From the fetched `mcp-servers` anchor, parse the `## Recommended` section into a set of server names (each bullet's backticked identifier). For each key in `settings.json`'s `mcpServers` not present in that set, emit one LOW finding: "MCP server `<name>` is not on the current recommended list — review whether it still fits your setup."

### Check 5.3 — `claude-tools` deprecated pattern present `[LOW]`

From the fetched `claude-tools` anchor, parse the `## Deprecated patterns` section into a list of pattern descriptors. Each bullet is expected to mention an exact file, key, or directory name in backticks. For each backticked name that the scan finds present in the repo (via `.claude/settings.json` keys or files under `.claude/`), emit one LOW finding: "`<pattern>` is marked deprecated in the current claude-tools anchor — migrate to the recommended alternative."

### Check 5.4 — `subagents` anti-pattern reference `[LOW]`

Only runs if the project has any subagent definition files under `.claude/agents/`. From the fetched `subagents` anchor, parse the `## Anti-patterns` section. For each anti-pattern, check whether any subagent definition file or `.claude/settings.json` reference matches the pattern (keyed on backticked names in the anti-pattern bullets). If matched, emit one LOW finding: "Subagent usage pattern `<name>` is flagged as an anti-pattern by the current subagents anchor."

### Check 5.5 — `knowledge-base` layout deviation `[LOW]`

Only runs if `setup_type == knowledge-base`. From the fetched `knowledge-base` anchor, parse the `## Recommended layout` section for the canonical folder names. Scan the top-level directory for folders. If the set of top-level folders in the project differs from the recommended layout (missing recommended folders, or non-recommended folders present), emit one LOW finding: "Vault layout does not match the current knowledge-base anchor recommendation."

If the anchor lacks the required section at fetch time, the corresponding check is silently skipped.

### Pass 5 Fallbacks

The embedded fallback snapshots live in `skills/anchors/SKILL.md`. Read them from there rather than duplicating. (If running this skill standalone without the `/anchors` skill installed, the fetch-anchor network path is the only route — a check will silently skip on offline use.)

---

## Output

After all five passes, print the following block. Do not print anything before it.

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
