---
name: web-development-setup
description: Set up Claude for web development — frontend, backend, or full-stack. Configures framework-aware tool permissions, styling/linter conventions, env-var hygiene, and deploy-target pointers so Claude ships production-ready web apps from day one.
---

# Web Development Setup

This skill configures Claude for **web application development** — frontend SPAs, backend APIs, full-stack apps, and static sites. It is the right choice when the project centers on a JS/TS framework (Next.js, React, Vue, Svelte, SolidJS, Astro, Remix) or a web-backend stack (Node, Bun, Python FastAPI/Django, Go) serving HTTP traffic.

Use `coding-setup` for language-agnostic software projects (libraries, CLIs, generic services). Use `design-setup` for UI/UX design tooling (Figma, design systems) rather than application code.

**Handoff context:** Read `skills/_shared/consume-handoff.md` and run it with the handoff block (if any). The helper guarantees the following locals: `detected_language`, `existing_claude_md`, `inferred_use_case`, `repo_signals`, `graphify_candidate`. Use `detected_language` for all user-facing prose; generated file content stays in English.

**Existing CLAUDE.md:** If `existing_claude_md: true`, DO NOT overwrite it. Append a new delimited section at the end of the file:

```
<!-- onboarding-agent:start setup=web-development skill=web-development-setup section=claude-md -->
## Claude Onboarding Agent — Web Development Setup
...generated content...
<!-- onboarding-agent:end -->
```

If the delimited block already exists from a previous run (either the attributed form above or the legacy unattributed `<!-- onboarding-agent:start -->` form), replace only the content between the markers; leave the rest of the file untouched. Upgrade the opening marker to the attributed form while you are there — `/upgrade-setup` depends on it for detection.

## Supporting Files

Read these on-demand at the step that invokes them. Do not read eagerly.

- `rule-file-templates.md` — bodies of the `.claude/rules/*.md` files (Step 6)
- `framework-defaults.md` — Q1/Q2-conditional styling and deploy-target matrix (Step 4), plus public env-var prefix table
- `gitignore-block.md` — the `.gitignore` block and `.env.example` scaffold (Step 6)
- `document-skeletons.md` — `package.json`, `pyproject.toml`, and per-stack install commands (Step 6)
- `type-check-hook.template.sh` — bash source for the optional type-check PostToolUse hook, with `<PM_EXEC>` placeholder (Step 8)
- `skills/_shared/consume-handoff.md` — orchestrator handoff parse + inline fallback (preamble, before Step 1)
- `skills/_shared/offer-superpowers.md` — canonical Superpowers opt-in (Step 1)
- `skills/_shared/offer-github-mcp.md` — canonical GitHub MCP offer (Step 7)
- `skills/_shared/offer-graphify.md` — canonical Graphify opt-in (Step 9)

## Step 1: Install Dependencies

Read `skills/_shared/offer-superpowers.md` and run it with `skill_slug: web-development-setup`, `mandatory: false`, `capability_line: "A free Claude Code skills library (94,000+ users). Useful for planning multi-step features, structured brainstorming on routing / data modeling, and subagent-driven refactors across a web stack."` The helper asks the user, delegates to `skills/_shared/installation-protocol.md` on `yes`, and sets `superpowers_installed`, `superpowers_scope`, `superpowers_method`.

## Step 2: Detect Package Manager

Before asking Q4 below, probe the working directory (via Bash / Read) for a lockfile so the question can be skipped when the answer is unambiguous:

- `pnpm-lock.yaml` → set `pm_detected: pnpm`
- `package-lock.json` → set `pm_detected: npm`
- `yarn.lock` → set `pm_detected: yarn`
- `bun.lockb` or `bun.lock` → set `pm_detected: bun`
- None of the above → set `pm_detected: null`

If `pm_detected` is set, skip Q4 and reuse the detected value. Otherwise ask Q4.

## Step 3: Context Questions

Ask these questions ONE AT A TIME. Wait for each answer before asking the next.

1. **Project type** — "What are you building?
   A) Frontend only (SPA, static site rendered client-side)
   B) Backend API only (no UI served from this repo)
   C) Full-stack (UI + API in the same repo, e.g. Next.js app router, Remix, SvelteKit)
   D) Static site (pre-rendered HTML, blog, marketing, docs)"

2. **Framework** — "Which frontend framework? (pick 'none' if this is a backend-only repo)
   A) Next.js
   B) React (plain, Vite or CRA)
   C) Vue (Nuxt or plain)
   D) Svelte / SvelteKit
   E) SolidJS (plain or SolidStart)
   F) Astro
   G) Remix
   H) None — backend only"

3. **Backend stack** — ONLY ask if Q1 ≠ frontend-only AND Q1 ≠ static-site: "Which backend runtime and framework?
   A) Node.js — Express
   B) Node.js — Fastify
   C) Node.js — Hono
   D) Bun (Bun.serve / Hono / Elysia)
   E) Python — FastAPI (managed with `uv`)
   F) Python — Django (managed with `uv`)
   G) Go (net/http, chi, or gin)
   H) Same as framework (Next.js route handlers, Remix loaders/actions, SvelteKit endpoints)"

4. **Package manager** — "Which JavaScript package manager do you use?
   A) pnpm (default, recommended — fast, disk-efficient, strict)
   B) npm (ships with Node)
   C) yarn
   D) bun (if you are already on the Bun runtime)"
   (Skip this question if `pm_detected` from Step 2 is already set.)

5. **TypeScript** — "How strict should the TypeScript configuration be?
   A) TypeScript, `strict: true` (recommended)
   B) TypeScript, non-strict (gradual migration from JS)
   C) Plain JavaScript, no TypeScript"

6. **Testing stack** — "Which test runner do you want Claude to use?
   A) Vitest (recommended for Vite / Next.js / most modern frameworks)
   B) Jest (classic, large ecosystem)
   C) Playwright (end-to-end, browser automation)
   D) Cypress (end-to-end, interactive runner)
   E) None — set up tests later"

7. **Linting / formatting** — "Which linter + formatter stack?
   A) ESLint + Prettier (classic, most plugins available)
   B) Biome (single-binary, very fast, ESLint + Prettier in one)"

(The optional Superpowers install is handled by Step 1 via the shared installation protocol and is never forced.)

## Step 4: Derive Implied Defaults (do NOT ask)

Read `framework-defaults.md`. Use the matrix there to derive `styling_stack` and `deploy_target_hint` from Q1 and Q2. These are NOT asked as separate questions.

## Step 5: Verify Package Manager Tooling

Only run a probe for the selected / detected package manager. Do NOT probe all of them.

- Q4 = pnpm (A) → `pnpm --version`
- Q4 = npm (B) → `npm --version`
- Q4 = yarn (C) → `yarn --version`
- Q4 = bun (D) → `bun --version`

If the command fails:

- pnpm → print ONCE: "⚠ `pnpm` is not installed. Install from https://pnpm.io/installation and re-run this skill when ready. Setup continues as instructions-only — no `pnpm install` will be executed."
- yarn → print ONCE: "⚠ `yarn` is not installed. Install from https://yarnpkg.com/getting-started/install and re-run this skill when ready. Setup continues as instructions-only."
- bun → print ONCE: "⚠ `bun` is not installed. Install from https://bun.sh/ and re-run this skill when ready. Setup continues as instructions-only."
- npm → print ONCE: "⚠ `npm` is not available — Node.js is missing. Install Node LTS from https://nodejs.org/ and re-run this skill when ready."

Set `pm_available: false` in any failure case and continue. **Never silently fall back to npm** — the user picked their package manager for a reason.

If Q3 (backend) = Python (FastAPI or Django), additionally probe `uv --version`. If `uv` is missing, print ONCE: "⚠ `uv` is not installed. Python backend dependencies must be managed with `uv` in this plugin — install from https://docs.astral.sh/uv/getting-started/installation/ and re-run when ready." Never suggest `pip install`.

If Q3 (backend) = Go, probe `go version`. If missing, print ONCE: "⚠ `go` is not installed. Install from https://go.dev/dl/ — setup continues as instructions-only."

## Step 6: Offer Project-Local Subagent

Read `skills/_shared/emit-subagent.md` and follow it with these inputs:

- `slug`: `component-auditor`
- `purpose_blurb`: "Audit a component or an API route against the project's structure, routing, and naming conventions."
- `frontmatter_description`: "Use to audit a React/Vue/Svelte component or an API route for the project's structure, routing, and naming conventions. Dispatch when the user asks 'does this component match our conventions', 'audit this route', or 'review this component'."
- `tools_list`: `Read, Grep, Glob`
- `rules_files`: `.claude/rules/component-structure.md, .claude/rules/api-conventions.md`
- `body_markdown`:

  ```
  You are the Component Auditor. You audit a component file or an API route against the project's conventions.

  ## Procedure
  1. Identify the target file(s) from the caller's request.
  2. Read the relevant rules files (component-structure.md for UI, api-conventions.md for routes).
  3. Audit the target for: file location, naming, exports, prop/signature shape, colocation of styles/tests, routing convention, error-shape for APIs.
  4. Return a structured verdict: target file(s), findings (severity: blocker / suggestion / nit) with file:line, recommended fixes (describe, do not apply).

  ## Rules
  - Do not write code. Describe fixes; do not apply them.
  - If a rules file is missing, say so in your header and audit against the framework's idiomatic defaults.
  ```

Record the emit outcome (`emit_subagent`, `subagent_skipped_existing`, `subagent_deferred`) for use in the completion summary (Step 12). If `emit_subagent: true`, add `"component-auditor"` to the list passed to `skills/_shared/write-meta.md` in Step 10 as `subagents_installed`.

## Step 7: Offer GitHub MCP (conditional)

Read `skills/_shared/offer-github-mcp.md` and run it with `skill_slug: web-development-setup`. The helper carries the canonical trigger condition, install command, auth details, and pointer link, and sets `github_installed` (and `github_deferred` on `later`) for the CLAUDE.md generator and completion summary.

## Step 8: Generate Artifacts

For each file below, if it already exists extend rather than overwrite. Use `<!-- onboarding-agent:start setup=web-development skill=web-development-setup section=<name> -->` / `<!-- onboarding-agent:end -->` markers for CLAUDE.md; use `# onboarding-agent: web-development — start` / `# onboarding-agent: web-development — end` markers for `.gitignore`.

### CLAUDE.md (≤ 30 lines — pointers only)

Read `document-skeletons.md` and write its `CLAUDE.md` section to `CLAUDE.md` (as a delimited block if the file already exists). Fill in the `[Q…]`, `[styling_stack]`, `[deploy_target_hint]`, and conditional blocks based on the interview answers.

[Include ONLY if github_installed is true OR github_deferred is true — emitted per skills/_shared/offer-mcp.md Step 5]
Append a `## Configured MCP servers` subsection with one bullet:
```
## Configured MCP servers
- github: [see _shared/offer-mcp.md Step 5 for the exact per-state line format]
```

### .claude/rules/api-conventions.md

Read `rule-file-templates.md` and write its `api-conventions` section to `.claude/rules/api-conventions.md`. Skip the write if the file already exists (log `Skipped .claude/rules/api-conventions.md (already exists)`).

### .claude/rules/component-structure.md

Read `rule-file-templates.md` and write its `component-structure` section to `.claude/rules/component-structure.md`. Skip the write if the file already exists.

### .claude/rules/env-vars.md

Read `rule-file-templates.md` and write its `env-vars` section to `.claude/rules/env-vars.md`. Skip the write if the file already exists.

### package.json and install commands

Read `document-skeletons.md`. If `package.json` is missing and Q1 ≠ backend-only-Python-or-Go, emit the scaffold from the `package.json` section with `<pm>` expanded from Q4. Print the install commands from the "Install commands by stack" section matching Q2 / Q5 / Q6 / Q7. NEVER execute install commands without explicit user consent. If `pm_available: false`, print the commands as a manual checklist.

### pyproject.toml (only if Q3 = Python backend and `uv_available: true`)

Read `document-skeletons.md` and emit its `pyproject.toml` section plus the `uv add` commands. If `uv_available: false`, print as instructions only.

### .claude/settings.json

Create or extend `.claude/settings.json` with stack-appropriate permissions. **Merge** into the `permissions.allow` list if the file already exists (dedupe, never overwrite).

Base allow list (always included):

```json
{
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(node *)"
    ]
  }
}
```

Adapt based on answers:

- Q4 = pnpm → add `"Bash(pnpm *)"`, `"Bash(pnpm dlx *)"`
- Q4 = npm → add `"Bash(npm *)"`, `"Bash(npx *)"`
- Q4 = yarn → add `"Bash(yarn *)"`, `"Bash(yarn dlx *)"`
- Q4 = bun → add `"Bash(bun *)"`, `"Bash(bunx *)"`
- Q5 ≠ plain JS → add `"Bash(tsc *)"`, `"Bash(tsx *)"`
- Q6 = Vitest → add `"Bash(vitest *)"`
- Q6 = Jest → add `"Bash(jest *)"`
- Q6 = Playwright → add `"Bash(playwright *)"`
- Q6 = Cypress → add `"Bash(cypress *)"`
- Q7 = ESLint + Prettier → add `"Bash(eslint *)"`, `"Bash(prettier *)"`
- Q7 = Biome → add `"Bash(biome *)"`
- Q3 = Python (FastAPI/Django) → add `"Bash(uv *)"`, `"Bash(python *)"`, `"Bash(pytest *)"`, `"Bash(uvicorn *)"`
- Q3 = Go → add `"Bash(go *)"`
- Q2 = Next.js → add `"Bash(next *)"`
- Q2 = Astro → add `"Bash(astro *)"`
- Deploy-target CLIs (emit the matching one from `deploy_target_hint`): `"Bash(vercel *)"`, `"Bash(netlify *)"`, `"Bash(wrangler *)"`, `"Bash(fly *)"`

### Optional: type-check PostToolUse hook

Only ask if Q5 (TypeScript) = A (strict) or B (non-strict). Skip if Q5 = C (plain JS) — there is no tsc to run.

Ask ONCE (adapt to detected language):

> "Install the type-check-on-save hook? After every Edit/Write to a `.ts` or `.tsx` file, Claude Code runs `<pm> exec tsc --noEmit` scoped to the changed file and injects any type errors into the next turn. Silent on clean builds. (yes / no)"

Default on empty input: `yes`.

On `no`: set `web_hook_emitted: false` and skip the rest.

On `yes`:

1. Write the type-check script body. The script:
   - Reads the tool-call JSON from stdin.
   - Extracts `.tool_input.file_path` via `jq`.
   - If the path does not end in `.ts` or `.tsx`, exit silently.
   - If no `tsconfig.json` exists at `$CLAUDE_PROJECT_DIR`, exit silently.
   - Otherwise run `<pm> exec tsc --noEmit --pretty false <path>` (the package manager command is baked in from Q4 — `pnpm`, `npm`, `yarn`, or `bun`).
   - If tsc exits non-zero, emit `additionalContext` with the first 30 lines of its output. Silent on exit 0.

   Read `type-check-hook.template.sh`. That file is the exact script body. Substitute the `<PM_EXEC>` placeholder with the package-manager command selected from Q4:

   | Q4 package manager | `<PM_EXEC>` substitution |
   |---|---|
   | `pnpm` | `pnpm exec` |
   | `npm` | `npm exec` |
   | `yarn` | `yarn exec` |
   | `bun` | `bun x` |

   The substituted text becomes the `script_source` below. Do not alter the shebang, the generated-by header, or the `set -u` / `jq` / `tsc` logic.

2. Set the hook spec (the helper writes `"_plugin": "claude-onboarding-agent"` and `"_skill": "web-development-setup"` into the emitted entry):

   ```
   hook_entries = [
     {
       event: "PostToolUse",
       matcher: "Edit|Write",
       command: "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/web-type-check.sh\"",
       script_name: "web-type-check.sh",
       script_source: <contents of type-check-hook.template.sh with <PM_EXEC> substituted>
     }
   ]
   skill_slug = "web-development-setup"
   ```

3. Read `skills/_shared/emit-hook.md` and follow every step H1–H7.

4. Capture the status variables. Set `web_hook_emitted: true` on success.

### .gitignore and .env.example

Read `gitignore-block.md` for the web-specific additions and the delimited-marker shape. Inside the marker block, inline the Node/JS patterns from `skills/_shared/gitignore-node.md` and the shared common patterns from `skills/_shared/gitignore-common.md` (single source of truth for Node / OS / env / Claude-local lines). Append the fully assembled block to the user's `.gitignore`; if the marker block already exists, replace only the content between the markers. If `.env.example` is missing, emit the `.env.example` scaffold from `gitignore-block.md`.

## Step 9: Optional Graphify Integration

Read `skills/_shared/offer-graphify.md` and run it with:

- `host_setup_slug: "web-development"`
- `host_skill_slug: "web-development-setup"`
- `run_initial_build: true`
- `install_git_hook: true`
- `corpus_blurb: "your web project (TS/JS/Python/Go code via tree-sitter for 25 languages, Markdown docs, JSON schemas, images, OpenAPI specs). Particularly useful on large monorepos with many routes, components, and server modules"`

The helper owns the opt-in prompt and the three-way branch (yes / no / later),
delegating to `skills/_shared/graphify-install.md`. Record the `graphify_*`
variables it produces for use in Step 12.

## Step 10: Write Upgrade Metadata

Set `setup_slug: web-development`, `skill_slug: web-development-setup`. Resolve `plugin_version` from the plugin's own `plugin.json`. If Step 6 emitted the `component-auditor` subagent, set `subagents_installed: ["component-auditor"]`; otherwise leave it unset. Then follow `skills/_shared/write-meta.md` to create or merge `./.claude/onboarding-meta.json`. If Step 9 installed Graphify, `skills_used` will include both `web-development-setup` and `graphify-setup`.

## Step 11: Render Anchor Sections

Read `skills/_shared/anchor-mapping.md`. Locate the row for `setup_type: web-development`. For each anchor slug in that row:

1. Call `skills/_shared/render-anchor-section.md` with:
   - `setup_type: web-development`
   - `skill_slug: web-development-setup`
   - `anchor_slug: <slug>`
   - `target_file: ./CLAUDE.md`
   - `fallback_content: <embedded fallback from skills/anchors/SKILL.md for that slug>`
2. If a `./AGENTS.md` file was generated earlier in this skill, repeat the call with `target_file: ./AGENTS.md`.

Do not fail if any single `render-anchor-section.md` call returns `placeholder`. Collect rendered / placeholder slugs for the completion summary.

For every call, also capture `render_freshness`. When it is anything other than `network` or `cache` (i.e. `fallback` or `embedded`), record the `(anchor_slug, render_freshness)` pair in `anchor_freshness_notes`. The completion summary's `Anchor freshness` line consumes this list.

## Step 12: Completion Summary

```
✓ Web Development setup complete!

Files created / updated:
  CLAUDE.md                                       — pointers + workflow rules (delimited section)
  .claude/rules/api-conventions.md                — route layout, error shape, auth, OpenAPI
  .claude/rules/component-structure.md            — atomic/container split, server vs client, colocation
  .claude/rules/env-vars.md                       — public-prefix rules, deploy-target secret stores
  package.json                                    — [created scaffold | left untouched — already present | skipped — backend-only Python/Go]
  pyproject.toml                                  — [created | skipped — not a Python backend | skipped — uv missing]
  .claude/settings.json                           — tool permissions for [stack summary]
  .gitignore                                      — node_modules, framework build outputs, env files, test artifacts (delimited section)
  .env.example                                    — [created | left untouched — already present]
  .claude/agents/component-auditor.md             — project-local subagent (auto-invoked) [only on yes path; if skipped existing: .claude/agents/component-auditor.md (already existed — skipped; re-run /checkup --rebuild to regenerate); if no/later: Subagent component-auditor not installed — re-run /web-development-setup to add it later.]
  .claude/onboarding-meta.json                    — setup marker for /upgrade-setup

External skills:
  [✓ Superpowers installed via superpowers_method (superpowers_scope)]
  [skipped — install later with: /plugin install superpowers@claude-plugins-official]
  [⚠ Superpowers installation failed — install manually: https://github.com/obra/superpowers]

Environment:
  [✓ [pm] detected | ⚠ [pm] missing — see install link printed earlier]
  [✓ uv detected | ⚠ uv missing — https://docs.astral.sh/uv/getting-started/installation/]   (only if Python backend)
  [✓ go detected | ⚠ go missing — https://go.dev/dl/]                                         (only if Go backend)

Graphify (knowledge graph):
  [✓ installed via <installer>, /graphify + PreToolUse hook registered | ⚠ installed but hook not verified — run /graphify in a new session | — skipped: <reason> | — deferred: run /graphify-setup when ready | — not offered]

MCP servers:
  [one line per MCP considered, formatted per skills/_shared/offer-mcp.md Step 6 — omit if github trigger condition was false]

Hooks:
  [✓ type-check PostToolUse hook written to .claude/settings.json + .claude/hooks/web-type-check.sh
   | — skipped per user
   | ⚠ settings.json is corrupt — entries printed above for manual paste
   | — not offered (plain JavaScript)]

Anchor freshness:
  [omit the whole block if anchor_freshness_notes is empty; otherwise one line per entry:
   Anchor <anchor_slug> served from <render_freshness> — consider running /anchors to refresh.]

Next steps:
  1. Run the printed install commands (or create the project via the scaffolder, then `cd` in).
  2. Copy `.env.example` to `.env.local` and fill in your real values.
  3. Wire your deploy target's secret store (Vercel / Netlify / Cloudflare / Fly) — see .claude/rules/env-vars.md.
  4. Start a new Claude session: "Generate an initial [route / component / API handler] following the conventions in .claude/rules/." Claude will respect the rules in CLAUDE.md.
  5. [If Graphify installed] Try: /graphify query "where does the auth middleware live?"
  - Run `/anchors` any time to refresh the anchor-derived sections. If any section was rendered as a placeholder due to offline mode, re-run `/anchors` once you are back online.
```
