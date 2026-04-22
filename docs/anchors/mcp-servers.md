---
name: mcp-servers
description: Recommended MCP servers by use case for Claude Code
last_updated: 2026-04-22
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

## Coding

- **filesystem** — scoped filesystem access beyond the working directory. Install: `claude mcp add filesystem npx -- -y @modelcontextprotocol/server-filesystem <path>`
- **git** — read git history, blame, diffs without shelling out. Install: `claude mcp add git uvx -- mcp-server-git`
- **github** — issues, PRs, reviews via the GitHub API. Install: `claude mcp add github npx -- -y @modelcontextprotocol/server-github` (needs `GITHUB_PERSONAL_ACCESS_TOKEN`). Note: the MCP reference implementation is now archived; the package still works but consider browsing community alternatives at the [MCP Registry](https://registry.modelcontextprotocol.io/).

## Knowledge base

- **obsidian (official CLI + subagent)** — use the official Obsidian CLI plus the `obsidian-vault-keeper` subagent pattern. The older third-party Obsidian MCP has known correctness issues; prefer this path. See `skills/knowledge-base-builder/SKILL.md`.

## Design

- **figma-context** — read Figma frames into context for UI work. Install: see https://github.com/GLips/Figma-Context-MCP

## Productivity

- **slack** — read channels, post messages. Note: the official reference server is archived and now community-maintained by Zencoder. Install: `claude mcp add slack npx -- -y @modelcontextprotocol/server-slack`
- **linear** — issues and projects. Install via Linear's official MCP integration.
- **gmail / calendar** — via official Google MCP integrations where available; otherwise the community `gmail-mcp-server`.

## DevOps / cloud

- **kubernetes** — cluster read access, kubectl-equivalent queries. Community servers available; pin a version before production use.
- **aws / gcp** — prefer official CLIs wrapped via allowed Bash permissions; MCP wrappers exist but are less mature.

## MCP features (recent)

- **Elicitation** — MCP servers can now request structured user input mid-task via an interactive dialog (Claude Code v2.1.76+). Use the `Elicitation` and `ElicitationResult` hooks to intercept or post-process these requests.
- **Large result persistence** — annotate a tool result with `_meta["anthropic/maxResultSizeChars"]` (up to 500K) to override the default size cap for large payloads.
- **MCP Registry** — browse and discover published commercial MCP servers at https://registry.modelcontextprotocol.io/.

## Selection tips

- Add a `"description"` field to each entry in `.claude/settings.json` so Claude knows when to pick the server. (Convention, not part of the official schema — but this plugin promotes it.)
- Keep the installed set small. Every MCP server adds tool-selection overhead and expands the trust surface.
- For read-only inspection tasks, prefer a dedicated CLI + Bash allowlist over an MCP server.
