> Consumed by web-development-setup/SKILL.md at Step 6. Do not invoke directly.

# Gitignore and .env.example — Web Development Setup

## .gitignore block

Append a delimited block at the end of the user's `.gitignore`. If the marker block already exists, replace only the content between the markers.

The block is assembled from the canonical Node/JS patterns in `skills/_shared/gitignore-node.md`, the common patterns in `skills/_shared/gitignore-common.md`, and the web-specific additions below. Do NOT duplicate Node or common patterns inline — read them from the shared helpers.

Web-specific additions (inside the marker block, after the shared patterns):

```gitignore
# onboarding-agent: web-development — start
# ... (inline skills/_shared/gitignore-node.md here)
# ... (inline skills/_shared/gitignore-common.md here)

# Framework build output (web-specific — not in shared node block)
.vercel/
.netlify/
.wrangler/

# Test artifacts
coverage/
.nyc_output/
playwright-report/
test-results/
cypress/videos/
cypress/screenshots/
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
