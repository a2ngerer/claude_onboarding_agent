> Consumed by web-development-setup/SKILL.md at Step 4. Do not invoke directly.

# Framework Defaults — Web Development Setup

## Implied Styling and Deploy Targets

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

## Public Env-Var Prefix Table

A value placed in an env file is NOT automatically safe to ship to the browser — each framework uses a prefix to mark a value as public. Anything without the prefix stays server-only.

| Framework | Public prefix | Where it runs |
|---|---|---|
| Next.js | `NEXT_PUBLIC_` | Inlined into the client bundle at build time |
| Vite / React-Vite / SolidJS | `VITE_` | Inlined into the client bundle at build time |
| Astro | `PUBLIC_` | Inlined at build time |
| Nuxt | `NUXT_PUBLIC_` (runtimeConfig.public) | Exposed via `useRuntimeConfig().public` |
| SvelteKit | `PUBLIC_` | Imported from `$env/static/public` |
| Remix | No prefix — pass via loader | Loader returns data to the client explicitly |
