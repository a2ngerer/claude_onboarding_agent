# Tipps Skill — Design

**Date:** 2026-04-20
**Status:** Draft
**Related issues:** #1 (`/tipps`), #8 (`/checkup` depends on this)

## Purpose

A new skill `onboarding-agent:tipps` (slash command `/tipps`) that audits an existing Claude setup and prints a prioritized, actionable list of improvement suggestions. Runs independently of any prior setup — no dependency on `/onboarding` having been run first.

## Non-goals

- Applying fixes or diffs (delegated to `/upgrade`, issue #5).
- Auto-fix mode (`--fix` flag). `/tipps` is suggest-only, always.
- Docs links per finding (hallucination risk — Why + How to apply carries the value).
- Automated CI tests (not the pattern in this repo).

## Integration with `/checkup`

`/checkup` (issue #8) invokes `/tipps` internally at Stage 2 of its decision flow. The integration uses Option A (plain text): `/tipps` prints its findings as structured text; `/checkup` reads the output via LLM conversation context. No file artifacts, no structured JSON contract.

## Entry Flow

1. Detect language from the user's first message. Respond in that language throughout. All generated file content stays in English per repo policy.
2. Silently scan the project: `.claude/settings.json`, `CLAUDE.md`, `AGENTS.md`, manifest files (`package.json`, `pyproject.toml`, `requirements.txt`, `Cargo.toml`, `go.mod`), `.gitignore`.
3. Run four named category passes (see Check Categories).
4. Collect all findings in memory, then print a unified severity-sorted list.

**Graceful degradation:** If a config file does not exist, skip checks that depend on it without erroring.

## Check Categories

### Pass 1 — Claude Config

Scope: `CLAUDE.md`, `AGENTS.md`, `.claude/settings.json`

| Finding | Severity | Condition |
|---|---|---|
| Secrets or personal data in `CLAUDE.md` | HIGH | Detected patterns: API keys, passwords, email addresses, tokens |
| Overly broad permissions in `settings.json` | HIGH | `allowedTools` contains `"*"` |
| `CLAUDE.md` length exceeds 40 lines | MEDIUM | Line count > 40 |
| No `allowedTools` entries | MEDIUM | `allowedTools` absent or empty |
| No section delimiters in `CLAUDE.md` | LOW | No `<!-- onboarding-agent:start -->` markers present |

### Pass 2 — Git Hygiene

Scope: `.gitignore`, presence of `.git/`

Skip entire pass if no `.git/` directory found.

| Finding | Severity | Condition |
|---|---|---|
| Claude artifacts not in `.gitignore` | MEDIUM | `.claude/` or `*.claude-*` not listed |
| No pre-commit hook | LOW | `.git/hooks/pre-commit` absent |

### Pass 3 — Project Tooling

Skip entire pass if no manifest file found (`package.json`, `pyproject.toml`, `requirements.txt`, `Cargo.toml`, `go.mod`).

| Finding | Severity | Condition |
|---|---|---|
| Python: `requirements.txt` present, no `uv` / `pyproject.toml` | MEDIUM | `requirements.txt` exists, `pyproject.toml` absent |
| No linter configured (stack-specific) | MEDIUM | Python: no `ruff.toml`/`.flake8`/`ruff` in deps; Node: no `.eslintrc*`/`biome.json`; Rust: clippy absent from `Cargo.toml` |
| Node: `package-lock.json` present (npm) | LOW | `package-lock.json` exists (suggest `pnpm`/`bun`) |
| Node: no TypeScript in non-trivial project | LOW | No `tsconfig.json` and project has > 5 JS files |

### Pass 4 — MCP & Skills

Scope: `.claude/settings.json` MCP entries, installed plugin list (if readable)

| Finding | Severity | Condition |
|---|---|---|
| `fewer-permission-prompts` skill not installed | MEDIUM | Skill absent and `allowedTools` is sparse |
| MCP servers present with no description | LOW | MCP entries lack a `description` field |
| Skills installed that don't match detected project type | LOW | e.g. `devops-setup` skill in a pure frontend project |

## Output Format

All findings collected after all four passes, printed once as a unified block sorted HIGH → MEDIUM → LOW. Within each severity level, findings appear in pass order (Config → Git → Tooling → MCP).

```
## Claude Setup Audit

Scanned: CLAUDE.md · .claude/settings.json · package.json · .gitignore
Passes: Claude Config · Git Hygiene · Project Tooling · MCP & Skills

---

[HIGH] Overly broad permissions in settings.json
Why: A "*" allow-all entry lets any tool run without confirmation — including destructive ones.
How to apply: Replace "*" with an explicit allowedTools list. Run /fewer-permission-prompts to generate one.

[MEDIUM] CLAUDE.md is 67 lines — aim for under 40
Why: Long CLAUDE.md files dilute signal. Claude reads the whole thing every turn.
How to apply: Trim to pointers and principles. Move detail into referenced files.

[LOW] No pre-commit hook found
Why: Pre-commit hooks catch issues before they hit CI.
How to apply: pip install pre-commit && pre-commit install

---
3 findings: 1 HIGH · 1 MEDIUM · 1 LOW
```

**If no findings:** print `"Your Claude setup looks clean — nothing to improve right now."` and exit.

## Severity Reference

- `[HIGH]` — Security risk or configuration that actively harms Claude's usefulness
- `[MEDIUM]` — Best-practice gap with a clear, low-effort fix
- `[LOW]` — Nice-to-have improvement

## Artifacts

### New files

- `skills/tipps/SKILL.md` — follows the pattern of existing skills: runtime language detection, graceful degradation, English content, no file writes.
- `.claude/commands/tipps.md` — slash command entry point.

### Modified files

- `.claude-plugin/plugin.json` — add `tipps` to `skills[]` and `/tipps` to `commands[]`.
- `README.md` — add a row to the "What's Inside" table.
- `skills/onboarding/SKILL.md` — add `/tipps` as an option in Step 3 and Step 5 (existing setup detected path).

## Acceptance Criteria

- [ ] `skills/tipps/SKILL.md` follows existing skill patterns
- [ ] Slash command `/tipps` works standalone
- [ ] Entry in `.claude-plugin/plugin.json` (`skills[]` + `commands[]`)
- [ ] Entry in `README.md` ("What's Inside" table)
- [ ] Skill runs independently of previous setup type
- [ ] Output is prioritized HIGH → MEDIUM → LOW and actionable
- [ ] Each finding has a Why and How to apply
- [ ] Graceful degradation when config files are missing
- [ ] No file writes — suggest-only

## Manual Test Cases

1. **Clean setup:** `/tipps` with a well-configured project prints the "nothing to improve" message.
2. **Secrets in CLAUDE.md:** HIGH finding surfaces first.
3. **`"*"` in allowedTools:** HIGH finding with correct How to apply.
4. **Python project with requirements.txt only:** MEDIUM finding for uv.
5. **No `.git/` directory:** Git Hygiene pass skipped silently.
6. **No manifest files:** Project Tooling pass skipped silently.
7. **Invoked from `/checkup`:** findings text readable inline by the LLM; no file artifacts written.

## Language Rule

All artifacts (SKILL.md, slash command, README updates) are written in English per repository policy. The skill detects user language at runtime and responds accordingly.
