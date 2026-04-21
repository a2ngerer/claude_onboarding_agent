# End-User Subagents Rollout — Design

**Date:** 2026-04-21
**Status:** Draft
**Scope:** Extend the subagent-generation pattern established by `knowledge-base-builder` (which emits `.claude/agents/obsidian-vault-keeper.md`) to a small, curated set of additional setup skills. Define the opt-in model, naming convention, context-discovery pattern, deduplication strategy across multi-setup projects, and file-ownership boundaries.

## Motivation

Subagents are a first-class Claude Code primitive: a `.claude/agents/<name>.md` file with a frontmatter `description` is auto-invoked by the main thread whenever the description matches the user's intent. This keeps specialist tool schemas and long procedural prompts **out of the main context window** and loads them only when the task actually hits that specialty. The plugin already uses the pattern successfully for Obsidian vault I/O; there is no reason to stop there.

Three concrete gaps justify a broader rollout:

1. **Repetitive audit-style tasks** (code review on a PR-sized diff, component-structure audit, notebook hygiene, academic-writing style compliance) match the subagent sweet spot: they are triggered by clear verbal cues ("review this diff", "check my component"), run over a bounded scope, and return a compact verdict.
2. **Generated rule files already exist for these skills** (from Initiative #5 — `.claude/rules/component-structure.md`, `evaluation-protocol.md`, `writing-style.md`, etc.). A subagent that reads those files as its source of truth gives the rules a runtime enforcement path beyond "Claude read them via CLAUDE.md pointer and remembered".
3. **Main-thread pollution:** embedding a full "how to review code" prompt block in CLAUDE.md or in a skill SKILL.md loads on every turn. Offloading it to a subagent preserves the main thread's context budget.

## Decision

### Opt-In Model

Subagent generation is **opt-in per skill, prompted once during setup**. The prompt appears after context questions and before artifact generation:

```
This skill can generate a project-local subagent (`<name>`) that Claude
auto-dispatches when the conversation matches its description
(e.g., "review this diff", "check my component"). The subagent lives in
.claude/agents/<name>.md and only loads when invoked — no always-on
context cost.

Install <name> now? (yes / no / later)
```

- **yes:** generate `.claude/agents/<name>.md` and record in `.claude/onboarding-meta.json` under a new `subagents_installed: []` array.
- **no:** skip silently.
- **later:** write no file; document the command the user can run (`/<skill> --add-subagent <name>`). Reserved for future work — v1 treats `later` the same as `no` but surfaces the same follow-up pointer in the completion summary.

**Rationale (rejected alternatives):**

- *Default-on, generate always:* violates YAGNI and may install subagents a user never wanted, cluttering `.claude/agents/`. Users opinionated enough to have used this plugin are opinionated enough to be asked once.
- *Default-off with no prompt (pure `--add-subagent` flag):* discoverability goes to zero. Users who would benefit never learn the feature exists. The one-line opt-in prompt is the right trade.

`knowledge-base-builder`'s existing `obsidian-vault-keeper` generation stays **default-on** when the Obsidian CLI is available, because the skill's setup is gated on a prior explicit question (Obsidian yes/no) that already functions as opt-in. No change to that skill's flow.

### Subagent Naming Convention

- **Filename:** `.claude/agents/<slug>.md` where `<slug>` is kebab-case, noun-led, and describes the agent's scope (`code-reviewer`, `component-auditor`, not `review-code` or `helper-3`).
- **`name:` frontmatter value:** matches the filename slug verbatim.
- **`description:` frontmatter value:** starts with `Use to …` or `Use when …`, names concrete trigger phrases, and stays under 3 sentences. Claude Code uses this string for auto-invocation matching — vague descriptions degrade dispatch quality.
- **Scope qualifier in filename is banned.** The filename is `code-reviewer`, not `coding-setup-code-reviewer`. Reason: users compose multi-skill setups; prefixing by skill creates awkward names and blocks deduplication (see next section).

### Subagent Catalog (v1)

Conservative selection. Each entry must clear the "does the main thread actually benefit from offloading this?" bar; weak candidates are explicitly rejected below the table.

| Skill | Subagent | Purpose | Trigger description (frontmatter, abbreviated) | Tools | Model |
|---|---|---|---|---|---|
| `coding-setup` | `code-reviewer` | Review a PR-sized diff against project conventions | "Use to review uncommitted diffs, staged changes, or a named commit range. Dispatch when the user asks for a code review, wants feedback on a change, or says 'review this' / 'check my changes'." | Bash, Read, Grep, Glob | inherit |
| `web-development-setup` | `component-auditor` | Check components against `.claude/rules/component-structure.md` (and `api-conventions.md` if present) | "Use to audit a React/Vue/Svelte component or an API route for the project's structure, routing, and naming conventions. Dispatch when the user asks 'does this component match our conventions' or 'audit this route'." | Read, Grep, Glob | inherit |
| `data-science-setup` | `notebook-auditor` | Audit a notebook or training script against `.claude/rules/evaluation-protocol.md` and `data-schema.md` (seeds, splits, leakage, logging) | "Use to review a notebook or training script for reproducibility — seed setting, train/val/test split integrity, leakage, baseline logging. Dispatch when the user asks to review a notebook, check an experiment, or audit reproducibility." | Read, Grep, Glob, Bash | inherit |
| `academic-writing-setup` | `writing-style-auditor` | Check a passage against `.claude/rules/writing-style.md` and `citation-rules.md` | "Use to audit an academic passage for voice, tense, structure, and citation hygiene against the project's writing-style and citation rules. Dispatch when the user asks to review a paragraph, check style, or verify citations." | Read, Grep, Glob | inherit |
| `knowledge-base-builder` | `obsidian-vault-keeper` | Owns Obsidian vault I/O (existing — not regenerated) | unchanged | Bash, Read, Glob, Grep | inherit |

**`inherit` model:** subagent inherits the parent conversation's model setting. Rationale: users on Sonnet do not want their subagents silently escalating to Opus; users on Opus want the subagent at the same tier. The subagent prompt can request a model explicitly only if the task genuinely needs it (none in v1 do).

**Rejected candidates (explicit list, to prevent drift):**

- `devops-setup / rollback-reviewer` — a rollback review is too context-dependent (infrastructure state, cloud provider, IaC tool) to fit a static subagent. Deferred until a concrete rules file exists to anchor the review. Out of scope for v1.
- `office-setup`, `content-creator-setup`, `research-setup` — no durable `.claude/rules/*.md` file exists today that a subagent could audit against. A subagent reduced to "audit a document in the abstract" is redundant with the main thread and adds ceremony without value. Reject.
- `design-setup` — similar reasoning; `frontend-design:frontend-design` already provides a dedicated skill for high-quality frontend work, and a plugin-generated `design-auditor` subagent would compete with that without improving on it. Reject.
- `graphify-setup` — Graphify already ships its own slash command and PreToolUse hook. Adding a subagent on top would be a third integration point for the same concern. Reject.

### Context-Discovery Pattern

Every subagent prompt begins with the same three-line preamble:

```markdown
## Before your first action
1. Read `CLAUDE.md` (project root) for project context.
2. Read the rules files relevant to your scope, listed below.
3. If a listed rules file is missing, say so in your response header and proceed with best-effort defaults — do not stop.
```

Each subagent hardcodes the list of rules files it depends on (e.g., `code-reviewer` lists none because it has no specific rules file; `component-auditor` lists `.claude/rules/component-structure.md` and `.claude/rules/api-conventions.md`). This pattern is identical to `obsidian-vault-keeper`'s "Before your first command — read `.claude/rules/obsidian-cli.md`" block (post-Initiative #5), keeping the plugin's subagent authoring consistent.

**Rationale (rejected alternatives):**

- *Pass rules inline in the subagent prompt.* Defeats the point — rules content gets loaded on every dispatch even if unchanged. A `Read` at dispatch-time pulls the current file once.
- *Rely on main-thread context to forward rules.* Subagents run with a fresh context window; they do not inherit the main thread's state. They must discover project context themselves.

### Deduplication Across Multi-Setup Projects

A project can have multiple setups (e.g., `coding-setup` + `web-development-setup` + `data-science-setup`). The v1 catalog intentionally uses distinct filenames per subagent (`code-reviewer`, `component-auditor`, `notebook-auditor`, `writing-style-auditor`) so dedup reduces to "if the file exists, skip." No semantic merging is required.

**Write-time collision policy (mirrors Initiative #5):**

- **Default:** Skip the write if `.claude/agents/<name>.md` already exists. Log `Skipped .claude/agents/<name>.md (already exists)` and continue.
- **Explicit regenerate:** `checkup --rebuild` and `upgrade` may overwrite after an explicit dry-run preview, consistent with how those skills already handle CLAUDE.md and rules files.

**Future conflict resolution:** if a future skill proposes a subagent whose trigger description overlaps substantially with an existing one (e.g., a second "review my code" subagent), the spec must be updated to pick one owner; no two skills may write the same filename. This matches the topic-exclusivity rule for `.claude/rules/`.

### Plugin File Ownership

The plugin **does not own** the `.claude/agents/` directory. It owns only the filenames listed in the v1 catalog (`code-reviewer.md`, `component-auditor.md`, `notebook-auditor.md`, `writing-style-auditor.md`, `obsidian-vault-keeper.md`). Any other file in `.claude/agents/` — whether written by the user, by another plugin, or by a future rollout — is **never read or modified** by this plugin. This parallels the rules-convention file-ownership rule and keeps the blast radius of `checkup --rebuild` bounded.

### Shared Authoring Helper

A new shared helper `skills/_shared/emit-subagent.md` holds the opt-in prompt text, the context-discovery preamble template, the collision-check snippet, and the one-line `.claude/onboarding-meta.json` update for `subagents_installed[]`. Consumed by the four generator skills. Rationale: DRY — without a helper, four skills would duplicate the same 20-line procedure and drift independently.

## Affected Skills

**Gain a new subagent-generation step (after context questions, before artifact generation):**

- `coding-setup` — emits `code-reviewer`
- `web-development-setup` — emits `component-auditor`
- `data-science-setup` — emits `notebook-auditor`
- `academic-writing-setup` — emits `writing-style-auditor`

**No change:**

- `knowledge-base-builder` — keeps `obsidian-vault-keeper`, already uses the target pattern.
- `devops-setup`, `office-setup`, `content-creator-setup`, `research-setup`, `design-setup`, `graphify-setup` — no subagent in v1 (see rejected-candidates list).

**Regeneration-aware (updated to know about the new filenames):**

- `checkup` — `--rebuild` path must recognize the whitelist and offer regeneration.
- `upgrade` — dry-run preview must recognize the whitelist and include subagent files.

**New shared helper:**

- `skills/_shared/emit-subagent.md`

## Onboarding Metadata Update

`./.claude/onboarding-meta.json` gains an optional `subagents_installed: []` array of subagent slugs. Example after a coding + web setup:

```json
{
  "plugin_version": "1.0.0",
  "skills_used": ["coding-setup", "web-development-setup"],
  "subagents_installed": ["code-reviewer", "component-auditor"]
}
```

Consumed by `checkup` for collision checks (skip if filename is both on disk AND listed as installed-by-us — positive ownership signal) and by `upgrade` for diff generation.

`skills/_shared/write-meta.md` must be updated to merge `subagents_installed` as a union across runs (not overwrite).

## Out of Scope

- **Plugin-internal subagents** (agents the plugin uses during its own setup flow) — that is Initiative #1, a separate concern.
- **Onboarding orchestrator refactor** (how the orchestrator routes to setup skills) — that is Initiative #7.
- **Subagent updates after generation** — once a subagent file is written, it is user-owned. `checkup --rebuild` is the only regeneration path.
- **Cross-skill subagents** (a single subagent owned by multiple skills simultaneously). Topic exclusivity prevents this; if demand emerges, it is a future spec.
- **Dynamic tool-set selection** (subagent picks its tools based on project language). The v1 tool-sets are static per subagent. Revisit only if a concrete pain case appears.
- **Subagent versioning beyond `checkup --rebuild`** — no `version:` field in subagent frontmatter in v1.

## Risks & Edge Cases

- **Subagent proliferation.** A user running four setups on one project would end up with four subagents. Mitigation: the catalog is capped and each subagent has a distinct, non-overlapping trigger description. If a user does not want a subagent, they say "no" at the prompt.
- **Auto-trigger misfires.** The Claude Code dispatcher matches the `description` field against user intent. A description like "review code" could fire on unrelated mentions of "review". Mitigation: descriptions use "Use to …" / "Dispatch when …" patterns with concrete trigger phrases, not bare topic names.
- **Tool-set too broad.** Granting `Bash` to every subagent invites side effects. Mitigation: only `code-reviewer`, `notebook-auditor`, and `obsidian-vault-keeper` get `Bash`; `component-auditor` and `writing-style-auditor` are read-only (Read, Grep, Glob). Each subagent's tool list is explicit, not inherited from main.
- **Rules-file dependency missing.** A subagent like `component-auditor` depends on `.claude/rules/component-structure.md` existing — but that file is generated by `web-development-setup`. Cross-skill timing: if `component-auditor` is installed before the rules file exists (unlikely given both come from the same skill), the subagent's preamble handles it (step 3 of the context-discovery pattern: "if missing, say so and proceed with best-effort defaults").
- **User edits a plugin subagent file.** File ownership is determined by filename, not by content hash. If the user edits `.claude/agents/code-reviewer.md`, the skip-on-exists policy preserves their edits; `checkup --rebuild` will warn-then-overwrite (dry-run preview). Documented, not mitigated with content-hash tracking in v1.
- **Model-inheritance surprise.** A user on Haiku dispatching `notebook-auditor` will get a Haiku-level audit. Acceptable trade for not silently upgrading to Opus. Documented in the subagent's description ("inherits parent model").
- **`.claude/onboarding-meta.json` drift.** If the user deletes `.claude/agents/code-reviewer.md` but the meta still lists it as installed, `checkup` should detect the drift and offer regeneration. Covered by `checkup`'s existing detection flow once it is updated to read `subagents_installed`.

## Success Criteria

- **Grep-testable: each setup skill with a subagent emits the right file.** For each of (`coding-setup`, `web-development-setup`, `data-science-setup`, `academic-writing-setup`), the SKILL.md contains the opt-in prompt and references `skills/_shared/emit-subagent.md`. Running the skill on a scratch project with "yes" to the prompt produces `.claude/agents/<slug>.md` with the expected `name:`, `description:`, and `tools:` frontmatter.
- **Collision skip.** Running `coding-setup` twice on the same project does not overwrite `.claude/agents/code-reviewer.md`; the skill logs a skip message. Confirmed by `ls -la .claude/agents/code-reviewer.md` showing unchanged `mtime` on second run.
- **Dedup across multi-setup.** Running `coding-setup` + `web-development-setup` on the same project produces `.claude/agents/code-reviewer.md` AND `.claude/agents/component-auditor.md` (distinct files, no conflict).
- **Metadata recording.** After a "yes" run, `./.claude/onboarding-meta.json` contains the subagent slug in `subagents_installed[]`. Verifiable with `jq '.subagents_installed' .claude/onboarding-meta.json`.
- **File-ownership boundary.** Running `checkup --rebuild` on a project with a user-authored `.claude/agents/my-custom-agent.md` does not touch that file. Verifiable with `stat -f '%m'` showing unchanged mtime.
- **Shared helper in place.** `skills/_shared/emit-subagent.md` exists and is referenced by exactly the four generator skills listed in Affected Skills (grep-verifiable).
- **Rejected candidates stay rejected.** `skills/devops-setup/SKILL.md`, `skills/office-setup/SKILL.md`, `skills/content-creator-setup/SKILL.md`, `skills/research-setup/SKILL.md`, `skills/design-setup/SKILL.md`, and `skills/graphify-setup/SKILL.md` contain zero references to `.claude/agents/` (grep-verifiable).
