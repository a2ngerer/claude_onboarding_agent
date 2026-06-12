---
name: mcp-servers
description: Recommended MCP servers by use case for Claude Code
last_updated: 2026-06-12
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

Browse reviewed connectors in the Anthropic Directory (`claude.ai/directory`); any remote server there can be added with `claude mcp add`. Per-category details follow. Keep the set small: every installed MCP expands the tool-selection surface and the trust boundary.

## Transport types

- **HTTP** (`--transport http`) — recommended for all remote servers; supports OAuth. The MCP spec calls this `streamable-http`; both names work in `.mcp.json`.
- **stdio** — local process; ideal for tools that need direct system access. Claude Code injects `CLAUDE_PROJECT_DIR` into the spawned server's environment for project-relative path resolution.
- **WebSocket** (`"type": "ws"`) — persistent bidirectional connection for servers that push events unprompted. Configure via `.mcp.json` or `claude mcp add-json`.
- **SSE** — deprecated. Migrate existing SSE servers to HTTP.

## Coding

- **filesystem** — scoped filesystem access beyond the working directory. Install: `claude mcp add filesystem npx -- -y @modelcontextprotocol/server-filesystem <path>`
- **git** — read git history, blame, diffs without shelling out. Install: `claude mcp add git uvx -- mcp-server-git`
- **github** — issues, PRs, reviews via the GitHub API. Install: `claude mcp add github npx -- -y @modelcontextprotocol/server-github` (needs `GITHUB_PERSONAL_ACCESS_TOKEN`)

## Knowledge base

- **obsidian (official CLI + subagent)** — use the official Obsidian CLI plus the `obsidian-vault-keeper` subagent pattern. The older third-party Obsidian MCP has known correctness issues; prefer this path. See `skills/knowledge-base-builder/SKILL.md`.

## Design

- **figma-context** — read Figma frames into context for UI work. Install: see https://github.com/GLips/Figma-Context-MCP

## Productivity

- **slack** — read channels, post messages. Install: `claude mcp add slack npx -- -y @modelcontextprotocol/server-slack`
- **linear** — issues and projects. Install via Linear's official MCP integration.
- **gmail / calendar** — via official Google MCP integrations where available.

## DevOps / cloud

- **kubernetes** — cluster read access, kubectl-equivalent queries. Community servers available; pin a version before production use.
- **aws / gcp** — prefer official CLIs wrapped via allowed Bash permissions; MCP wrappers exist but are less mature.

## Selection tips

- Use `--scope project` to share a server with your team via `.mcp.json`; `--scope user` (formerly `global`) for personal use across all projects; `--scope local` (formerly `project`) for personal use in one project only.
- Add a `"description"` field in `.claude/settings.json` so Claude knows when to pick the server.
- Stdio servers: `CLAUDE_PROJECT_DIR` is injected automatically — use it inside the server for project-relative paths.
- Channels: an MCP server can declare the `claude/channel` capability to push events (CI results, alerts, webhooks) directly into your session. Enable with `--channels` at startup.
- Add a per-server `"timeout"` field in `.mcp.json` (milliseconds) to cap individual tool-call duration.
- Keep the installed set small. Every MCP server adds tool-selection overhead and expands the trust surface.
- For read-only inspection tasks, prefer a dedicated CLI + Bash allowlist over an MCP server.
