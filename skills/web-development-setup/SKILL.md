---
name: web-development-setup
description: Set up Claude for web development — frontend, backend, or full-stack. Configures framework-aware tool permissions, styling/linter conventions, env-var hygiene, and deploy-target pointers so Claude ships production-ready web apps from day one.
---

# Web Development Setup

This skill configures Claude for **web application development** — frontend SPAs, backend APIs, full-stack apps, and static sites. It is the right choice when the project centers on a JS/TS framework (Next.js, React, Vue, Svelte, SolidJS, Astro, Remix) or a web-backend stack (Node, Bun, Python FastAPI/Django, Go) serving HTTP traffic.

Use `coding-setup` for language-agnostic software projects (libraries, CLIs, generic services). Use `design-setup` for UI/UX design tooling (Figma, design systems) rather than application code.

**Language:** Use `detected_language` from handoff context, or detect from the user's first message and use it throughout. All generated file content stays in English.

**Existing CLAUDE.md:** If `existing_claude_md: true` in handoff context, or if `CLAUDE.md` already exists in the filesystem, DO NOT overwrite it. Append a new delimited section at the end of the file:

```
<!-- onboarding-agent:start setup=web-development skill=web-development-setup section=claude-md -->
## Claude Onboarding Agent — Web Development Setup
...generated content...
<!-- onboarding-agent:end -->
```

If the delimited block already exists from a previous run (either the attributed form above or the legacy unattributed `<!-- onboarding-agent:start -->` form), replace only the content between the markers; leave the rest of the file untouched. Upgrade the opening marker to the attributed form while you are there — `/upgrade` depends on it for detection.

## Step 1: Install Dependencies

Read `skills/_shared/installation-protocol.md` and follow it for each dependency below.

Dependencies:
- Superpowers (optional) — description: "A free Claude Code skills library (94,000+ users). Useful for planning multi-step features, structured brainstorming on routing / data modeling, and subagent-driven refactors across a web stack." — marketplace-id: `superpowers@claude-plugins-official`, github: `https://github.com/obra/superpowers`, name: `superpowers`

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

To keep the interview ≤ 7 questions, infer the following from Q2 / Q1 rather than asking:

| Framework (Q2) | Implied styling | Deploy-target pointer | Extra notes |
|---|---|---|---|
| Next.js | Tailwind CSS + CSS Modules | Vercel (primary) / self-hosted Node | App Router assumed; `NEXT_PUBLIC_*` env convention |
| React (Vite) | Tailwind CSS | Netlify / Cloudflare Pages / Vercel | Client-only by default |
| Vue / Nuxt | Tailwind CSS or scoped `<style>` | Netlify / Vercel | Nuxt has its own server routes |
| Svelte / SvelteKit | Tailwind or component-scoped CSS | Cloudflare / Vercel / Netlify | Adapter chosen at build time |
| SolidJS | Tailwind CSS | Cloudflare / Vercel | |
| Astro | Scoped `<style>` + Tailwind for design systems | Netlify / Cloudflare Pages / Vercel | Islands architecture |
| Remix | Tailwind CSS | Cloudflare / Vercel / Fly.io | Loaders / actions do server work |
| None (backend-only) | n/a | Fly.io / Railway / self-hosted / Lambda | No styling stack |

For Q1 = static site: deploy-target defaults to Netlify / Cloudflare Pages / GitHub Pages.

Record the implied styling + deploy target as `styling_stack` and `deploy_target_hint` — they go into CLAUDE.md pointers but are not asked as separate questions.

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

## Step 6: Generate Artifacts

For each file below, if it already exists extend rather than overwrite. Use `<!-- onboarding-agent:start setup=web-development skill=web-development-setup section=<name> -->` / `<!-- onboarding-agent:end -->` markers for CLAUDE.md; use `# onboarding-agent: web-development — start` / `# onboarding-agent: web-development — end` markers for `.gitignore`.

### CLAUDE.md (≤ 30 lines — pointers only)

```markdown
# Claude Instructions — Web Development

## Project Context
Type: [Q1]. Framework: [Q2]. Backend: [Q3 or "n/a"]. Package manager: [Q4]. TypeScript: [Q5]. Tests: [Q6]. Lint/format: [Q7].
Implied styling: [styling_stack]. Likely deploy target: [deploy_target_hint].

## Key Pointers
- Route conventions, error shape, auth header: `.claude/rules/api-conventions.md`
- Component structure, server vs client split, colocation: `.claude/rules/component-structure.md`
- Env var handling and secrets hygiene: `.claude/rules/env-vars.md`

## Workflow Rules
- Package manager: always use [Q4] — never mix managers in the same repo. Commit the lockfile.
- TypeScript: [strict / non-strict / off] — match the tsconfig; do not weaken it to fix a type error.
- Tests live next to source (`Component.tsx` + `Component.test.tsx`) for unit tests; [Q6 = Playwright/Cypress] e2e tests live under `e2e/`.
- Secrets: never hardcode, never commit `.env.local`. Client-exposed values must use the framework's public prefix.
- [If Q3 = Python backend] Python deps via `uv add` — never `pip install`.

[Include ONLY if superpowers_installed is true]
## Superpowers
Superpowers is installed. Use `superpowers:brainstorming` before non-trivial feature work and `superpowers:writing-plans` for multi-page or multi-route changes.
```

Keep this file short (≤ 30 lines). Details belong in `.claude/rules/*.md`.

### .claude/rules/api-conventions.md

```markdown
# API Conventions

## Route layout
- REST-style resources: `GET /api/v1/<resource>`, `GET /api/v1/<resource>/:id`, `POST /api/v1/<resource>`, `PATCH /api/v1/<resource>/:id`, `DELETE /api/v1/<resource>/:id`.
- Version in the path (`/api/v1/…`) so breaking changes can coexist. Never version via query string.
- Framework-specific layout:
  - Next.js: route handlers under `app/api/<resource>/route.ts` (App Router) or `pages/api/<resource>.ts` (Pages Router). Prefer the App Router for new projects.
  - Remix: loaders/actions colocated with the route file.
  - SvelteKit: `+server.ts` colocated with the route.
  - Standalone Node/Bun/Python/Go: one route module per resource, grouped under `src/routes/` or `app/routes/`.

## Error response shape
Every error returns a consistent JSON body:

```json
{
  "error": {
    "code": "string_snake_case_code",
    "message": "Human-readable message for UI display",
    "details": { "field": "optional field-level info" }
  }
}
```

- HTTP status mirrors the class (400 validation, 401 unauthenticated, 403 forbidden, 404 not found, 409 conflict, 422 unprocessable, 500 server).
- Never leak stack traces or DB errors to the client — log them server-side with a request id, return only `code` + safe `message`.

## Auth header convention
- Bearer tokens: `Authorization: Bearer <token>`.
- Session cookies: `HttpOnly`, `Secure`, `SameSite=Lax` (strict for same-site-only flows).
- Never accept tokens from query strings; never log full tokens.

## Request validation
- Node / Bun: use `zod` or `valibot` to parse request bodies; reject with 400 + the error shape above.
- Python FastAPI: use Pydantic models — FastAPI handles validation and OpenAPI generation automatically.
- Python Django: use DRF serializers or `django-ninja` (Pydantic-based) for API endpoints.
- Go: use `encoding/json` + explicit struct tags; add validator.v10 for field-level rules.

## OpenAPI / schema
- FastAPI: OpenAPI at `/docs` (Swagger) and `/redoc` — keep it enabled in development, disable in production if the API is private.
- Node backends: generate OpenAPI from `zod` schemas via `zod-openapi`, serve at `/docs`.
- Commit the generated `openapi.json` / `openapi.yaml` so Claude can read it when helping with client code.

## Rate limiting and idempotency
- Rate limit public endpoints by IP + user id.
- For POST/PATCH on money-like or side-effecting resources, accept an `Idempotency-Key` header and store recent keys for 24h.
```

### .claude/rules/component-structure.md

```markdown
# Component Structure

## File layout
- One component per file. Filename matches the default export: `UserCard.tsx` exports `UserCard`.
- Colocation: tests, styles, and helpers live next to the component.
  ```
  components/UserCard/
    UserCard.tsx
    UserCard.test.tsx
    UserCard.module.css        # or .stories.tsx if Storybook is used
    index.ts                    # re-exports UserCard
  ```
- Shared primitives live under `components/ui/` (buttons, inputs, dialogs).
- Feature-specific components live under `features/<feature>/components/` or `app/<route>/components/` for Next.js App Router.

## Atomic vs container split
- **Presentational** components: stateless, take props, render UI. No direct API calls, no `useRouter`, no `useSession`.
- **Container** components: own data fetching, side effects, routing. They compose presentational components.
- The rule Claude should follow: if a component reaches for a data source or a global hook, it is a container — put it under `features/<name>/` or `app/<route>/`, not `components/ui/`.

## Next.js App Router: server vs client components
- Default is **server component**. Do not add `"use client"` unless the component uses state, effects, refs, or browser-only APIs.
- Server components can read secrets, hit the database directly, and import server-only modules.
- Client components must NEVER import server-only code (env vars without `NEXT_PUBLIC_`, `fs`, DB drivers). The bundler will leak them into the browser.
- Passing server data to client components: serialize through props — no class instances, no functions, no `Date` (send ISO strings).

## React / non-Next frameworks
- Hooks live in `hooks/useThing.ts` — one hook per file, name starts with `use`.
- Context providers live in `providers/` — one provider per file, named `XProvider`.

## Vue / Svelte / Solid
- Single-file components with scoped styles by default.
- Shared composables (Vue) / stores (Svelte) / signals (Solid) live under `composables/` / `stores/` / `signals/` respectively.

## Astro
- `.astro` components are server-rendered by default. Use `client:load` / `client:idle` / `client:visible` directives sparingly — islands, not SPAs.

## Naming
- Components: `PascalCase`. Hooks: `useCamelCase`. Utilities: `camelCase`. Constants: `SCREAMING_SNAKE_CASE`.
- Test files: `X.test.tsx` (unit) or `X.e2e.ts` (Playwright/Cypress, under `e2e/`).

## What Claude should NOT do
- Do not create a `utils.ts` dumping ground — group helpers by domain.
- Do not add a layer of abstraction (HOC, render-prop, wrapper hook) unless two concrete call sites already need it.
- Do not convert server components to client components to "fix" a compile error — fix the import instead.
```

### .claude/rules/env-vars.md

```markdown
# Env Var Handling

## File layout
- `.env` — committed defaults for non-secret values (e.g. `NODE_ENV=development`, public URLs).
- `.env.local` — local secrets and overrides. **Never committed.** Listed in `.gitignore`.
- `.env.production` — production values. Committed only if it contains no secrets (pure references), otherwise managed via the deploy target's secret store.
- `.env.test` — values used by the test runner. Safe to commit if they point to local fixtures.

## Framework conventions for client-exposed values
A value placed in an env file is NOT automatically safe to ship to the browser — each framework uses a prefix to mark a value as public. Anything without the prefix stays server-only.

| Framework | Public prefix | Where it runs |
|---|---|---|
| Next.js | `NEXT_PUBLIC_` | Inlined into the client bundle at build time |
| Vite / React-Vite / SolidJS | `VITE_` | Inlined into the client bundle at build time |
| Astro | `PUBLIC_` | Inlined at build time |
| Nuxt | `NUXT_PUBLIC_` (runtimeConfig.public) | Exposed via `useRuntimeConfig().public` |
| SvelteKit | `PUBLIC_` | Imported from `$env/static/public` |
| Remix | No prefix — pass via loader | Loader returns data to the client explicitly |

**The rule Claude must follow:** any secret (API key, DB URL, auth secret) that lacks the framework's public prefix MUST NOT appear in a client component or client-side import chain. If the user asks to "use `STRIPE_SECRET_KEY` in the checkout button", Claude refuses and suggests a server route + fetch instead.

## Reading env vars
- Node / Bun: `process.env.FOO` (Node) or `Bun.env.FOO`. Validate with `zod` or `valibot` at startup — fail fast if required vars are missing.
- Python: read via `os.environ["FOO"]` with a default; prefer `pydantic-settings` for typed config.
- Go: `os.Getenv("FOO")` with an explicit validation pass at startup.

## What Claude should NOT do
- Never print secrets in logs — not even masked.
- Never write a secret into `CLAUDE.md`, `README.md`, or any committed file.
- Never hardcode an API key "just for testing" — use `.env.local` even for one-off scripts.
- Never add a new env var without also adding it to `.env.example` (with a placeholder value) so teammates know it exists.

## Deploy-target hints
- **Vercel**: secrets via Project → Settings → Environment Variables. Pull locally with `vercel env pull .env.local`.
- **Netlify**: secrets via Site settings → Environment variables or `netlify env:set`.
- **Cloudflare Pages / Workers**: `wrangler secret put FOO` for server-side; plain vars via `wrangler.toml` or the dashboard.
- **Self-hosted / Docker**: inject via the orchestrator (systemd `EnvironmentFile=`, docker-compose `env_file:`, k8s `Secret` mounted as env).
- **Fly.io**: `fly secrets set FOO=bar` — applies on next deploy.
```

### package.json (minimal, only if none exists AND Q1 ≠ backend-only-Python-or-Go)

If `package.json` already exists, leave it untouched and only print the recommended install commands. If it does not exist and the stack needs one, emit a minimal scaffold based on Q4:

```json
{
  "name": "your-project",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "packageManager": "<Q4>@<latest>",
  "scripts": {
    "dev": "...",
    "build": "...",
    "test": "...",
    "lint": "...",
    "format": "..."
  }
}
```

Then print the recommended install commands (NEVER execute without explicit user consent):

- Q2 = Next.js: `<pm> create next-app@latest .` (or `<pm> add next react react-dom` into an existing folder)
- Q2 = React (Vite): `<pm> create vite@latest . -- --template react-ts`
- Q2 = Vue / Nuxt: `<pm> create nuxt@latest .` or `<pm> create vite@latest . -- --template vue-ts`
- Q2 = Svelte / SvelteKit: `<pm> create svelte@latest .`
- Q2 = SolidJS: `<pm> create solid@latest .`
- Q2 = Astro: `<pm> create astro@latest .`
- Q2 = Remix: `<pm> create remix@latest .`
- Q6 = Vitest: `<pm> add -D vitest @vitest/ui jsdom @testing-library/react @testing-library/jest-dom`
- Q6 = Jest: `<pm> add -D jest @types/jest ts-jest @testing-library/react`
- Q6 = Playwright: `<pm> dlx playwright install` after `<pm> add -D @playwright/test`
- Q6 = Cypress: `<pm> add -D cypress`
- Q7 = ESLint + Prettier: `<pm> add -D eslint prettier eslint-config-prettier`
- Q7 = Biome: `<pm> add -D @biomejs/biome` + `<pm> biome init`
- Q5 = TypeScript (A or B): `<pm> add -D typescript @types/node`

Where `<pm>` expands to `pnpm`, `npm`, `yarn`, or `bun` based on Q4. Use `pnpm dlx` / `npx` / `yarn dlx` / `bunx` for one-shot runners.

If `pm_available: false`, print these as a manual checklist instead of recommending execution.

### pyproject.toml (only if Q3 = Python backend AND `uv_available: true`)

Emit a minimal scaffold and print `uv add` commands — never execute them without consent.

```toml
[project]
name = "your-backend"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = []

[tool.uv]
dev-dependencies = []
```

- Q3 = FastAPI: `uv add fastapi uvicorn[standard] pydantic pydantic-settings`
- Q3 = Django: `uv add django django-ninja pydantic-settings`
- Dev: `uv add --dev pytest pytest-asyncio httpx ruff`

If `uv` is missing, print the commands as instructions only.

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

### .gitignore

Append a delimited block at the end. If the marker block already exists, replace only the content between the markers.

```gitignore
# onboarding-agent: web-development — start
# Node / package managers
node_modules/
.pnpm-store/
.npm/
.yarn/cache/
.yarn/install-state.gz

# Framework build output
dist/
build/
.next/
.nuxt/
.output/
.astro/
.svelte-kit/
.turbo/
.vercel/
.netlify/
.wrangler/

# Env files (NEVER commit local secrets)
.env
.env.local
.env.*.local

# Test artifacts
coverage/
.nyc_output/
playwright-report/
test-results/
cypress/videos/
cypress/screenshots/

# TypeScript / tooling caches
*.tsbuildinfo
.eslintcache
.cache/

# Editor / OS noise
.DS_Store
Thumbs.db

# Claude local settings
.claude/settings.local.json
# onboarding-agent: web-development — end
```

Note: `.env.example` (without `.local`) is intentionally NOT ignored — it serves as the committed template listing every required variable with placeholder values.

### Optional: .env.example scaffold

If `.env.example` is missing, emit a minimal one based on the stack:

```
# Copy to .env.local and fill in real values. Never commit secrets.
NODE_ENV=development

# Public, client-exposed values (pick the prefix that matches your framework)
# NEXT_PUBLIC_APP_URL=http://localhost:3000
# VITE_APP_URL=http://localhost:5173
# PUBLIC_APP_URL=http://localhost:4321

# Server-only secrets (DO NOT expose to the client)
# DATABASE_URL=
# AUTH_SECRET=
```

## Step 7: Optional Graphify Integration

Ask ONCE (adapt to detected language):

> "Install Graphify knowledge-graph integration now?
>
> Graphify indexes your web project (TS/JS/Python/Go code via tree-sitter for 25 languages, Markdown docs, JSON schemas, images, OpenAPI specs) into a local graph, registers a `/graphify` slash command, and adds a PreToolUse hook that consults the graph BEFORE Claude runs Grep / Glob / Read. Particularly useful on large monorepos with many routes, components, and server modules. See https://github.com/safishamsi/graphify.
>
> (yes / no / later)"

- **yes** → set `host_setup_slug: "web-development"`, `host_skill_slug: "web-development-setup"`, `run_initial_build: true`, `install_git_hook: true`. Read `skills/_shared/graphify-install.md` and follow steps G1–G9 in order. The protocol writes the attributed CLAUDE.md section with `setup=web-development skill=graphify-setup section=graphify`.
- **no** → set `graphify_installed: false` and skip to Step 8.
- **later** → invoke `skills/_shared/graphify-install.md` in "later" mode: skip G1–G7 and write only the short deferred pointer block. Set `graphify_installed: false`, `graphify_deferred: true`.

## Step 8: Write Upgrade Metadata

Set `setup_slug: web-development`, `skill_slug: web-development-setup`. Resolve `plugin_version` from the plugin's own `plugin.json`. Then follow `skills/_shared/write-meta.md` to create or merge `./.claude/onboarding-meta.json`. If Step 7 installed Graphify, `skills_used` will include both `web-development-setup` and `graphify-setup`.

## Step 9: Completion Summary

```
✓ Web Development setup complete!

Files created / updated:
  CLAUDE.md                                       — pointers + workflow rules (delimited section)
  .claude/rules/api-conventions.md          — route layout, error shape, auth, OpenAPI
  .claude/rules/component-structure.md      — atomic/container split, server vs client, colocation
  .claude/rules/env-vars.md                 — public-prefix rules, deploy-target secret stores
  package.json                                    — [created scaffold | left untouched — already present | skipped — backend-only Python/Go]
  pyproject.toml                                  — [created | skipped — not a Python backend | skipped — uv missing]
  .claude/settings.json                           — tool permissions for [stack summary]
  .gitignore                                      — node_modules, framework build outputs, env files, test artifacts (delimited section)
  .env.example                                    — [created | left untouched — already present]
  .claude/onboarding-meta.json                    — setup marker for /upgrade

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

Next steps:
  1. Run the printed install commands (or create the project via the scaffolder, then `cd` in).
  2. Copy `.env.example` to `.env.local` and fill in your real values.
  3. Wire your deploy target's secret store (Vercel / Netlify / Cloudflare / Fly) — see .claude/rules/env-vars.md.
  4. Start a new Claude session: "Generate an initial [route / component / API handler] following the conventions in .claude/rules/." Claude will respect the rules in CLAUDE.md.
  5. [If Graphify installed] Try: /graphify query "where does the auth middleware live?"
```
