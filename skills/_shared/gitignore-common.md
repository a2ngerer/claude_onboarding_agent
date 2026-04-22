# Common .gitignore patterns (shared)

> Consumed by every setup skill that generates a project `.gitignore`. Do not invoke directly.

Canonical OS / editor / environment / Claude-local ignore patterns. Consumer
skills must append this block (or the relevant subset) to every generated
`.gitignore` regardless of stack. Stack-specific patterns live in
`gitignore-python.md` and `gitignore-node.md`.

```gitignore
# Env files (NEVER commit local secrets)
.env
.env.local
.env.*.local

# Editor / OS noise
.DS_Store
Thumbs.db
.idea/
.vscode/

# Claude local settings
.claude/settings.local.json
```
