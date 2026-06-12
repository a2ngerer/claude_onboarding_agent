# How Installation Works

## Current Method: curl + symlinks (macOS / Linux) or irm + junctions (Windows)

The one-liner fetches `install.sh` (macOS / Linux) or `install.ps1` (Windows) and runs it locally:

```
~/.claude/
├── plugins/
│   └── claude-onboarding-agent/   ← full repo cloned here
│       ├── skills/
│       │   ├── onboarding/SKILL.md
│       │   ├── coding-setup/SKILL.md
│       │   └── ...
│       └── .claude-plugin/plugin.json
└── skills/
    ├── onboarding → ../plugins/claude-onboarding-agent/skills/onboarding/   (symlink)
    ├── coding-setup → ...
    └── ...
```

**How Claude Code discovers skills:** it scans `~/.claude/skills/` at session start and loads any `SKILL.md` it finds there. Each skill becomes a `/slash-command` available in every project. The links mean updates (`git pull` in the plugin dir) are picked up immediately without re-running any install step.

**Why junctions on Windows:** the PowerShell script uses directory junctions instead of symbolic links. Junctions work without admin rights and without Developer Mode, while `SymbolicLink` requires one of the two. For Claude Code's read-only skill discovery, the two are equivalent.

The `plugin.json` manifest at `.claude-plugin/plugin.json` declares which skill folders and which slash-command names belong to the plugin. The accompanying `marketplace.json` at `.claude-plugin/marketplace.json` enables the self-hosted plugin marketplace flow (see Option 2 below).

**Update:** re-run the same curl command. The script detects an existing clone and does `git pull` instead of re-cloning.

**Uninstall:** the uninstall script removes all symlinks in `~/.claude/skills/` that point into the plugin directory, then deletes the clone.

| Aspect | Notes |
|--------|-------|
| Transparency | Full — `install.sh` / `install.ps1` is readable, every step is visible |
| Security model | No sandboxing — the script runs with full shell permissions of the user |
| Update control | Explicit — `git pull` only when the user triggers it, no auto-update |
| Dependencies | `git` plus either `bash` (macOS / Linux) or PowerShell 5.1+ (Windows) |
| Recoverability | Simple and fully transparent — remove links, delete the directory |

---

## Option 2: Self-Hosted Plugin Marketplace

This repo ships a `.claude-plugin/marketplace.json` that makes it discoverable via the Claude Code plugin marketplace commands. Once the repo is registered as a marketplace source, installation is:

```
/plugin marketplace add a2ngerer/claude_onboarding_agent
/plugin install claude-onboarding-agent@claude-onboarding-agent
```

Under the hood, Claude Code:

1. Fetches the `marketplace.json` from the repo to discover available plugins
2. Reads the `plugin.json` manifest to find the `skills[]` directory declarations
3. Registers each skill; the slash-command name derives from the skill directory name
4. Makes all slash-commands available immediately

The `plugin.json` fields `skills[]`, `author`, `version`, and `homepage` are what the plugin system consumes. The `marketplace.json` adds the discovery layer (owner, plugin listing) that the `/plugin marketplace add` command expects.

| Aspect | Notes |
|--------|-------|
| Transparency | High — both manifest files are readable JSON in the repo |
| Security model | Depends on Claude Code's plugin verification — no separate shell script needed |
| Update control | Via Claude Code's own update mechanism |
| Dependencies | Only Claude Code itself |
| Recoverability | `/plugin uninstall` |
