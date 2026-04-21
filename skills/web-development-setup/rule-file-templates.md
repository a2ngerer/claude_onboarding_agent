> Consumed by web-development-setup/SKILL.md at Step 6. Do not invoke directly.

# Rule File Templates — Web Development Setup

This file holds the ready-to-write bodies of the three `.claude/rules/*.md` files the skill generates. SKILL.md instructs Claude which section to emit based on Q1–Q7 answers.

## api-conventions

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

## component-structure

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

## env-vars

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
