# Design Spec: New Setup Skills & Optional Skills Integration

**Date:** 2026-04-16
**Status:** Approved

## Problem

The onboarding agent currently covers 5 personas (coding, knowledge-base, office, research, content-creator). Two high-demand roles are missing: DevOps/Cloud Engineers and UI/UX Designers. Additionally, the existing setups do not surface popular community skills (e.g., `frontend-design` with 277k installs) — users must discover these independently.

## Goals

1. Add two new setup skills: `devops-setup` and `design-setup`
2. Add a configurable "Optional Skills" step to `coding-setup` and `research-setup`
3. Update `onboarding/SKILL.md` to route to the new setups
4. Update `.claude-plugin/plugin.json` with new entries

## Non-Goals

- No new setup for data science (deferred)
- No changes to `office-setup` or `content-creator-setup` (no suitable external skills identified)
- No central extras orchestrator (Approach B/C rejected in favor of per-skill curation)

---

## Architecture

### New Files

| Path | Purpose |
|---|---|
| `skills/devops-setup/SKILL.md` | Full setup skill for DevOps/Cloud Engineers |
| `skills/design-setup/SKILL.md` | Full setup skill for UI/UX Designers |

### Modified Files

| Path | Change |
|---|---|
| `skills/onboarding/SKILL.md` | Add options 7 & 8, two new "Not sure" questions, two new dispatch routes |
| `skills/coding-setup/SKILL.md` | Add Step 5 (Optional Skills) before completion summary |
| `skills/research-setup/SKILL.md` | Add Optional Skills step (scientific-skills, d3js) |
| `.claude-plugin/plugin.json` | Register devops-setup and design-setup |

---

## devops-setup Skill

### Context Questions (one at a time)

1. Cloud Provider: AWS / GCP / Azure / On-Prem / Mixed
2. Container orchestration: Kubernetes / Docker Compose / both / none
3. IaC tool: Terraform / Pulumi / CloudFormation / Ansible / none
4. CI/CD platform: GitHub Actions / GitLab CI / Jenkins / CircleCI / other

### Generated Artifacts

**CLAUDE.md**
```markdown
# Claude Instructions — DevOps / Cloud

## Infrastructure Context
Cloud: [Q1] | Orchestration: [Q2] | IaC: [Q3] | CI/CD: [Q4]

## Guidelines
- Never apply destructive infrastructure changes (destroy, delete, scale-to-zero) without explicit user confirmation
- Always plan before apply: show `terraform plan` / `pulumi preview` output before executing
- Tag all cloud resources consistently; flag untagged resources
- Treat secrets and credentials as out-of-scope — never hardcode, always reference secret managers
- For Kubernetes: prefer declarative manifests over kubectl imperative commands
- Validate IaC configs before committing (tflint, checkov, or equivalent)
```

**AGENTS.md**
```markdown
# Agent Roles

## infra-planner
Plans infrastructure changes. Runs plan/preview commands. Never applies changes directly. Returns a diff summary for human review.

## infra-applier
Applies approved infrastructure changes. Confirms with user before any destructive operation. Writes a post-apply summary.

## security-reviewer
Reviews IaC configs for security issues (open security groups, public S3 buckets, missing encryption). Returns findings with severity.
```

**`.claude/settings.json`** — permissions based on detected stack:
- Always: `Bash(git *)`
- Terraform: `Bash(terraform *)`, `Bash(tflint *)`, `Bash(checkov *)`
- Pulumi: `Bash(pulumi *)`
- Kubernetes: `Bash(kubectl *)`, `Bash(helm *)`
- AWS: `Bash(aws *)`
- GCP: `Bash(gcloud *)`
- Azure: `Bash(az *)`
- Docker: `Bash(docker *)`, `Bash(docker-compose *)`

**`.gitignore`**
```
*.tfstate
*.tfstate.backup
.terraform/
.pulumi/
*.pem
*.key
.env
.env.*
.DS_Store
.claude/settings.local.json
```

### Superpowers (Optional)

Same pattern as existing skills — offer A/B/C (Plugin Marketplace / GitHub / Skip).

### Optional Skills Step

Ask after context questions, before artifact generation:

> "Möchtest du zusätzliche Community-Skills installieren?
>
> A) kubernetes-ops — Kubernetes best practices and manifest patterns
> B) aws-cloud-patterns — AWS architecture patterns and CDK helpers
> C) ci-cd-skill — CI/CD pipeline templates for GitHub Actions / GitLab CI
> D) All of the above
> E) None
>
> (Multiple selections via comma, e.g. 'A, C')"

Install via `/plugin install <skill>@claude-plugins-official`. On failure: warn + continue.

### Completion Summary

```
✓ DevOps / Cloud setup complete!

Files created:
  CLAUDE.md             — infrastructure context + safety guidelines
  AGENTS.md             — infra-planner, infra-applier, security-reviewer
  .claude/settings.json — tool permissions for [stack]
  .gitignore            — IaC state files and secrets

Optional skills: [installed list or "none selected"]

Next steps:
  Start a new Claude session and describe your infrastructure task.
  Example: "Review this Terraform plan for security issues"
  Example: "Generate a GitHub Actions workflow for this Node.js project"
```

---

## design-setup Skill

### Context Questions (one at a time)

1. Primary design tool: Figma / Sketch / Adobe XD / other
2. Frontend stack: React + Tailwind / Vue / Vanilla CSS / other / none (design-only)
3. Workflow: Hand off designs → generate code / Review existing code / both
4. Accessibility standard: WCAG AA / WCAG AAA / no specific standard

### Generated Artifacts

**CLAUDE.md**
```markdown
# Claude Instructions — UI/UX Design

## Design Context
Tool: [Q1] | Stack: [Q2] | Workflow: [Q3] | Accessibility: [Q4]

## Guidelines
- Avoid generic AI aesthetics — no default gray cards, no rounded-everything, no "modern minimal" clichés
- Always check WCAG [Q4] compliance for color contrast and interactive elements
- When generating UI code: component-first, no inline styles, use design tokens where available
- When reviewing designs: flag accessibility issues before aesthetic feedback
- Prefer existing component library patterns over custom implementations
- For Figma handoff: extract exact spacing, typography, and color tokens from provided specs
```

**`.claude/settings.json`**
```json
{
  "permissions": {
    "allow": ["Bash(git *)"]
  }
}
```
Extend based on stack (npm/npx for React/Vue, etc.)

**`.gitignore`**
```
*.fig
*.sketch
node_modules/
dist/
.DS_Store
.claude/settings.local.json
```

### Superpowers (Optional)

Same offer pattern as other skills.

### Optional Skills Step

> "Möchtest du zusätzliche Community-Skills installieren?
>
> A) frontend-design (official Anthropic) — avoids AI-generic UI, bold design decisions (277k installs, strongly recommended)
> B) web-artifacts-builder — build complex HTML artifacts with React + Tailwind + shadcn/ui
> C) accessibility-skill — automated WCAG audit and remediation guidance
> D) All of the above
> E) None"

### Completion Summary

```
✓ UI/UX Design setup complete!

Files created:
  CLAUDE.md             — design context, accessibility standard, UI guidelines
  .claude/settings.json — tool permissions
  .gitignore            — design file rules

Optional skills: [installed list or "none selected"]

Next steps:
  Start a new Claude session and paste a design description or Figma spec.
  Example: "Build this component from the attached design spec"
  Example: "Review this UI for WCAG AA compliance"
```

---

## Optional Skills Step for Existing Setups

### coding-setup (insert as Step 5, before current Step 5 → becomes Step 6)

```
## Step 5: Optional Skills

"Would you like to install additional community skills?

A) frontend-design (official Anthropic) — avoids AI-generic UI (277k installs)
B) mcp-builder — create MCP servers for external API integrations
C) webapp-testing — Playwright-based UI testing
D) security-suite — Trail of Bits CodeQL/Semgrep analysis
E) All of the above
F) None

(Multiple selections, e.g. 'A, C')"
```

Install via `/plugin install`. On failure: warn + continue. Add installed skills list to Completion Summary.

### research-setup (insert as new step before completion summary)

```
"Would you like to install additional community skills?

A) claude-scientific-skills — NumPy, SciPy, pandas, matplotlib helpers
B) claude-d3js-skill — data visualization patterns and D3.js helpers
C) Both
D) None"
```

---

## onboarding/SKILL.md Changes

### Step 3 — Options List

Add after option 5 (Content Creation), before "Not sure":

```
6. DevOps / Cloud Engineering — CI/CD, Kubernetes, Terraform, cloud providers
7. UI/UX Design              — component design, Figma handoff, accessibility
```

Renumber "Not sure" to option 8.

### Step 4 — Not Sure Flow

Add after existing question 3:

4. "Do you manage infrastructure, CI/CD pipelines, or cloud resources?" → yes → DevOps Setup
5. "Do you primarily work with UI designs, components, or frontend interfaces?" → yes → Design Setup

### Step 5 — Dispatch

Add routing:
- DevOps Setup → invoke `devops-setup` skill
- UI/UX Design Setup → invoke `design-setup` skill

---

## plugin.json Changes

Add to `skills[]`:
```json
{ "name": "devops-setup", "path": "skills/devops-setup/SKILL.md" },
{ "name": "design-setup", "path": "skills/design-setup/SKILL.md" }
```

Add to `commands[]`:
```json
{ "name": "devops-setup", "skill": "devops-setup" },
{ "name": "design-setup", "skill": "design-setup" }
```

---

## Invariants Preserved

- No silent CLAUDE.md overwrite — extend with new section if existing
- Failed external skill installs → warn + continue, never block setup
- Language detection from handoff context
- Onboarding steps back after dispatch
- All SKILL.md content in English; runtime responses in detected language
