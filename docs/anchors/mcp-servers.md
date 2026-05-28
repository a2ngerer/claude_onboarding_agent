---
name: mcp-servers
description: Recommended MCP servers by use case for Claude Code
last_updated: 2026-05-28
sources:
  - https://docs.claude.com/en/docs/claude-code/mcp
  - https://github.com/modelcontextprotocol/servers
  - https://www.anthropic.com/engineering
version: 3
---

## Recommended

Browse reviewed connectors at `claude.ai/directory` (the Anthropic Directory). Keep the installed set small: every MCP server adds tool-selection overhead and expands the trust boundary.

- `filesystem` — scoped filesystem access beyond the working directory
- `git` — read git history, blame, diffs without shelling out
- `github` — issues, PRs, reviews via GitHub's remote HTTP MCP
- `obsidian` (official CLI + `obsidian-vault-keeper` subagent) — vault I/O without always-on tool schemas
- `figma-context` — read Figma frames into context for UI work
- `slack` — read channels, post messages
- `linear` — issues and projects (official Linear MCP)
- `gmail` / `calendar` — Google productivity via official MCPs where available

Per-category install commands follow. Use `--transport http` for remote cloud services and `--transport stdio` for local process servers.

## Coding

- **filesystem** — scoped filesystem access.
  `claude mcp add --transport stdio filesystem -- npx -y @modelcontextprotocol/server-filesystem <path>`
- **git** — read git history without shelling out.
  `claude mcp add --transport stdio git -- uvx mcp-server-git`
- **github** — issues, PRs, reviews (HTTP remote; needs a GitHub PAT).
  `claude mcp add --transport http github https://api.githubcopilot.com/mcp/ --header "Authorization: Bearer <PAT>"`

## Knowledge base

- **obsidian (official CLI + subagent)** — use the official Obsidian CLI plus the `obsidian-vault-keeper` subagent pattern. The older third-party Obsidian MCP has known correctness issues; prefer this path. See `skills/knowledge-base-builder/SKILL.md`.

## Design

- **figma-context** — read Figma frames into context for UI work. See https://github.com/GLips/Figma-Context-MCP

## Productivity

- **slack** — `claude mcp add --transport stdio slack -- npx -y @modelcontextprotocol/server-slack`
- **linear** — install via Linear's official MCP integration (HTTP).
- **gmail / calendar** — via official Google MCP integrations where available; otherwise the community `gmail-mcp-server`.

## DevOps / cloud

- **kubernetes** — cluster read access. Community servers available; pin a version before production use.
- **aws / gcp** — prefer official CLIs wrapped via allowed Bash permissions; MCP wrappers exist but are less mature.

## Selection tips

- The SSE transport is deprecated; use `--transport http` for new remote servers.
- Use `--scope project` to commit a shared server to `.mcp.json`; `--scope user` for personal cross-project servers.
- Add a `"description"` field to each entry in `.claude/settings.json` so Claude knows when to pick the server.
- For read-only inspection tasks, prefer a dedicated CLI + Bash allowlist over an MCP server.
