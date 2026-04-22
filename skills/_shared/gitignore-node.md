# Node / JS .gitignore patterns (shared)

> Consumed by `coding-setup` (Node/TS stack path) and `web-development-setup` (via its own `gitignore-block.md`). Do not invoke directly.

Canonical Node/JavaScript/TypeScript ignore patterns. Consumer skills that emit
a Node `.gitignore` must source these lines from here instead of re-listing
them inline. Non-Node-specific lines (`.env`, `.DS_Store`,
`.claude/settings.local.json`) live in `gitignore-common.md`.

```gitignore
# Node / package managers
node_modules/
.pnpm-store/
.npm/
.yarn/cache/
.yarn/install-state.gz

# Build output
dist/
build/
.next/
.nuxt/
.output/
.astro/
.svelte-kit/
.turbo/

# TypeScript / tooling caches
*.tsbuildinfo
.eslintcache
.cache/

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*
```
