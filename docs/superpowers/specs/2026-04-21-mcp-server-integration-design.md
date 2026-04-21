# MCP Server Integration — Design

**Date:** 2026-04-21
**Status:** Draft
**Scope:** Introduce a conservative, opt-in MCP (Model Context Protocol) recommendation layer to selected setup skills. All MCP servers are registered at the user's Claude Code install via `claude mcp add` at the user's discretion. The plugin does NOT bundle MCP servers via `plugin.json` and does NOT ship OAuth credentials. Affects `coding-setup`, `web-development-setup`, `design-setup`, `office-setup`. Leaves `knowledge-base-builder` on its existing CLI + subagent pattern.

## Motivation

Three of the plugin's setup skills operate on domains where a well-chosen MCP server provides a meaningful capability upgrade over Bash + CLI: Figma frames for UI work, GitHub issues/PRs for code work, and Gmail/Calendar/Drive for office work. Today those skills either point users at generic CLI allowlists (coding-setup, web-development-setup) or generate style rules without any tool wiring (office-setup, design-setup). A structured recommendation layer raises the setup output from "you could add an MCP server" to "here is the command to add the MCP server that fits your declared use case, with the opt-in prompt and auth-flow instructions the user actually needs".

The anchor doc at `docs/anchors/mcp-servers.md` already catalogs recommended MCP servers per use case — but no skill currently reads it, so its recommendations never reach user-generated CLAUDE.md output. This initiative closes that loop.

A secondary goal: document clearly why some plausible MCPs (Obsidian, filesystem, git) are deliberately NOT recommended, so future skill authors do not re-open decisions already made.

## Decision

### Catalog (conservative)

Only MCPs with a concrete, already-discussed use case in an existing skill are in scope for v1.

| MCP | Target Skill | Capability | Auth Model | Inclusion | Registration |
|---|---|---|---|---|---|
| `figma-context` | design-setup | Read Figma frames into context for UI-to-code work | Figma API token (user env var) | Offered (opt-in) when user picks Figma in Q1 | Runtime `claude mcp add` |
| `github` | coding-setup, web-development-setup | Issues, PRs, reviews via GitHub API | `GITHUB_PERSONAL_ACCESS_TOKEN` (user env var) | Offered (opt-in) when user's project is git-backed with a GitHub remote | Runtime `claude mcp add` |
| `gmail` | office-setup | Read/search/send email | OAuth (user-side) | Offered (opt-in) when Q1 selects "Emails and messages" or "All of the above" | Runtime `claude mcp add` |
| `google-calendar` | office-setup | Read/create calendar events | OAuth (user-side) | Offered (opt-in) alongside Gmail when applicable | Runtime `claude mcp add` |
| `google-drive` | office-setup | Read/search Drive documents | OAuth (user-side) | Offered (opt-in) when Q1 selects "Reports and proposals" or "All of the above" | Runtime `claude mcp add` |

**Explicitly rejected for v1:**

- **Obsidian MCP** — the existing `knowledge-base-builder` CLI + subagent approach is the verified better path (see anchor doc: "third-party Obsidian MCP has known correctness issues"). Switching would regress a working pattern.
- **filesystem MCP** — Claude Code's built-in Read/Glob/Edit already cover in-repo file access. The MCP adds value only for paths outside the working directory, which is a YAGNI edge case for our setup scopes.
- **git MCP** — Bash + `git` + `gh` covers the same surface with no extra dependency. Adding a server for read-only inspection violates the anchor's own "prefer CLI + Bash allowlist over MCP server" guidance.
- **Slack, Linear, Kubernetes, AWS/GCP** — no existing skill has a declared use case for them. Adding them pre-emptively is speculative scope.

### Plugin-manifest vs runtime registration

All five catalog MCPs are registered at **runtime via `claude mcp add`**, triggered by the skill during the setup flow when the user opts in. The plugin's `.claude-plugin/plugin.json` is NOT extended with an `mcpServers` field.

**Rationale:**

1. **Plugin-manifest MCPs auto-start for every user of the plugin.** Per Claude Code plugin docs: "Plugin MCP servers start automatically when the plugin is enabled." That violates opt-in semantics for MCPs that need OAuth (Gmail/Calendar/Drive) or API tokens (Figma, GitHub). A user running `/coding-setup` should not incur an unsolicited GitHub OAuth prompt at plugin enable time.
2. **Plugin-manifest MCPs would force the plugin to ship connection details.** OAuth client IDs, server paths, and token storage conventions vary per provider and per install. Runtime registration pushes those details to the user's own `~/.claude/settings.json`, where Claude Code's own credential handling owns them.
3. **Scope correctness.** `claude mcp add --scope user|project|local` lets the user choose visibility. Plugin-bundled servers force global scope.
4. **Reversibility.** `claude mcp remove` cleanly undoes a runtime registration; disabling the plugin would otherwise need to tear down plugin-bundled servers.

Plugin-manifest MCP bundling remains a viable option for a future "MCP that ships bundled config files inside the plugin" use case, but no such use case exists in the current skill set.

### Opt-in UX pattern (one pattern per skill)

Each affected skill adds exactly one MCP-offer step to its existing context-question flow. The offer:

1. Triggers only when a prior answer makes the MCP relevant (declared per-MCP in the catalog table above). No unconditional offers.
2. Explains the capability in one or two sentences, using the detected user language.
3. Shows the exact `claude mcp add ...` command.
4. Asks a yes/no/later question. "later" means: skip registration now, but still emit a short pointer in CLAUDE.md so the user can revisit.
5. On "yes": run the `claude mcp add` command via Bash. If registration succeeds, record `<mcp-slug>_installed: true` in skill state.
6. On failure (non-zero exit, missing prerequisite, user declines mid-OAuth): warn once, fall through, record `<mcp-slug>_installed: false`.
7. Never block the rest of the skill on MCP success — the setup flow continues either way.

### Auth-flow handling

**API-token MCPs (GitHub, Figma):** The skill prints the environment variable name the MCP expects (`GITHUB_PERSONAL_ACCESS_TOKEN`, `FIGMA_API_TOKEN`) and the link to generate the token. The user sets the env var in their own shell profile; the skill does not write tokens to any plugin-owned file.

**OAuth MCPs (Gmail, Calendar, Drive):** The skill runs `claude mcp add` and tells the user: "Claude Code will open a browser window for the Google OAuth consent screen on first use of a Gmail/Calendar/Drive tool. Complete the consent flow there; the token is stored in Claude Code's credential store." The skill does NOT attempt to intercept or mediate the OAuth callback — that is Claude Code's responsibility, not the plugin's.

**If an MCP's registration fails because a prerequisite is missing** (e.g. `npx` not installed, `uvx` not installed for the git MCP variants, a token env var unset), the skill surfaces the exact error from `claude mcp add` to the user and proceeds to the next step. No auto-recovery.

### Generated CLAUDE.md content

Each skill that registers an MCP appends a short section to its generated CLAUDE.md block:

```
## Configured MCP servers
- <mcp-slug>: <one-line capability>. Auth: <token or OAuth note>. See <link-to-mcp-project>.
```

This is two or three lines per MCP, not a full CLI reference. No extraction to `.claude/rules/` is required (under the 25-line threshold from the rules-convention spec).

### Cross-skill consistency helper

A new shared helper `skills/_shared/offer-mcp.md` documents the uniform offer-prompt-execute-record pattern, so `coding-setup`, `web-development-setup`, `design-setup`, and `office-setup` reference it instead of duplicating text. The helper is a procedural template; each skill passes in its own MCP slug, trigger condition, capability description, install command, auth type, and optional pointer link.

## Affected Skills

| Skill | Change | Affected MCPs |
|---|---|---|
| `coding-setup` | Add MCP-offer step conditional on git-backed repo | `github` |
| `web-development-setup` | Add MCP-offer step conditional on git-backed repo | `github` |
| `design-setup` | Add MCP-offer step conditional on Q1 = Figma | `figma-context` |
| `office-setup` | Add MCP-offer step conditional on Q1 selections | `gmail`, `google-calendar`, `google-drive` |

**Unchanged skills (deliberate):**

- `knowledge-base-builder` — stays on Obsidian CLI + `obsidian-vault-keeper` subagent. See Out of Scope.
- `data-science-setup`, `academic-writing-setup`, `research-setup`, `content-creator-setup`, `devops-setup`, `graphify-setup`, `tipps`, `onboarding`, `upgrade`, `checkup` — no declared use case warrants an MCP in v1.

## Migration Path

No migration is needed. All changes are additive: existing users whose generated CLAUDE.md predates this spec keep their current setup. If they re-run a setup skill or invoke `/checkup --rebuild`, the MCP-offer step executes freshly and the new CLAUDE.md section is appended inside the plugin's existing delimited block (the existing `<!-- onboarding-agent:start ... -->` marker pattern already handles re-run content replacement).

`checkup` MAY surface a tip if the user's project declares a matching use case in `onboarding-meta.json` (e.g. setup_slug: office) but has no corresponding MCP registered in `.claude/settings.json` — but this is informational only, not an automatic remediation. That tip lives in the checkup skill's existing "Pass 4 — MCP & Skills" section as a new Check 4.3 "Use-case suggests MCP that is not registered" (LOW severity). Detailed wording lives in the plan, not here.

## Out of Scope

- **Building new MCP servers.** This initiative uses existing published servers only.
- **Shipping MCPs via the plugin manifest.** Explicitly rejected above.
- **Obsidian MCP adoption in `knowledge-base-builder`.** The current CLI + subagent path is better on both correctness and token cost. Revisit only if the anchor doc upgrades the Obsidian MCP's status.
- **Filesystem, git, Slack, Linear, Kubernetes, AWS/GCP MCPs.** No current use case. Future skills that introduce those use cases would extend this spec; no pre-emptive wiring.
- **Token/OAuth storage inside the plugin.** Credentials live in the user's shell env or Claude Code's credential store. The plugin never reads or writes auth material.
- **Auto-remediation in `checkup`.** Checkup only surfaces a LOW-severity tip when a registered MCP is missing for the declared use case; it never adds one without the user running the relevant setup skill.
- **OAuth flow implementation.** The plugin assumes Claude Code handles the OAuth dance for MCP servers that declare OAuth in their manifest. No fallback if Claude Code's OAuth support is broken — that is an upstream concern.
- **Testing MCP server tools end-to-end.** The success criteria verify registration success, not that the MCP's own tools work. Tool-level verification is the MCP author's responsibility.

## Risks & Edge Cases

- **Auth failure mid-OAuth.** User starts OAuth, cancels in the browser. The `claude mcp add` process may report success (server registered) but the first tool call will fail. Mitigation: the skill's completion summary tells the user "First use of a <MCP> tool will prompt the OAuth flow; if that fails, run `claude mcp remove <slug>` and re-run the setup."
- **Token env var unset at registration time.** GitHub MCP registration succeeds without the token but fails on first tool call. Mitigation: the skill prints the env var name and a check command (`echo $GITHUB_PERSONAL_ACCESS_TOKEN`) before offering registration; the user can bail out.
- **MCP server crashes.** An MCP server dying mid-session makes its tools unavailable until the user restarts. This is an upstream concern; the plugin documents it in the generated CLAUDE.md pointer ("If <mcp-slug> tools become unavailable, restart Claude Code").
- **Privacy for Google MCPs.** Gmail, Calendar, and Drive MCPs read user data. Mitigation: the office-setup offer prompt states this explicitly: "Granting access lets Claude read your <Gmail inbox|Calendar events|Drive documents>; the OAuth scope is controlled by the MCP server — review the consent screen before approving."
- **MCP ecosystem churn.** Today's recommended servers (e.g. `figma-context`, `gmail-mcp-server`) may be deprecated, renamed, or replaced. The anchor doc (`docs/anchors/mcp-servers.md`) is the single source of truth for current recommendations; skills reference slugs from the anchor, not hardcoded URLs. When the anchor changes, skills re-read it on next generation.
- **Non-git project runs `coding-setup`.** The GitHub MCP offer is gated on git-remote detection. If detection is false, the offer is silently skipped and no MCP section appears in CLAUDE.md.
- **User already has the MCP registered.** `claude mcp add` with an existing name fails or warns. The skill detects this via pre-check (`claude mcp list` or equivalent) and logs `Skipped <slug> (already registered)` rather than failing the whole setup.
- **User runs a setup skill twice.** The MCP offer re-appears. That is intentional — re-running setup is the documented path to re-evaluate the offer. The skill's idempotence is the user's choice, consistent with how the rules-convention spec handles re-runs.
- **Corporate environments with restricted network.** `npx`-based MCPs fetch npm packages at start; offline-restricted users cannot use them. Mitigation: the skill's offer prompt notes "requires network access to fetch the MCP server package"; users on locked-down networks decline.
- **Cross-initiative overlap with issue #4 (modularization) and #2 (end-user subagents).** If `knowledge-base-builder` or `office-setup` gain dispatched subagents in a future initiative, those subagents may want the MCPs this spec registers. The registration is user-scoped and visible to any subagent dispatched in the same project, so no re-registration is needed — but the subagent-owning spec should reference this spec to confirm tool availability.

## Success Criteria

- **Grep-testable:** `.claude-plugin/plugin.json` contains NO `mcpServers` key (negative test — the decision is to use runtime registration).
- **Grep-testable:** `skills/coding-setup/SKILL.md` and `skills/web-development-setup/SKILL.md` each contain exactly one reference to `_shared/offer-mcp.md` and exactly one `github` MCP slug.
- **Grep-testable:** `skills/design-setup/SKILL.md` contains one reference to `_shared/offer-mcp.md` and one `figma-context` MCP slug.
- **Grep-testable:** `skills/office-setup/SKILL.md` contains one reference to `_shared/offer-mcp.md` and the three slugs `gmail`, `google-calendar`, `google-drive`.
- **Grep-testable:** `skills/_shared/offer-mcp.md` exists and documents the offer/prompt/execute/record pattern (contains the strings "claude mcp add", "yes / no / later", "auth", "GITHUB_PERSONAL_ACCESS_TOKEN" or an example env-var placeholder).
- **Grep-testable:** `docs/anchors/mcp-servers.md` remains the single source for MCP slugs referenced by skills; no skill hardcodes an install command that conflicts with the anchor.
- **Grep-testable:** `skills/knowledge-base-builder/SKILL.md` still contains the existing Obsidian CLI + subagent flow and does NOT reference `_shared/offer-mcp.md` (unchanged-skill verification).
- **Checkup check 4.3 exists:** `skills/checkup/SKILL.md` contains a "Check 4.3" entry referencing "use case suggests MCP".
- **Manual E2E:** In a test project with a GitHub remote, running `/coding-setup` offers the GitHub MCP; accepting with a valid `GITHUB_PERSONAL_ACCESS_TOKEN` set runs `claude mcp add` and the resulting CLAUDE.md contains the `## Configured MCP servers` section with a `github:` line.
- **Manual E2E:** Running `/office-setup` and picking "Emails and messages" in Q1 offers Gmail and Calendar; declining both leaves CLAUDE.md without a Configured MCP servers section.
- **Manual E2E:** Running `/coding-setup` in a project without a git remote does NOT offer the GitHub MCP (conditional trigger verification).
