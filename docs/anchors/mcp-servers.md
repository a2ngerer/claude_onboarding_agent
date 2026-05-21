---
name: mcp-servers
description: Recommended MCP servers by use case for Claude Code
last_updated: 2026-05-21
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

Browse reviewed connectors at the Anthropic Directory (`claude.ai/directory`) — any remote server listed there can be added with `claude mcp add`. Keep the set small: every installed MCP expands the tool-selection surface and the trust boundary.

## Coding

- **filesystem** — scoped filesystem access beyond the working directory. Install: `claude mcp add --transport stdio filesystem -- npx -y @modelcontextprotocol/server-filesystem <path>`
- **git** — read git history, blame, diffs without shelling out. Install: `claude mcp add --transport stdio git -- uvx mcp-server-git`
- **github** — issues, PRs, reviews via the GitHub API. Install: `claude mcp add --transport http github https://api.github.com/mcp` (needs `GITHUB_PERSONAL_ACCESS_TOKEN`)

## Knowledge base

- **obsidian (official CLI + subagent)** — use the official Obsidian CLI plus the `obsidian-vault-keeper` subagent pattern. The older third-party Obsidian MCP has known correctness issues; prefer this path. See `skills/knowledge-base-builder/SKILL.md`.

## Design

- **figma-context** — read Figma frames into context for UI work. Install: see https://github.com/GLips/Figma-Context-MCP

## Productivity

- **slack** — read channels, post messages. Install: `claude mcp add --transport stdio slack -- npx -y @modelcontextprotocol/server-slack`
- **linear** — issues and projects. Install via Linear's official MCP integration.
- **gmail / calendar** — via official Google MCP integrations where available; otherwise the community `gmail-mcp-server`.

## DevOps / cloud

- **kubernetes** — cluster read access, kubectl-equivalent queries. Community servers available; pin a version before production use.
- **aws / gcp** — prefer official CLIs wrapped via allowed Bash permissions; MCP wrappers exist but are less mature.

## Transport & scoping

HTTP is now the preferred transport. SSE transport is deprecated — migrate SSE-based servers to HTTP where available:

```bash
claude mcp add --transport http <name> <url>       # remote HTTP (recommended)
claude mcp add --transport stdio <name> -- <cmd>   # local stdio process
```

Scope flags: `--scope local` (default, current project, not checked into git), `--scope project` (shared via `.mcp.json`), `--scope user` (all your projects). Note: the old scope names `project` and `global` are now `local` and `user` respectively.

Stdio servers receive `CLAUDE_PROJECT_DIR` in their environment pointing to the project root — use it to resolve project-relative paths inside your server.

To scaffold a new MCP server: install the official plugin (`/plugin install mcp-server-dev@claude-plugins-official`) then run `/mcp-server-dev:build-mcp-server`.

## Selection tips

- Keep the installed set small. Every MCP server adds tool-selection overhead and expands the trust surface.
- For read-only inspection tasks, prefer a dedicated CLI + Bash allowlist over an MCP server.
- Plugin-provided MCP servers start automatically when the plugin is enabled — prefer this over user-level config for team-shared servers.
- Verify you trust each server before connecting — servers that fetch external content can expose you to prompt injection risk.
