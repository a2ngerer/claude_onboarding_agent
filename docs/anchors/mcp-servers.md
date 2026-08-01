---
name: mcp-servers
description: Recommended MCP servers by use case for Claude Code
last_updated: 2026-08-01
sources:
  - https://docs.claude.com/en/docs/claude-code/mcp
  - https://github.com/modelcontextprotocol/servers
  - https://www.anthropic.com/engineering
version: 4
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

Per-category details follow. Keep the set small: every installed MCP expands the tool-selection surface and the trust boundary — though MCP tool search (default on) now loads tool schemas on demand instead of upfront, so a larger server set costs less context than it used to.

## Coding

- **filesystem** — scoped filesystem access beyond the working directory. Install: `claude mcp add --transport stdio filesystem -- npx -y @modelcontextprotocol/server-filesystem <path>`
- **git** — read git history, blame, diffs without shelling out. Install: `claude mcp add --transport stdio git -- uvx mcp-server-git`
- **github** — issues, PRs, reviews via the official GitHub MCP server. `@modelcontextprotocol/server-github` is archived (moved to `modelcontextprotocol/servers-archived`); use the official remote server instead.
  - Remote (recommended): `claude mcp add --transport http github https://api.githubcopilot.com/mcp/ --header "Authorization: Bearer YOUR_GITHUB_PAT"`
  - Local via Docker: `claude mcp add github -e GITHUB_PERSONAL_ACCESS_TOKEN=YOUR_PAT -- docker run -i --rm -e GITHUB_PERSONAL_ACCESS_TOKEN ghcr.io/github/github-mcp-server`

## Knowledge base

- **obsidian (official CLI + subagent)** — use the official Obsidian CLI plus the `obsidian-vault-keeper` subagent pattern. The older third-party Obsidian MCP has known correctness issues; prefer this path. See `skills/knowledge-base-setup/SKILL.md`.

## Design

- **figma-context** — read Figma frames into context for UI work. Uses the `figma-developer-mcp` npm package (GLips/Figma-Context-MCP).
  Install: `claude mcp add -s user --transport stdio figma-mcp -- npx -y figma-developer-mcp --figma-api-key=YOUR_FIGMA_API_KEY --stdio`
  Alternatively set `FIGMA_API_KEY` in the environment and omit the flag. API key from: https://www.figma.com/developers/api#access-tokens

## Productivity

- **slack** — read channels, post messages. Install: `claude mcp add --transport stdio slack -- npx -y @modelcontextprotocol/server-slack`
- **linear** — issues and projects. Install via Linear's official MCP integration.
- **gmail / calendar / drive** — Google hosts official remote MCP endpoints for these services. Authentication requires OAuth2 via a Google Cloud project and is configured through the Claude.ai/Claude Desktop GUI (Settings > Connectors), not via a single CLI command. For Claude Code headless use, the Google Workspace CLI is the practical alternative:
  ```
  npm install -g @googleworkspace/cli
  gws auth setup
  claude mcp add gws -- gws mcp -s drive,gmail,calendar
  ```
  The remote endpoints (`gmailmcp.googleapis.com`, `calendarmcp.googleapis.com`, `drivemcp.googleapis.com`) require a paid Claude plan and OAuth2 bearer tokens that cannot be injected as a static header — use the GUI connector flow for those.

## DevOps / cloud

- **kubernetes** — cluster read access, kubectl-equivalent queries. Community servers available; pin a version before production use.
- **aws / gcp** — prefer official CLIs wrapped via allowed Bash permissions; MCP wrappers exist but are less mature.

## Transport note

- **Prefer HTTP for remote servers, stdio for local servers.** SSE (Server-Sent Events) transport is deprecated — use HTTP where available. WebSocket (`--transport` accepts `ws` only via `add-json`, not `claude mcp add`) suits servers that push unprompted events.
- Use `claude mcp add-json` for HTTP/WebSocket servers with complex headers or OAuth config; use `claude mcp add --transport <type>` for the common cases.
- Scopes: `local` (default, private to you and this project), `project` (shared via `.mcp.json`, requires approval on first use), `user` (private, all your projects).

## Selection tips

- Add a `"description"` field to each entry in `.claude/settings.json` so Claude knows when to pick the server. (Convention, not part of the official schema — but this plugin promotes it.)
- Keep the installed set small. Every MCP server still expands the trust surface even though tool search reduces the context cost.
- For read-only inspection tasks, prefer a dedicated CLI + Bash allowlist over an MCP server.
- Prefer official/first-party remote servers (OAuth) over long-lived static tokens where available — Claude Code refreshes OAuth tokens automatically and flags re-auth needs in `/mcp`.
