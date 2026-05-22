---
name: mcp-servers
description: Recommended MCP servers by use case for Claude Code
last_updated: 2026-05-22
sources:
  - https://docs.claude.com/en/docs/claude-code/mcp
  - https://github.com/modelcontextprotocol/servers
  - https://www.anthropic.com/engineering
version: 3
---

## Finding servers

Browse reviewed connectors in the **Anthropic Directory** at `claude.ai/directory`. Any remote server listed there can be added with `claude mcp add`. For building your own, see the official `mcp-server-dev` plugin (`/plugin install mcp-server-dev@claude-plugins-official`).

## Recommended

- `filesystem` — scoped filesystem access beyond the working directory
- `git` — read git history, blame, diffs without shelling out
- `github` — issues, PRs, reviews via the GitHub API (HTTP transport)
- `obsidian` (official CLI + `obsidian-vault-keeper` subagent) — vault I/O without always-on tool schemas
- `figma-context` — read Figma frames into context for UI work
- `slack` — read channels, post messages
- `linear` — issues and projects (official Linear MCP)
- `sentry` — production errors and stack traces (HTTP transport)
- `gmail` / `calendar` — Google productivity via official MCPs where available

Per-category details follow. Keep the set small: every installed MCP expands the tool-selection surface and the trust boundary.

## Coding

- **filesystem** — scoped filesystem access beyond the working directory. Install: `claude mcp add filesystem npx -- -y @modelcontextprotocol/server-filesystem <path>`
- **git** — read git history, blame, diffs without shelling out. Install: `claude mcp add git uvx -- mcp-server-git`
- **github** — issues, PRs, reviews via the GitHub API. Install: `claude mcp add --transport http github https://api.githubcopilot.com/mcp/ --header "Authorization: Bearer YOUR_GITHUB_PAT"`

## Knowledge base

- **obsidian (official CLI + subagent)** — use the official Obsidian CLI plus the `obsidian-vault-keeper` subagent pattern. The older third-party Obsidian MCP has known correctness issues; prefer this path. See `skills/knowledge-base-builder/SKILL.md`.

## Design

- **figma-context** — read Figma frames into context for UI work. Install: see https://github.com/GLips/Figma-Context-MCP

## Productivity

- **slack** — read channels, post messages. Install: `claude mcp add slack npx -- -y @modelcontextprotocol/server-slack`
- **linear** — issues and projects. Install via Linear's official MCP integration.
- **sentry** — production errors. Install: `claude mcp add --transport http sentry https://mcp.sentry.dev/mcp`
- **gmail / calendar** — via official Google MCP integrations where available; otherwise the community `gmail-mcp-server`.

## DevOps / cloud

- **kubernetes** — cluster read access, kubectl-equivalent queries. Community servers available; pin a version before production use.
- **aws / gcp** — prefer official CLIs wrapped via allowed Bash permissions; MCP wrappers exist but are less mature.

## Selection tips

- Add a `"description"` field to each entry in `.claude/settings.json` so Claude knows when to pick the server. (Convention, not part of the official schema — but this plugin promotes it.)
- Keep the installed set small. Every MCP server adds tool-selection overhead and expands the trust surface.
- For read-only inspection tasks, prefer a dedicated CLI + Bash allowlist over an MCP server.
- Set `"alwaysLoad": true` on a server entry in `.mcp.json` to load its tools upfront on every session (skips MCP Tool Search deferral). Use sparingly — each upfront tool consumes context.
- **MCP Tool Search** is enabled by default: tool schemas are deferred and discovered on demand, keeping context usage low when many servers are installed. Disable with `ENABLE_TOOL_SEARCH=false` if needed.
- **SSE transport is deprecated.** Prefer HTTP (`--transport http`) for new remote servers.
- MCP servers can push messages into your session via the **channels** capability; opt in with `--channels` at startup.
