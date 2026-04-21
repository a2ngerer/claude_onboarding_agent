# Write Upgrade Metadata

This file is read by setup skills at the end of their flow. It writes (or merges into) `.claude/onboarding-meta.json` so `/upgrade-setup` can later detect the setup and re-apply current best practices without touching user customizations.

## Inputs (set by the calling skill before reading this file)

- `setup_slug` — one of `coding`, `data-science`, `design`, `knowledge-base`, `devops`, `content-creator`, `office`, `research`, `academic-writing`
- `skill_slug` — the skill's directory name under `skills/` (e.g. `coding-setup`, `knowledge-base-setup`)
- `plugin_version` — read from the plugin's own `plugin.json` `"version"` field. Resolve it at runtime from `~/.claude/plugins/claude-onboarding-agent/.claude-plugin/plugin.json` or the project-local equivalent. If unreadable, use the string `"unknown"`.
- `subagents_installed` — optional. List of project-local subagent slugs this invocation installed (e.g. `["code-reviewer"]`). Passed by skills that invoke `skills/_shared/emit-subagent.md`. Omit or pass `[]` when the skill installed no subagents.

## Schema

The JSON file shape written by this helper:

- `setup_type: string` — primary setup slug (first one to run).
- `skills_used: string[]` — directory names under `skills/` that have contributed. Union-merged across runs.
- `plugin_version: string` — resolved from the plugin's `plugin.json`; `"unknown"` if unresolvable.
- `installed_at: string` — ISO-8601 UTC timestamp of the first write.
- `upgraded_at: string | null` — set only by `/upgrade-setup`.
- `subagents_installed: string[]` — slugs of project-local subagents installed by the plugin (e.g., `"code-reviewer"`, `"component-auditor"`). Union-merged across runs. Omitted from the object if the calling skill did not pass `subagents_installed` AND no prior file had the key.

## Protocol

### Step M1 — Read existing file if present

Read `./.claude/onboarding-meta.json` if it exists. Parse as JSON.

- If it exists and parses: set `existing_meta: <parsed>`.
- If it exists but does not parse: print once: `"⚠ .claude/onboarding-meta.json exists but is not valid JSON — leaving it untouched so you can recover it manually."` and skip the rest of this protocol. Do not overwrite it.
- If it does not exist: set `existing_meta: null`.

### Step M2 — Merge

Produce the new meta object:

```json
{
  "setup_type": "<setup_slug>",
  "skills_used": [<merged list>],
  "plugin_version": "<plugin_version>",
  "installed_at": "<existing_meta.installed_at OR now ISO-8601 UTC>",
  "upgraded_at": null,
  "subagents_installed": [<merged list>]
}
```

Merging rules for `skills_used`:

- If `existing_meta` is null: `skills_used = [<skill_slug>]`.
- If `existing_meta.skills_used` exists and is a list: `skills_used = dedupe(existing_meta.skills_used + [<skill_slug>])`, preserving first-seen order.
- If `existing_meta.skills_used` is missing or the wrong type: `skills_used = [<skill_slug>]`.

Merging rules for `subagents_installed`:

- Start with `prior = existing_meta.subagents_installed` if it exists and is a list; otherwise `prior = []`.
- Start with `incoming = subagents_installed` (the input passed by the calling skill) if it exists and is a list; otherwise `incoming = []`.
- `subagents_installed = dedupe(prior + incoming)`, preserving first-seen order.
- If the resulting list is empty AND `existing_meta` did not have the key, omit the `subagents_installed` key from the written object (keep the file minimal).
- If the resulting list is non-empty OR `existing_meta` already had the key, always write the key (even if empty) — once a project records subagent ownership, the field stays.

Merging rule for `setup_type`:

- If `existing_meta.setup_type` is set AND differs from the current `setup_slug`: keep the existing value. A project may run multiple setup skills (e.g. `coding-setup` then `devops-setup`); `setup_type` records the **primary** one — the first one that ran. The `skills_used` array captures every skill that has contributed.

Merging rule for `installed_at`:

- If `existing_meta.installed_at` is set: keep it.
- Otherwise: write the current ISO-8601 UTC timestamp (`YYYY-MM-DDTHH:MM:SSZ`).

Always reset `upgraded_at` to `null` — only the `/upgrade-setup` skill sets it.

### Step M3 — Write

Ensure `./.claude/` exists (`mkdir -p` via Bash). Write the merged object to `./.claude/onboarding-meta.json` with 2-space indent and a trailing newline.

### Step M4 — Record in completion summary

Tell the calling skill to mention the file in its completion summary, e.g.:

```
  .claude/onboarding-meta.json — setup marker for /upgrade-setup
```
