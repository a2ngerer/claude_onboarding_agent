---
name: mcp-servers
description: Recommended MCP servers by use case for Claude Code
last_updated: 2026-05-29
sources:
  - https://docs.claude.com/en/docs/claude-code/mcp
  - https://github.com/modelcontextprotocol/servers
  - https://www.anthropic.com/engineering
version: 3
---

## Discovery

Browse reviewed connectors at the **Anthropic Directory** (`claude.ai/directory`). Any remote server listed there can be added with `claude mcp add --transport http <name> <url>`. For building your own server, use the `mcp-server-dev` plugin: `/plugin install mcp-server-dev@claude-plugins-official`, then `/mcp-server-dev:build-mcp-server`.

## Recommended

- `filesystem` — scoped filesystem access beyond the working directory
- `git` — read git history, blame, diffs without shelling out
- `github` — issues, PRs, reviews via GitHub's first-party remote MCP
- `obsidian` (official CLI + `obsidian-vault-keeper` subagent) — vault I/O without always-on tool schemas
- `figma-context` — read Figma frames into context for UI work
- `slack` — read channels, post messages
- `linear` — issues and projects (official Linear MCP)
- `gmail` / `calendar` — Google productivity via official MCPs where available

Keep the set small: every installed MCP expands the tool-selection surface and the trust boundary.

## Coding

- **filesystem** — `claude mcp add filesystem npx -- -y @modelcontextprotocol/server-filesystem <path>`
- **git** — `claude mcp add git uvx -- mcp-server-git`
- **github** (first-party remote HTTP) — `claude mcp add --transport http github https://api.githubcopilot.com/mcp/ --header "Authorization: Bearer YOUR_GITHUB_PAT"`
- **sentry** — `claude mcp add --transport http sentry https://mcp.sentry.dev/mcp`

## Knowledge base

- **obsidian** — use the official Obsidian CLI plus the `obsidian-vault-keeper` subagent. The older third-party Obsidian MCP has known correctness issues; prefer this path. See `skills/knowledge-base-builder/SKILL.md`.

## Design

- **figma-context** — read Figma frames into context for UI work. See https://github.com/GLips/Figma-Context-MCP

## Productivity

- **slack** — `claude mcp add slack npx -- -y @modelcontextprotocol/server-slack`
- **linear** — via Linear's official MCP integration.
- **gmail / calendar** — via official Google MCP integrations where available.

## DevOps / cloud

- **kubernetes** — cluster read access, kubectl-equivalent queries. Community servers available; pin a version before production use.
- **aws / gcp** — prefer official CLIs wrapped via allowed Bash permissions; MCP wrappers exist but are less mature.

## Configuration tips

- Add a `"description"` field to each `.claude/settings.json` entry so Claude knows when to pick the server.
- Set `alwaysLoad: true` on servers whose tools Claude needs on every turn (e.g. a core project database). All other servers are deferred by default via MCP Tool Search.
- Keep the installed set small. Every MCP server adds tool-selection overhead and expands the trust surface.
- For read-only inspection tasks, prefer a CLI + Bash allowlist over an MCP server.
- **SSE transport is deprecated** — use `--transport http` for new remote server additions.
- Scopes: `local` (default, private to your project), `project` (shared via `.mcp.json`), `user` (cross-project).
