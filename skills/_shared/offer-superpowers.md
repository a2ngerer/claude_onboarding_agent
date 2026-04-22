# Offer Superpowers (shared procedure)

> Consumed by `coding-setup`, `web-development-setup`, `data-science-setup`, `research-setup`, `academic-writing-setup`, and `knowledge-base-setup` during their dependency-install step. Do not invoke directly.

Canonical opt-in prompt and delegation target for the Superpowers skills library
(https://github.com/obra/superpowers). Every consumer skill points here so the
wording, the marketplace/GitHub ids, and the failure path stay identical across
the plugin.

## Contract

The calling skill sets these inputs (inline in its own prose, not as structured
arguments) before reading this file:

| Parameter | Example | Purpose |
|---|---|---|
| `skill_slug` | `coding-setup` | Owning skill, used for state logging and the recovery hint |
| `mandatory` | `true` \| `false` | `true` → install without asking (the skill treats Superpowers as a hard requirement); `false` → ask first |
| `capability_line` | "Useful for planning multi-step experiments." | Optional one-sentence description shown in the opt-in prompt; omit when `mandatory: true`. If absent the helper uses the generic line below. |

Pinned install coordinates (do not override):

- marketplace-id: `superpowers@claude-plugins-official`
- github: `https://github.com/obra/superpowers`
- name: `superpowers`

## Step 1: Opt-in prompt (only when `mandatory: false`)

If `mandatory: true`, skip this step entirely and go to Step 2.

Otherwise ask ONCE (adapt to the detected language, keep coordinates verbatim):

```
Install Superpowers?

<capability_line OR "A free Claude Code skills library (94,000+ users) that adds structured brainstorming, planning, and subagent-driven-development skills used throughout this setup.">

(yes / no)
```

- `yes` → proceed to Step 2.
- `no` → record `superpowers_installed: false` in the calling skill's state and stop. The skill continues with the rest of its steps; every CLAUDE.md block gated on `superpowers_installed` is omitted.

## Step 2: Delegate to the installation protocol

Read `skills/_shared/installation-protocol.md` and follow it with the following
dependency spec:

- **name:** `superpowers`
- **type:** `required` (the protocol skips its own opt-in question — either the
  user already said `yes` here, or `mandatory: true`)
- **marketplace-id:** `superpowers@claude-plugins-official`
- **github:** `https://github.com/obra/superpowers`

The protocol sets `superpowers_installed`, `superpowers_scope`,
`superpowers_method` (and logs a warning line on failure). The calling skill
reuses those variables in its completion summary — this helper does not emit
its own summary line.

## Re-run behavior

Re-invoking the same setup skill re-runs the offer (unless `mandatory: true`).
That is intentional — re-running is the documented path to reconsider the
choice. Helpers MUST NOT persist a "user declined" marker that suppresses the
offer permanently.
