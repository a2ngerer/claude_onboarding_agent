# Offer Graphify (shared procedure)

> Consumed by `coding-setup`, `web-development-setup`, `data-science-setup`, `research-setup`, and `knowledge-base-setup` at their Graphify step. Do not invoke directly.

Canonical opt-in prompt and delegation target for the Graphify knowledge-graph
integration (https://github.com/safishamsi/graphify). Every consumer skill
points here so the opt-in wording, the `yes/no/later` paths, and the call into
`graphify-install.md` stay identical across the plugin.

## Contract

The calling skill sets these inputs (inline in its own prose, not as structured
arguments) before reading this file:

| Parameter | Example | Purpose |
|---|---|---|
| `host_setup_slug` | `coding` \| `web-development` \| `data-science` \| `knowledge-base` \| `research` | Written onto the `setup=<slug>` attribute of the CLAUDE.md marker by the install protocol |
| `host_skill_slug` | `coding-setup` \| `web-development-setup` \| `data-science-setup` \| `knowledge-base-setup` \| `research-setup` | Calling-skill directory name; the install protocol logs it under `skills_used` |
| `run_initial_build` | `true` \| `false` | Passed through to `graphify-install.md`; controls whether step G6 offers `graphify .` on the current project |
| `install_git_hook` | `true` \| `false` | Passed through to `graphify-install.md`; controls whether step G7 offers `graphify hook install` |
| `corpus_blurb` | "your web project (TS/JS/Python/Go code…)" | One-sentence adaptation of the corpus sentence. Swapped into the `{corpus_blurb}` placeholder below. Keep it short and concrete — the helper supplies the rest of the pitch. |

## Step 1: Prompt the user

Ask ONCE (adapt to the detected language; keep the URL and slash-command
verbatim):

```
Install Graphify knowledge-graph integration now?

Graphify indexes {corpus_blurb} into a local graph, registers a `/graphify` slash command, and adds a PreToolUse hook that consults the graph BEFORE Claude runs Grep / Glob / Read. This cuts token cost substantially on large corpora. See https://github.com/safishamsi/graphify.

(yes / no / later)
```

## Step 2: Branch on the answer

- **yes** → read `skills/_shared/graphify-install.md` and follow steps G1–G9
  with the inputs above (`host_setup_slug`, `host_skill_slug`,
  `run_initial_build`, `install_git_hook`). That protocol handles all
  prerequisite probes, install, hook registration, verification, and appends
  the attributed CLAUDE.md section `setup=<host_setup_slug>
  skill=graphify-setup section=graphify`.

- **no** → set `graphify_installed: false` and return. No CLAUDE.md change, no
  further prompts. The calling skill proceeds to its next step.

- **later** → invoke `skills/_shared/graphify-install.md` in "later" mode: skip
  steps G1–G7 entirely, write ONLY the short deferred pointer block described
  in its Step G8 "later" variant. Set `graphify_installed: false`,
  `graphify_deferred: true`.

## Step 3: Return status

The calling skill reuses the `graphify_*` variables set by
`graphify-install.md` (see its Step G9) in its own completion summary. This
helper does not emit a summary line — one source of truth for the wording
lives in the install protocol.
