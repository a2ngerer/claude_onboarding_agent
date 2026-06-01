---
name: mcp-servers
description: Recommended MCP servers by use case for Claude Code
last_updated: 2026-06-01
sources:
  - https://docs.claude.com/en/docs/claude-code/mcp
  - https://github.com/modelcontextprotocol/servers
  - https://www.anthropic.com/engineering
version: 3
---

## Finding servers

Browse reviewed connectors at `claude.ai/directory`. Any remote server listed there can be added with `claude mcp add --transport http <name> <url>`. To scaffold a custom server, use the `mcp-server-dev` plugin.

## Recommended

- `filesystem` — scoped filesystem access beyond the working directory
- `git` — read git history, blame, diffs without shelling out
- `github` — issues, PRs, reviews via the GitHub API
- `obsidian` (official CLI + `obsidian-vault-keeper` subagent) — vault I/O without always-on tool schemas
- `figma-context` — read Figma frames into context for UI work
- `slack` — read channels, post messages
- `linear` — issues and projects (official Linear MCP)
- `sentry` — error monitoring: recent errors, stack traces, deployment diffs
- `gmail` / `calendar` — Google productivity via official MCPs where available

Per-category details follow. Keep the set small: every installed MCP expands the tool-selection surface and the trust boundary.

## Coding

- **filesystem** — scoped filesystem access. Install: `claude mcp add filesystem npx -- -y @modelcontextprotocol/server-filesystem <path>`
- **git** — read git history, blame, diffs. Install: `claude mcp add git uvx -- mcp-server-git`
- **github** — issues, PRs, reviews. Install: `claude mcp add --transport http github https://api.githubcopilot.com/mcp/ --header "Authorization: Bearer YOUR_GITHUB_PAT"`

## Knowledge base

- **obsidian (official CLI + subagent)** — use the official Obsidian CLI plus the `obsidian-vault-keeper` subagent pattern. The older third-party Obsidian MCP has known correctness issues; prefer this path. See `skills/knowledge-base-builder/SKILL.md`.

## Design

- **figma-context** — read Figma frames into context for UI work. See https://github.com/GLips/Figma-Context-MCP

## Productivity

- **slack** — read channels, post messages. Install: `claude mcp add slack npx -- -y @modelcontextprotocol/server-slack`
- **linear** — issues and projects. Install via Linear's official MCP integration.
- **gmail / calendar** — via official Google MCP integrations where available; otherwise the community `gmail-mcp-server`.

## DevOps / cloud

- **sentry** — error monitoring. Install: `claude mcp add --transport http sentry https://mcp.sentry.dev/mcp` (OAuth via `/mcp`)
- **kubernetes** — cluster read access, kubectl-equivalent queries. Community servers available; pin a version before production use.
- **aws / gcp** — prefer official CLIs wrapped via allowed Bash permissions; MCP wrappers exist but are less mature.

## Selection tips

- **HTTP transport is preferred for remote servers.** SSE transport is deprecated; use `--transport http` for new installs. Stdio is for local processes only.
- By default, tools from all MCP servers are deferred and discovered on demand via tool search — adding more servers does not bloat the context window upfront.
- Set `alwaysLoad: true` in `.mcp.json` for servers whose tools Claude needs on every turn (skips deferral but costs context on every session).
- Add a `"description"` field to each entry in `.claude/settings.json` so Claude knows when to pick the server.
- For read-only inspection tasks, prefer a dedicated CLI + Bash allowlist over an MCP server.
- Scopes: `local` (this project, private — default), `project` (shared via `.mcp.json` in VCS), `user` (all your projects, private).
- Project-scoped servers from `.mcp.json` require explicit approval before first use; reset with `claude mcp reset-project-choices`.
