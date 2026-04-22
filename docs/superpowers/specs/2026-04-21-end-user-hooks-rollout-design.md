# End-User Hooks Broad Rollout — Design

**Date:** 2026-04-21
**Status:** Draft
**Scope:** Extend selected setup skills so that — with a single opt-in prompt — they emit project-local Claude Code hooks into the user's `.claude/settings.json`. Introduces a marker convention so plugin-owned hook entries can be cleanly identified, refreshed, and removed. Curates a conservative hook catalog: one strong recipe per setup where the value is unambiguous.

## Motivation

The plugin already exercises the hooks primitive twice: the development repo ships its own `PostToolUse` hook (`.claude/hooks/check-dependencies.sh`), and `graphify-setup` registers a `PreToolUse` hook for token-efficient search. Every other setup skill leaves hooks unused.

That gap matters. Hooks are the mechanism Claude Code provides for turning static rules (what CLAUDE.md instructs) into runtime enforcement (what the harness makes happen). Expert Claude Code setups routinely ship hooks — type-check on save, plan-before-apply for IaC, notebook-output stripping — because rule-only guidance is forgotten mid-session and produces dirty diffs, broken types, or accidental `terraform apply` runs.

The plugin promises "setup Claude for <domain> in minutes". Without hooks the promise stops at configuration text. Hooks are the next step.

Secondary goal: establish a convention so plugin-written hooks can be refreshed by `upgrade` and removed by future uninstall logic without touching user-authored hooks in the same file.

## Decision

### Opt-in Model

Each participating setup skill asks a **single yes/no question** late in its flow (after context questions, before artifact generation), listing the hooks it would emit with a one-line purpose each. Default answer on empty input is `yes`. No per-hook granularity — the catalog is curated so that within a setup, accepting all hooks is the recommended path.

Rejected: (a) automatic emission without asking — hooks change runtime behavior and users have strong preferences about autonomous vs confirm-first flows; (b) per-hook opt-in — bloats the interview for marginal gains and the curated catalog is already conservative.

Skills that have no strong hook recipe do not ask the question at all.

### Target Location

Always project-local: `./.claude/settings.json` relative to the user's working directory at the time the skill runs. Matches the existing pattern (`devops-setup`, `data-science-setup`, `coding-setup` already write permissions to this file) and aligns with the existing plugin-internal hook (`.claude/settings.json` at repo root).

Rejected: global `~/.claude/settings.json` — applies hooks across unrelated projects; surprise factor too high. Rejected: per-invocation scope question — needlessly doubles the interview for a decision that is essentially always "this project".

### Marker Convention

Each hook entry written by the plugin carries two identifying fields at the top of the `hooks[]` object:

```json
{
  "_plugin": "claude-onboarding-agent",
  "_skill": "<skill-slug>",
  "type": "command",
  "command": "<command here>"
}
```

The outer matcher-group also carries a marker on the wrapping object where the schema allows it — but the canonical identifier sits on the inner command entry, because that is the granularity at which merge / removal decides.

Claude Code ignores unknown keys on hook entries (underscore-prefixed fields are a standard convention for metadata), so these markers do not affect runtime behavior.

**Why not comments:** JSON has no comments. Any comment-based scheme requires out-of-band parsing, which breaks once the user touches the file with a standard JSON editor. Field markers survive round-tripping.

### Settings.json Merge Strategy

On every run of a hook-emitting skill:

1. If `.claude/settings.json` does not exist: create it with the fresh hook block and nothing else.
2. If it exists but fails JSON parse: print a clear error pointing at the syntax error, do not attempt to write, do not fail the whole setup — print a fallback block the user can paste in manually. Never overwrite a corrupt file.
3. If it exists and parses:
   - **Remove** every hook entry whose `_plugin == "claude-onboarding-agent"` AND `_skill == <current skill slug>`. Iterate through every hook event (`PreToolUse`, `PostToolUse`, `SessionStart`, …). Within each event, remove matching entries from the inner `hooks[]` arrays; if an entire matcher-group becomes empty, remove the whole group. If an entire top-level event becomes empty, remove the key.
   - **Append** the fresh plugin entries under the appropriate event + matcher group. If a group with the identical `matcher` value already exists (user-authored or from another skill), append into that group rather than creating a duplicate group.
   - Preserve key order and formatting where practical (two-space indent, trailing newline).

This procedure is idempotent: running the same skill twice produces the same file. It never touches hook entries that lack the plugin's marker — user-authored hooks, or hooks from any other skill, pass through untouched.

### Scripts Directory

Hook commands that are more than a one-liner are emitted as shell scripts under `./.claude/hooks/<skill-slug>-<purpose>.sh`, marked executable, and referenced from `settings.json` via `bash "$CLAUDE_PROJECT_DIR/.claude/hooks/<name>.sh"`. Inline commands are fine for trivial cases (three tokens or fewer). The split matches the existing plugin-internal hook's structure.

Each generated script starts with a comment block that names the owning skill and the plugin slug, so identification is possible even if `settings.json` is hand-edited.

## Hook Catalog

Conservative by construction. One recipe per participating skill. Every recipe here has a concrete failure mode it prevents, not a vague "might help".

| Setup Skill | Event | Matcher | Action | Rationale | Default |
|---|---|---|---|---|---|
| ~~devops-setup~~ | ~~PreToolUse~~ | ~~`Bash`~~ | Defanged 2026-04-22 (issue #40). Replaced by a tool-agnostic rule file at `.claude/rules/infra-safety.md` emitted unconditionally by `devops-setup`. Rationale: the hardcoded tool list (Terraform / Pulumi / CloudFormation / kubectl / Azure) silently missed Bicep, CDK, Crossplane, Argo CD, Helm, and any future IaC tool; the `yes` default emitted a hook more aggressively than a new user expects. A rule file instructing Claude to pause before ANY IaC apply covers more surface area with no runtime state. | — | removed |
| web-development-setup | PostToolUse | `Edit\|Write` | If the edited file matches `*.ts` or `*.tsx` AND a `tsconfig.json` exists at repo root, run the project's TypeScript compiler in `--noEmit` mode scoped to the changed file. Emit any compiler errors as `additionalContext`. Silent on success. Gated on Q5 ≠ plain-JS and a tsconfig being present. | Catches type errors in the same turn, before Claude moves on. | on (only when Q5 = TypeScript) |
| data-science-setup | PostToolUse | `Edit\|Write` | If the edited file matches `*.ipynb`, run `nbstripout <file>` in-place. Silent on success; on `nbstripout` missing, emit `additionalContext` with the install command. | Notebooks with cell outputs produce massive diffs and leak data. Stripping on save is the de facto standard. | on (only when Q6 = yes, i.e. notebook hygiene accepted) |
| academic-writing-setup | SessionStart | `startup\|resume` | Emit `additionalContext` with the full text of `.claude/rules/writing-style.md` and `.claude/rules/citation-rules.md` (both plugin-owned, extracted files). Silent if either file is absent. | Long writing sessions drift in voice and citation discipline. Reloading the rules at session boundary keeps the drift corrected. | on |

Explicitly rejected recipes (documented here so future contributors do not re-litigate):

- **coding-setup PreToolUse `rm -rf` guard.** Claude Code's permission system already handles destructive commands via allow / deny lists. A hook duplicates that logic and creates two sources of truth for the same behavior.
- **coding-setup PostToolUse linter.** Language-agnostic coding-setup does not know which linter to run; asking would bloat the interview. Linter-on-save belongs in stack-specific skills (web-development-setup does this for TypeScript). Python users get it via `pre-commit` already emitted by `data-science-setup` when relevant; generic Python coding does not currently have a pre-commit emitter, and adding one is YAGNI for this initiative.
- **knowledge-base-builder hooks.** Graphify already owns the hook slot for this setup via delegation. A second hook would compete for token budget.
- **office-setup, content-creator-setup, design-setup, research-setup.** No strong recipe surfaced during brainstorm. These setups primarily emit rules and pointers; their value prop is not runtime enforcement. Adding weak hooks would violate the YAGNI constraint.

## Affected Skills

**Hook-emitting (new behavior):**

- ~~`devops-setup` — adds opt-in question + plan-before-apply PreToolUse hook~~ (defanged 2026-04-22 per issue #40; now emits `.claude/rules/infra-safety.md` unconditionally instead of a hook)
- `web-development-setup` — adds opt-in question + TS compile PostToolUse hook, gated on TypeScript
- `data-science-setup` — adds opt-in question + nbstripout PostToolUse hook, gated on notebook hygiene
- `academic-writing-setup` — adds opt-in question + SessionStart rules-reload hook

**Shared helper (new):**

- `skills/_shared/emit-hook.md` — merge-and-emit procedure consumed by all four hook-emitting skills

**Refresh-aware (adjusted, existing behavior):**

- `upgrade` — extends its Pass 2 planning + Pass 3 per-change confirmation to include plugin-owned hook entries in `.claude/settings.json`. Identification: same marker convention.
- `checkup` — no behavior change beyond its existing flow; `--rebuild` already routes to `onboarding --rebuild` which eventually re-invokes the setup skill and re-emits hooks via the shared helper (idempotent by design).

**Untouched:** `coding-setup`, `knowledge-base-builder`, `office-setup`, `content-creator-setup`, `design-setup`, `research-setup`, `graphify-setup`, `onboarding`, `tipps`. Rationale: either they have no strong recipe, or hooks are already handled via delegation (Graphify).

## Out of Scope

- Plugin-internal hook redesign (the `.claude/hooks/check-dependencies.sh` that lives in this repo). That hook serves plugin-development purposes and is not user-facing.
- Hook event types beyond those listed (e.g. `UserPromptSubmit` gating on content, `Stop` hooks for post-run audit). Valuable, but speculative without a concrete recipe and user demand. Revisit per request.
- MCP-server provisioning from setup skills. Related in spirit (runtime extensions) but orthogonal in mechanism. Covered by Initiative #6.
- Uninstall-time hook stripping as a dedicated command. The marker convention makes it possible; the feature itself ships once uninstall is otherwise specified.
- Cross-skill hook interaction. The merge procedure prevents collisions at write time; emergent interactions between a plugin PreToolUse and a user-authored one are the user's responsibility, same as any other hook stack.
- pre-commit-style hooks (`.pre-commit-config.yaml`) — these are a different mechanism entirely (Git hooks, not Claude Code hooks). `data-science-setup` and `academic-writing-setup` already emit them; this spec does not touch that behavior.

## Risks & Edge Cases

- **User-authored matcher collision.** A user has a `PostToolUse` + `matcher: "Edit|Write"` group before the plugin writes one. Merge appends into that existing group — the plugin entry coexists with the user's. The marker still identifies ownership, so subsequent refresh finds only the plugin entry. Confirmed safe.
- **Corrupt settings.json.** The plugin never overwrites a file it cannot parse. It prints the fallback block and continues — hooks are a best-effort layer, not a blocker for the rest of the setup.
- **Hook misfire.** ~~The plan-before-apply guard in `devops-setup` uses substring matching on the command text.~~ Defanged 2026-04-22 (issue #40) — the devops-setup hook was replaced by a tool-agnostic rule file, so substring-based misfires no longer apply to this plugin. Retained here as a design note for any future Bash-command-inspection hook: prefer rule-file guidance unless runtime enforcement is strictly required.
- **Schema drift.** Claude Code's hook schema is stable as of current documentation but could evolve. Mitigation: the emit-hook helper is a single file. Schema adjustments happen once, propagate to every skill.
- **User confusion if a hook blocks their action.** The catalog deliberately avoids `permissionDecision: deny`. Every recipe uses `additionalContext` or silent in-place file modification (`nbstripout`). Nothing hard-blocks the user.
- **Marker pollution on standard JSON editors.** Some editors strip unknown fields. Claude Code does not; hand-editing in VS Code / Cursor does not; the risk is only a concern if the user pipes the file through a stripping tool. Documented in the helper.
- **Skill runs outside a git repo.** Hooks write to `.claude/settings.json` regardless of git state. No git dependency introduced.
- **Skill re-run with declined hooks.** If a user said `no` on first run, the skill does not write hook entries. On re-run, it re-asks (no marker-file equivalent of `.migration-declined`). Rationale: the question is cheap, opinions change, and `upgrade` provides the canonical path for non-interactive re-refresh.

## Success Criteria

- **Grep-testable marker:** Across `skills/`, every generated hook entry contains both `_plugin` and `_skill` keys. `grep -r "_plugin.*claude-onboarding-agent" skills/` returns hits only in the four hook-emitting skills and the shared helper.
- **Shared-helper reuse:** The four hook-emitting skills all reference `skills/_shared/emit-hook.md`. No skill reimplements the merge logic inline.
- **Idempotent emission:** In a test project, running the skill twice produces identical `.claude/settings.json` content (byte-for-byte where practical, semantically identical otherwise — ordering within arrays may vary but content does not duplicate).
- **Collision survival:** In a test project whose `.claude/settings.json` already has a user-authored hook under the same event + matcher, running the emit helper appends the plugin entry into the same group without touching the user entry. Removal leaves the user entry intact.
- **Corrupt-file safety:** In a test project whose `.claude/settings.json` is malformed JSON, the skill prints the fallback block and exits the hook step without modifying the file. The rest of the skill completes normally.
- **Upgrade refresh:** `upgrade` identifies plugin-owned hook entries via the `_plugin` marker, includes them in the Pass 2 plan, and refreshes them in Pass 4.
- **Catalog discipline:** The four hook recipes listed in the catalog are the only hook-emission code paths across the plugin. No skill ships additional hooks outside this spec.
