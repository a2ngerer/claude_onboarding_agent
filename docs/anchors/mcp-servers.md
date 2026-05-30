---
name: mcp-servers
description: Recommended MCP servers by use case for Claude Code
last_updated: 2026-05-30
sources:
  - https://docs.claude.com/en/docs/claude-code/mcp
  - https://github.com/modelcontextprotocol/servers
  - https://www.anthropic.com/engineering
version: 3
---

## Discovery

Browse reviewed servers at the **Anthropic Directory** (`claude.ai/directory`). Any remote server listed there can be added with `claude mcp add`. If logged in with a Claude.ai account, connectors added in Claude.ai are auto-available in Claude Code — no separate install step.

## Recommended

- `filesystem` — scoped filesystem access beyond the working directory
- `git` — read git history, blame, diffs without shelling out
- `github` — issues, PRs, reviews via the GitHub API
- `sentry` — production error monitoring; official Anthropic Directory server
- `obsidian` (official CLI + `obsidian-vault-keeper` subagent) — vault I/O without always-on tool schemas
- `figma-context` — read Figma frames into context for UI work
- `slack` — read channels, post messages
- `linear` — issues and projects (official Linear MCP)

Keep the set small: every installed MCP expands the tool-selection surface and the trust boundary.

## Transport types

| Type | Status | Best for |
|------|--------|----------|
| `http` (`streamable-http`) | **Recommended** | Remote cloud services; supports OAuth 2.0 |
| `stdio` | Active | Local processes, system access |
| `ws` (WebSocket) | Active | Push events / bidirectional streams |
| `sse` | **Deprecated** | Legacy; migrate to `http` |

```bash
# Remote HTTP (recommended for cloud services)
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
# Local stdio
claude mcp add --transport stdio db -- npx -y @bytebase/dbhub --dsn "postgresql://..."
```

## Coding

- **filesystem** — `claude mcp add filesystem npx -- -y @modelcontextprotocol/server-filesystem <path>`
- **git** — `claude mcp add git uvx -- mcp-server-git`
- **github** — `claude mcp add --transport http github https://api.githubcopilot.com/mcp/` (pass `Authorization: Bearer <PAT>` header)

## Knowledge base

- **obsidian (official CLI + subagent)** — use the official Obsidian CLI plus the `obsidian-vault-keeper` subagent. See `skills/knowledge-base-builder/SKILL.md`.

## Design

- **figma-context** — read Figma frames into context. See https://github.com/GLips/Figma-Context-MCP

## Productivity

- **slack** — `claude mcp add slack npx -- -y @modelcontextprotocol/server-slack`
- **linear** — via Linear's official MCP integration
- **sentry** — `claude mcp add --transport http sentry https://mcp.sentry.dev/mcp` (then `/mcp` for OAuth)
- **gmail / calendar** — via official Google MCP integrations where available

## DevOps / cloud

- **kubernetes** — cluster read access; community servers available; pin a version before production use.
- **aws / gcp** — prefer official CLIs wrapped via allowed Bash permissions; MCP wrappers exist but are less mature.

## Selection tips

- Browse the Anthropic Directory first; prefer `http` transport for remote servers over `sse` (deprecated).
- By default, MCP tool schemas are **deferred** (tool search enabled) — loaded only when Claude needs them. Add `"alwaysLoad": true` to a server entry to force-load its tools at session start.
- Keep the installed set small. Every MCP server adds tool-selection overhead and expands the trust surface.
- For read-only inspection tasks, prefer a dedicated CLI + Bash allowlist over an MCP server.
- Scaffold a custom MCP server: install the `mcp-server-dev` plugin (`/plugin install mcp-server-dev@claude-plugins-official`), then run `/mcp-server-dev:build-mcp-server`.
