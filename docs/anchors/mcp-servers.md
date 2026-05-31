---
name: mcp-servers
description: Recommended MCP servers by use case for Claude Code
last_updated: 2026-05-31
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

Browse reviewed connectors at the [Anthropic Directory](https://claude.ai/directory). Keep the set small: every installed MCP expands tool-selection overhead and the trust boundary.

## Coding

- **filesystem** — scoped filesystem access. Install: `claude mcp add -- filesystem -- npx -y @modelcontextprotocol/server-filesystem <path>`
- **git** — read git history, blame, diffs. Install: `claude mcp add git uvx -- mcp-server-git`
- **github** — issues, PRs, reviews. Install: `claude mcp add --transport http github https://api.githubcopilot.com/mcp/ --header "Authorization: Bearer <PAT>"`

## Knowledge base

- **obsidian (official CLI + subagent)** — use the official Obsidian CLI plus the `obsidian-vault-keeper` subagent pattern. The older third-party Obsidian MCP has known correctness issues; prefer this path. See `skills/knowledge-base-builder/SKILL.md`.

## Design

- **figma-context** — read Figma frames into context for UI work. See https://github.com/GLips/Figma-Context-MCP

## Productivity

- **slack** — read channels, post messages. Install: `claude mcp add slack npx -- -y @modelcontextprotocol/server-slack`
- **linear** — issues and projects. Install via Linear's official MCP integration.
- **gmail / calendar** — via official Google MCP integrations where available; otherwise the community `gmail-mcp-server`.

## DevOps / cloud

- **kubernetes** — cluster read access, kubectl-equivalent queries. Community servers available; pin a version before production use.
- **aws / gcp** — prefer official CLIs wrapped via allowed Bash permissions; MCP wrappers exist but are less mature.

## Selection tips

- **Transport**: prefer `--transport http` for remote servers. SSE (`--transport sse`) is deprecated — migrate to HTTP.
- **Tool Search**: MCP tools are deferred by default — only tool names load at session start, schemas load on demand. Set `"alwaysLoad": true` in a server's config entry to force upfront loading for tools Claude needs every turn.
- **Scopes**: `local` (default, private to you in this project, stored in `~/.claude.json`), `project` (shared via `.mcp.json` in version control), `user` (your personal cross-project servers, stored in `~/.claude.json`).
- Add a `"description"` field to each entry in `.mcp.json` so Claude knows when to pick the server.
- For read-only inspection tasks, prefer a dedicated CLI + Bash allowlist over an MCP server.
