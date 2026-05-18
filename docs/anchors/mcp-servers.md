---
name: mcp-servers
description: Recommended MCP servers by use case for Claude Code
last_updated: 2026-05-18
sources:
  - https://docs.claude.com/en/docs/claude-code/mcp
  - https://github.com/modelcontextprotocol/servers
  - https://www.anthropic.com/engineering
version: 3
---

## Overview

Browse reviewed connectors in the [Anthropic Directory](https://claude.ai/directory). Any server listed there can be added with `claude mcp add`. Keep the installed set small: every MCP server adds tool-selection overhead and expands the trust boundary.

## Recommended servers

- `filesystem` — scoped filesystem access beyond the working directory
- `git` — read git history, blame, diffs without shelling out
- `github` — issues, PRs, reviews via the GitHub API
- `obsidian` (official CLI + `obsidian-vault-keeper` subagent) — vault I/O without always-on tool schemas
- `figma-context` — read Figma frames into context for UI work
- `slack` — read channels, post messages
- `linear` — issues and projects (official Linear MCP)
- `gmail` / `calendar` — Google productivity via official MCPs where available

## Transports

**HTTP** (recommended) — `claude mcp add --transport http <name> <url>`. Use for remote cloud-based services. `streamable-http` is accepted as a JSON config alias per the MCP spec.

**SSE** — deprecated. Migrate to HTTP transport where available.

**stdio** — local process; ideal for tools needing direct system access. `claude mcp add [options] <name> -- <command> [args...]`

## Coding

- **filesystem** — `claude mcp add filesystem npx -- -y @modelcontextprotocol/server-filesystem <path>`
- **git** — `claude mcp add git uvx -- mcp-server-git`
- **github** — `claude mcp add github npx -- -y @modelcontextprotocol/server-github` (needs `GITHUB_PERSONAL_ACCESS_TOKEN`)

## Knowledge base

- **obsidian (official CLI + subagent)** — use the official Obsidian CLI plus the `obsidian-vault-keeper` subagent pattern. The older third-party Obsidian MCP has known correctness issues; prefer this path. See `skills/knowledge-base-builder/SKILL.md`.

## Design

- **figma-context** — read Figma frames into context for UI work. Install: see https://github.com/GLips/Figma-Context-MCP

## Productivity

- **slack** — `claude mcp add slack npx -- -y @modelcontextprotocol/server-slack`
- **linear** — via Linear's official MCP integration.
- **gmail / calendar** — via official Google MCP integrations where available; otherwise the community `gmail-mcp-server`.

## DevOps / cloud

- **kubernetes** — community servers available; pin a version before production use.
- **aws / gcp** — prefer official CLIs wrapped via allowed Bash permissions; MCP wrappers exist but are less mature.

## Selection tips

- Add a `"description"` field to each `.claude/settings.json` entry so Claude knows when to pick the server.
- Keep the installed set small. Every MCP server adds tool-selection overhead and expands the trust surface.
- For read-only inspection tasks, prefer a dedicated CLI + Bash allowlist over an MCP server.
- The server name `workspace` is reserved; Claude Code skips and warns if your config uses it.
- Scopes: `local` (default, your machine only), `project` (shared via `.mcp.json`), `user` (all your projects). Note: `local` was called `project` and `user` was called `global` in older versions.
- HTTP/SSE servers auto-reconnect up to 5× on disconnect with exponential backoff.
- **Channels**: an MCP server can push events into your session by declaring the `claude/channel` capability — useful for CI alerts, chat messages, or webhook triggers.
- **Plugin-provided servers**: plugins bundle `.mcp.json` at the plugin root; those servers start automatically when the plugin is enabled.
