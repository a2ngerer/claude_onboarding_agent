# Claude Onboarding Agent

> **Claude is powerful. But only if set up right.**

Most people start a new Claude session and just... start typing. No context, no workflow, no structure. The results are inconsistent, Claude forgets everything between sessions, and it never really learns how you work.

This plugin fixes that in minutes. Run `/onboarding` once — Claude scans your project, asks you a few targeted questions, and automatically generates everything: a tailored `CLAUDE.md`, subagent role definitions, tool permissions, workflow instructions, and more.

Already know what you need? Call any setup skill directly.

---

## What's Inside

| Command | Description |
|---------|-------------|
| `/onboarding` | Orchestrator — scans your repo, infers your use case, guides you to the right setup |
| `/coding-setup` | Installs [Superpowers](https://github.com/obra/superpowers), sets up iterative dev workflow: brainstorm → plan → subagents → review → commit |
| `/build-knowledge-base` | Builds a [Karpathy-pattern](https://github.com/forrestchang/andrej-karpathy-skills) wiki from your codebase or notes — with optional [Obsidian](https://obsidian.md) MCP integration |
| `/office-setup` | Configures writing style, document preferences, and company context |
| `/research-setup` | Sets up citation format, research domain, and academic writing guidelines |
| `/content-creator-setup` | Configures brand voice, platform preferences, and audience context |
| `/devops-setup` | Configures cloud provider, IaC tool, and CI/CD platform — generates safe infrastructure workflow guidelines and agent roles |
| `/design-setup` | Configures design tool, frontend stack, and accessibility standard — generates UI guidelines and avoids generic AI aesthetics |

---

## Installation

### Option 1: Plugin Marketplace (recommended)

```
/plugin install claude-onboarding-agent
```

> **Note:** Marketplace listing is in progress. Use Option 2 in the meantime.

### Option 2: One-liner (current recommended method)

```bash
curl -fsSL https://raw.githubusercontent.com/a2ngerer/claude_onboarding_agent/main/scripts/install.sh | bash
```

This clones the repository and symlinks all skills into `~/.claude/skills/` so Claude Code picks them up automatically. Future updates: re-run the same command.

> **How it works technically, and what the future plugin system will look like:** [docs/installation.md](docs/installation.md)

### Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/a2ngerer/claude_onboarding_agent/main/scripts/uninstall.sh | bash
```

---

## How It Works

```
/onboarding
     │
     ▼
Scan repo — detect files, manifests, existing CLAUDE.md
     │
     ▼
Suggest most likely use case (or ask if repo is empty)
     │
     ├── 1. Coding Setup
     ├── 2. Knowledge Base Builder
     ├── 3. Office & Business
     ├── 4. Research & Writing
     ├── 5. Content Creation
     ├── 6. DevOps & Infrastructure
     └── 7. Design & Frontend
               │
               ▼
     Ask 3–7 targeted questions
               │
               ▼
     Install Superpowers (always for Coding/KB, optional for others)
               │
               ▼
     Generate CLAUDE.md + config files automatically
               │
               ▼
     Print completion summary
```

**Know what you want?** Skip the orchestrator:

```
/coding-setup
/build-knowledge-base
/office-setup
/research-setup
/content-creator-setup
/devops-setup
/design-setup
```

---

## What Gets Generated

Every setup skill creates a tailored `CLAUDE.md` with context and instructions specific to your workflow. Here's what each path produces:

| Skill | CLAUDE.md | AGENTS.md | settings.json | .gitignore | External |
|-------|-----------|-----------|---------------|------------|----------|
| Coding | ✓ + workflow | ✓ 3 roles | ✓ stack permissions | ✓ stack | Superpowers |
| Knowledge Base | ✓ + Karpathy pattern | — | ✓ Obsidian MCP (optional) | ✓ | Superpowers + Karpathy |
| Office | ✓ + writing style | — | — | ✓ | Superpowers (optional) |
| Research | ✓ + citation format | — | — | ✓ LaTeX | Superpowers (optional) |
| Content | ✓ + brand voice | — | — | ✓ media files | Superpowers (optional) |
| DevOps | ✓ + infra workflow | ✓ 3 roles | ✓ stack permissions | ✓ IaC state, secrets | Superpowers (optional) |
| Design | ✓ + UI guidelines | ✓ 2 roles | ✓ stack permissions | ✓ design assets | Superpowers (optional) |

### The Coding Workflow (powered by Superpowers)

The Coding Setup installs [Superpowers](https://github.com/obra/superpowers) — a battle-tested Claude Code workflow library with 94,000+ users — and wires it into your `CLAUDE.md`. Every future session follows this proven loop:

```
Brainstorm idea → Write plan → Dispatch subagents → Code review → Commit
```

### The Knowledge Base (Karpathy Pattern)

The Knowledge Base Builder sets up the [Karpathy LLM Wiki pattern](https://github.com/forrestchang/andrej-karpathy-skills): a `raw/` folder for source material and a `wiki/` folder of interlinked markdown notes that Claude builds and maintains. Drop files into `raw/`, ask Claude to ingest them — the wiki grows automatically.

Optional: connect [Obsidian](https://obsidian.md) via MCP for direct vault integration and graph visualization.

---

## Language Support

All skills detect your language automatically from your first message and respond accordingly. Supported: English, German, Spanish, French, and any other language Claude Code supports.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add new setup skills.

---

## Authors

- Alexander Angerer — <alexander.angerer@outlook.de>
- Maximilian Achenbach — <Maximiliana28@gmail.com>

---

## License

[MIT](LICENSE) — free to use, modify, and distribute.
