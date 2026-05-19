---
name: mcp-servers
description: Recommended MCP servers by use case for Claude Code
last_updated: 2026-05-19
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

For discovery, browse the [Anthropic Directory](https://claude.ai/directory) — it lists reviewed connectors for Claude Code. Per-category details follow. Keep the set small: every installed MCP expands the tool-selection surface and the trust boundary.

## Active reference implementations

The `modelcontextprotocol/servers` repository currently maintains these official reference servers:

- **filesystem** — scoped file access. Install: `claude mcp add filesystem npx -- -y @modelcontextprotocol/server-filesystem <path>`
- **git** — git history, blame, diffs. Install: `claude mcp add git uvx -- mcp-server-git`
- **fetch** — web content retrieval optimized for LLM processing
- **memory** — knowledge-graph-based persistent memory across sessions
- **sequential-thinking** — dynamic problem-solving through thought sequences

Note: Several previously maintained reference implementations (GitHub, GitLab, Slack, Google Drive, PostgreSQL, Redis, SQLite, Brave Search) have been archived to a separate `servers-archived` repository. For these integrations use official vendor MCPs or entries in the Anthropic Directory.

## Coding

- **filesystem** — scoped filesystem access. Install: `claude mcp add filesystem npx -- -y @modelcontextprotocol/server-filesystem <path>`
- **git** — read git history, blame, diffs without shelling out. Install: `claude mcp add git uvx -- mcp-server-git`
- **github** — issues, PRs, reviews. Use an official vendor-provided MCP or the Anthropic Directory entry (reference implementation archived).

## Knowledge base

- **obsidian (official CLI + subagent)** — use the official Obsidian CLI plus the `obsidian-vault-keeper` subagent pattern. The older third-party Obsidian MCP has known correctness issues; prefer this path. See `skills/knowledge-base-builder/SKILL.md`.

## Design

- **figma-context** — read Figma frames into context for UI work. Install: see https://github.com/GLips/Figma-Context-MCP

## Productivity

- **slack** — read channels, post messages. Use a vendor-provided or Anthropic Directory entry (reference implementation archived).
- **linear** — issues and projects. Install via Linear's official MCP integration.
- **gmail / calendar** — via official Google MCP integrations where available; otherwise the community `gmail-mcp-server`.

## DevOps / cloud

- **kubernetes** — cluster read access, kubectl-equivalent queries. Community servers available; pin a version before production use.
- **aws / gcp** — prefer official CLIs wrapped via allowed Bash permissions; MCP wrappers exist but are less mature.

## Selection tips

- Add a `"description"` field to each entry in `.claude/settings.json` so Claude knows when to pick the server.
- Keep the installed set small. Every MCP server adds tool-selection overhead and expands the trust surface.
- The server name `workspace` is reserved (v2.1.128+); servers using that name are skipped with a warning.
- For read-only inspection tasks, prefer a dedicated CLI + Bash allowlist over an MCP server.
