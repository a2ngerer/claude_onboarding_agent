---
name: mcp-servers
description: Recommended MCP servers by use case for Claude Code
last_updated: 2026-05-24
sources:
  - https://docs.claude.com/en/docs/claude-code/mcp
  - https://github.com/modelcontextprotocol/servers
  - https://www.anthropic.com/engineering
version: 3
---

## Recommended

- `filesystem` — scoped filesystem access beyond the working directory
- `git` — read git history, blame, diffs without shelling out
- `github` — issues, PRs, reviews via the GitHub API (HTTP transport)
- `obsidian` (official CLI + `obsidian-vault-keeper` subagent) — vault I/O without always-on tool schemas
- `figma-context` — read Figma frames into context for UI work
- `slack` — read channels, post messages
- `linear` — issues and projects (official Linear MCP)
- `sentry` — error monitoring and stack traces
- `gmail` / `calendar` — Google productivity via official MCPs where available

Browse reviewed connectors at the [Anthropic Directory](https://claude.ai/directory). Keep the set small: every installed MCP expands the tool-selection surface and the trust boundary.

## Coding

- **filesystem** — `claude mcp add filesystem npx -- -y @modelcontextprotocol/server-filesystem <path>`
- **git** — `claude mcp add git uvx -- mcp-server-git`
- **github** — `claude mcp add --transport http github https://api.githubcopilot.com/mcp/ --header "Authorization: Bearer <PAT>"`

## Knowledge base

- **obsidian (official CLI + subagent)** — use the official Obsidian CLI plus the `obsidian-vault-keeper` subagent pattern. The older third-party Obsidian MCP has known correctness issues; prefer this path. See `skills/knowledge-base-builder/SKILL.md`.

## Design

- **figma-context** — see https://github.com/GLips/Figma-Context-MCP

## Productivity

- **slack** — `claude mcp add slack npx -- -y @modelcontextprotocol/server-slack`
- **linear** — via Linear's official MCP integration.
- **sentry** — `claude mcp add --transport http sentry https://mcp.sentry.dev/mcp`
- **gmail / calendar** — via official Google MCP integrations where available; otherwise the community `gmail-mcp-server`.

## DevOps / cloud

- **kubernetes** — cluster read access, kubectl-equivalent queries. Community servers available; pin a version before production use.
- **aws / gcp** — prefer official CLIs wrapped via allowed Bash permissions; MCP wrappers exist but are less mature.

## Selection tips

- **Prefer HTTP transport** for remote servers — the SSE transport is deprecated.
- MCP tools are **deferred by default** (tool search enabled); only tools Claude actually uses enter context.
- Set `"alwaysLoad": true` in a server's `.mcp.json` entry to skip deferral and load all its tools at session start. Use sparingly — upfront tools consume context.
- For read-only inspection tasks, prefer a dedicated CLI + Bash allowlist over an MCP server.
- Use `/mcp` to authenticate remote servers that require OAuth; tokens persist across reconnects.
