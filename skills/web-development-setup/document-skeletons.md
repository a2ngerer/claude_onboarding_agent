> Consumed by web-development-setup/SKILL.md at Step 6. Do not invoke directly.

# Document Skeletons — Web Development Setup

## CLAUDE.md (pointers-only, ≤ 30 lines)

Append a delimited block. Keep this file short — details belong in `.claude/rules/*.md`.

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

## package.json (when missing and Q1 ≠ backend-only-Python-or-Go)

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

## Install commands by stack

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

## pyproject.toml (when Q3 = Python backend and `uv_available: true`)

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
