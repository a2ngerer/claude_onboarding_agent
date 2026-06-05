---
name: mcp-servers
description: Recommended MCP servers by use case for Claude Code
last_updated: 2026-06-05
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
- `obsidian` (official CLI + `obsidian-vault-keeper` subagent) — vault I/O; requires Obsidian 1.13+
- `figma-context` — read Figma frames into context for UI work
- `slack` — read channels, post messages
- `linear` — issues and projects (official Linear MCP)
- `gmail` / `calendar` — Google productivity via official MCPs where available

Keep the set small — every installed MCP expands the tool-selection surface and the trust boundary.

## Coding

- **filesystem** — `claude mcp add filesystem npx -- -y @modelcontextprotocol/server-filesystem <path>`
- **git** — `claude mcp add git uvx -- mcp-server-git`
- **github** — `claude mcp add github npx -- -y @modelcontextprotocol/server-github` (needs `GITHUB_PERSONAL_ACCESS_TOKEN`)

## Knowledge base

- **obsidian (CLI + subagent)** — official CLI plus `obsidian-vault-keeper`. Requires Obsidian 1.13+. The older third-party Obsidian MCP has correctness issues; prefer this path. See `skills/knowledge-base-builder/SKILL.md`.

## Design / Productivity / DevOps

- **figma-context** — Figma frames into context. See https://github.com/GLips/Figma-Context-MCP
- **slack** — `claude mcp add slack npx -- -y @modelcontextprotocol/server-slack`
- **linear** — via Linear's official MCP integration
- **kubernetes** — community servers; pin a version before production use
- **aws / gcp** — prefer official CLIs wrapped via Bash allowlists; MCP wrappers exist but are less mature

## Transports

| Transport | Flag | When to use |
|---|---|---|
| HTTP (streamable-http) | `--transport http` | Remote cloud services — recommended default |
| stdio | default | Local processes needing direct system access |
| WebSocket | JSON only (`"type":"ws"`) | Servers that push events unprompted |
| SSE | `--transport sse` | **Deprecated** — migrate to HTTP |

HTTP example: `claude mcp add --transport http notion https://mcp.notion.com/mcp`

Stdio servers receive `CLAUDE_PROJECT_DIR` in their environment. Stdio servers are not auto-reconnected; HTTP/SSE servers reconnect automatically with exponential backoff.

## Selection tips

- Add a `"description"` field to each entry in `.claude/settings.json` so Claude picks the right server.
- **`workspace`** is a reserved server name — Claude Code skips it at load time and warns you to rename it.
- For push-event workflows (CI alerts, chat bots), use a server declaring the `claude/channel` capability (see Channels docs). Enable with `--channels` at startup.
- MCP servers support dynamic tool updates via `list_changed` notifications; no reconnect needed when tools change.
- Browse reviewed connectors at `claude.ai/directory`. Scaffold a new server with the `mcp-server-dev` plugin (`/plugin install mcp-server-dev@claude-plugins-official`).
- Use `--scope project` to share a server via `.mcp.json` (checked into git), `--scope local` for your copy only, `--scope user` for all your projects.
- For read-only inspection, prefer a CLI + Bash allowlist over an MCP server.
