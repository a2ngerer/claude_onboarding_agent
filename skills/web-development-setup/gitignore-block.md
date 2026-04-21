> Consumed by web-development-setup/SKILL.md at Step 6. Do not invoke directly.

# Gitignore and .env.example — Web Development Setup

## .gitignore block

Append this delimited block at the end of the user's `.gitignore`. If the marker block already exists, replace only the content between the markers.

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

## .env.example scaffold

If `.env.example` is missing, emit this minimal one based on the stack:

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
