---
name: mcp-servers
description: Recommended MCP servers by use case for Claude Code
last_updated: 2026-06-04
sources:
  - https://docs.claude.com/en/docs/claude-code/mcp
  - https://github.com/modelcontextprotocol/servers
  - https://www.anthropic.com/engineering
version: 3
---

## Recommended

- `filesystem` — scoped filesystem access beyond the working directory
- `git` — read git history, blame, diffs without shelling out
- `github` — issues, PRs, reviews via the GitHub API
- `obsidian` (official CLI + `obsidian-vault-keeper` subagent) — vault I/O without always-on tool schemas
- `figma-context` — read Figma frames into context for UI work
- `slack` — read channels, post messages
- `linear` — issues and projects (official Linear MCP)
- `gmail` / `calendar` — Google productivity via official MCPs where available

Per-category details follow. Keep the set small: every installed MCP expands the tool-selection surface and the trust boundary.

Browse reviewed connectors in the Anthropic Directory at `https://claude.ai/directory`.

## Coding

- **filesystem** — scoped filesystem access beyond the working directory. Install: `claude mcp add filesystem npx -- -y @modelcontextprotocol/server-filesystem <path>`
- **git** — read git history, blame, diffs without shelling out. Install: `claude mcp add git uvx -- mcp-server-git`
- **github** — issues, PRs, reviews. Install: `claude mcp add --transport http github https://api.githubcopilot.com/mcp/ --header "Authorization: Bearer <PAT>"`

## Knowledge base

- **obsidian (official CLI + subagent)** — use the official Obsidian CLI plus the `obsidian-vault-keeper` subagent pattern. The older third-party Obsidian MCP has known correctness issues; prefer this path. See `skills/knowledge-base-builder/SKILL.md`.

## Design

- **figma-context** — read Figma frames into context for UI work. Install: see https://github.com/GLips/Figma-Context-MCP

## Productivity

- **slack** — read channels, post messages. Install: `claude mcp add slack npx -- -y @modelcontextprotocol/server-slack`
- **linear** — issues and projects. Install via Linear's official MCP integration.
- **gmail / calendar** — via official Google MCP integrations where available; otherwise the community `gmail-mcp-server`.

## DevOps / cloud

- **kubernetes** — cluster read access, kubectl-equivalent queries. Community servers available; pin a version before production use.
- **aws / gcp** — prefer official CLIs wrapped via allowed Bash permissions; MCP wrappers exist but are less mature.

## Transports

- **HTTP** (`--transport http`) is the recommended transport for remote servers. OAuth 2.0 authentication is supported.
- **stdio** — local process; ideal for tools needing direct system access.
- **WebSocket** (`ws://`) — persistent bidirectional connection; configure in `.mcp.json` with `"type": "ws"`.
- **SSE** — deprecated. Use HTTP instead where available.

## Installation scopes

| Scope | Stored in | Shared |
|---|---|---|
| `local` (default) | `~/.claude.json` | No — personal, current project only |
| `project` | `.mcp.json` in repo root | Yes — via version control |
| `user` | `~/.claude.json` | No — personal, all projects |

## Selection tips

- Tool search is on by default: MCP tool schemas are deferred and loaded on demand, keeping startup context lean. Set `alwaysLoad: true` in `.mcp.json` for servers whose tools are needed on every turn.
- Keep the installed set small. Every MCP server adds tool-selection overhead and expands the trust surface.
- For read-only inspection tasks, prefer a dedicated CLI + Bash allowlist over an MCP server.
- Add a `"description"` field to each entry in `.claude/settings.json` so Claude knows when to pick the server.
