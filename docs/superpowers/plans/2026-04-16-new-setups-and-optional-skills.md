# New Setup Skills & Optional Skills Integration — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `devops-setup` and `design-setup` skills, add a configurable "Optional Skills" step to `coding-setup` and `research-setup`, and wire everything into the onboarding orchestrator.

**Architecture:** Each skill is a standalone `SKILL.md` markdown file following a fixed pattern: language detection → optional Superpowers install → context questions → optional community skills → artifact generation → completion summary. No shared code — each file is fully self-contained. Modifications to existing skills insert a new step without changing surrounding structure.

**Tech Stack:** Markdown (SKILL.md), JSON (plugin.json). No runtime code. Verification via `grep` pattern checks.

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `skills/devops-setup/SKILL.md` | Full setup skill for DevOps/Cloud Engineers |
| Create | `skills/design-setup/SKILL.md` | Full setup skill for UI/UX Designers |
| Modify | `skills/coding-setup/SKILL.md` | Insert Step 5 (Optional Skills) before current Step 5 |
| Modify | `skills/research-setup/SKILL.md` | Insert Optional Skills step before Step 4 (Completion Summary) |
| Modify | `skills/onboarding/SKILL.md` | Add options 6 & 7, new "Not sure" questions 4 & 5, dispatch routes |
| Modify | `.claude-plugin/plugin.json` | Register two new skills and commands |
| Modify | `README.md` | Add two rows to the "What's Inside" table |

---

## Task 1: Create `skills/devops-setup/SKILL.md`

**Files:**
- Create: `skills/devops-setup/SKILL.md`

**Spec reference:** `docs/superpowers/specs/2026-04-16-new-setups-and-optional-skills-design.md` → section "devops-setup Skill"

- [ ] **Step 1: Verify the directory does not exist yet**

```bash
ls skills/devops-setup 2>/dev/null && echo "EXISTS" || echo "OK to create"
```
Expected: `OK to create`

- [ ] **Step 2: Create the skill file**

Create `skills/devops-setup/SKILL.md` with the following exact content:

```markdown
---
name: devops-setup
description: Set up Claude for DevOps and cloud engineering — configures your cloud provider, IaC tool, and CI/CD platform so Claude helps with infrastructure planning, safe applies, and security reviews.
---

# DevOps / Cloud Engineering Setup

This skill configures Claude for DevOps and infrastructure work.

**Language:** Use `detected_language` from handoff context, or detect from the user's first message and use it throughout.

**Existing CLAUDE.md:** If `existing_claude_md: true` in handoff context, or if CLAUDE.md exists in the filesystem, extend it by appending a new section (`## Claude Onboarding Agent — DevOps Setup`) rather than overwriting.

## Step 1: Superpowers (Optional)

> "**Superpowers** is a free Claude Code skills library used by 94,000+ people. Its planning and subagent skills work well for infrastructure tasks that need careful step-by-step execution.
>
> Would you like to install it?
> **A) Yes — Plugin Marketplace** (one command, recommended)
> **B) Yes — GitHub** (clone from github.com/obra/superpowers)
> **C) Skip for now**"

If A or B: install using the chosen method.

**If Plugin Marketplace:** `/plugin install superpowers@claude-plugins-official`
**If GitHub:** `git clone https://github.com/obra/superpowers ~/.claude/plugins/superpowers`

Verify installation. On failure: warn and set `superpowers_installed: false`. Continue regardless.

## Step 2: Context Questions

Ask one at a time:

1. "Which cloud provider do you primarily use?
   A) AWS
   B) GCP
   C) Azure
   D) On-Prem / Self-hosted
   E) Mixed / Multiple"

2. "Which container orchestration do you use?
   A) Kubernetes
   B) Docker Compose
   C) Both
   D) None"

3. "Which IaC tool do you use?
   A) Terraform
   B) Pulumi
   C) CloudFormation
   D) Ansible
   E) None"

4. "Which CI/CD platform do you use?
   A) GitHub Actions
   B) GitLab CI
   C) Jenkins
   D) CircleCI
   E) Other — please specify"

## Step 3: Optional Community Skills

> "Would you like to install additional community skills?
>
> A) kubernetes-ops — Kubernetes best practices and manifest patterns
> B) aws-cloud-patterns — AWS architecture patterns and CDK helpers
> C) ci-cd-skill — CI/CD pipeline templates for GitHub Actions / GitLab CI
> D) All of the above
> E) None
>
> (Multiple selections via comma, e.g. 'A, C')"

For each selected skill, run: `/plugin install <skill>@claude-plugins-official`

On failure for any skill: warn clearly ("⚠ Could not install [skill] — skipping. Install manually later.") and continue. Never block the setup.

Store the list of successfully installed optional skills as `optional_skills_installed`.

## Step 4: Generate Artifacts

### CLAUDE.md

```markdown
# Claude Instructions — DevOps / Cloud

## Infrastructure Context
Cloud: [Q1 answer] | Orchestration: [Q2 answer] | IaC: [Q3 answer] | CI/CD: [Q4 answer]

## Guidelines
- Never apply destructive infrastructure changes (destroy, delete, scale-to-zero) without explicit user confirmation
- Always plan before apply: show `terraform plan` / `pulumi preview` output before executing
- Tag all cloud resources consistently; flag untagged resources in reviews
- Treat secrets and credentials as out-of-scope — never hardcode, always reference secret managers
- For Kubernetes: prefer declarative manifests over kubectl imperative commands
- Validate IaC configs before committing (tflint, checkov, or equivalent)

[Include ONLY if superpowers_installed is true]
## Superpowers
Superpowers is installed. For multi-step infrastructure tasks, use superpowers:writing-plans to plan changes before applying, and superpowers:subagent-driven-development to execute safely step-by-step.
```

Adapt based on answers:
- Terraform answer → reference `terraform plan` in guidelines
- Pulumi answer → reference `pulumi preview`
- If neither → omit plan/preview line

### AGENTS.md

```markdown
# Agent Roles

## infra-planner
Plans infrastructure changes. Runs plan/preview commands. Never applies changes directly. Returns a diff summary for human review.

## infra-applier
Applies approved infrastructure changes. Confirms with user before any destructive operation (destroy, delete, scale-to-zero). Writes a post-apply summary.

## security-reviewer
Reviews IaC configs for security issues (open security groups, public S3 buckets, missing encryption). Returns findings with severity (critical/major/minor).
```

### .claude/settings.json

Build the `allow` list based on answers:

Always include: `"Bash(git *)"`

Add based on Q3 (IaC):
- Terraform → `"Bash(terraform *)"`, `"Bash(tflint *)"`, `"Bash(checkov *)"`
- Pulumi → `"Bash(pulumi *)"`
- CloudFormation → `"Bash(aws cloudformation *)"`
- Ansible → `"Bash(ansible *)"`, `"Bash(ansible-playbook *)"`

Add based on Q2 (Orchestration):
- Kubernetes → `"Bash(kubectl *)"`, `"Bash(helm *)"`
- Docker Compose → `"Bash(docker *)"`, `"Bash(docker-compose *)"`
- Both → all four above

Add based on Q1 (Cloud):
- AWS → `"Bash(aws *)"`
- GCP → `"Bash(gcloud *)"`
- Azure → `"Bash(az *)"`

Example for Terraform + Kubernetes + AWS:
```json
{
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(terraform *)",
      "Bash(tflint *)",
      "Bash(checkov *)",
      "Bash(kubectl *)",
      "Bash(helm *)",
      "Bash(aws *)"
    ]
  }
}
```

### .gitignore

```gitignore
# IaC state files
*.tfstate
*.tfstate.backup
.terraform/
.pulumi/

# Secrets
*.pem
*.key
.env
.env.*

# OS
.DS_Store
Thumbs.db

# Claude local settings
.claude/settings.local.json
```

## Step 5: Completion Summary

```
✓ DevOps / Cloud setup complete!

Files created:
  CLAUDE.md             — infrastructure context + safety guidelines
  AGENTS.md             — infra-planner, infra-applier, security-reviewer
  .claude/settings.json — tool permissions for [stack summary]
  .gitignore            — IaC state files and secrets

External skills:
  [✓ Superpowers installed via Plugin Marketplace / GitHub]
  [skipped — install later with: /plugin install superpowers@claude-plugins-official]
  [⚠ Superpowers installation failed — install manually: https://github.com/obra/superpowers]

Optional community skills: [list of installed skills, or "none selected"]

Next steps:
  Start a new Claude session and describe your infrastructure task.
  Example: "Review this Terraform plan for security issues"
  Example: "Generate a GitHub Actions workflow for this Node.js project"
  Example: "Help me migrate this deployment to Kubernetes"
```
```

- [ ] **Step 3: Verify required sections exist**

```bash
grep -c "## Step 1\|## Step 2\|## Step 3\|## Step 4\|## Step 5" skills/devops-setup/SKILL.md
```
Expected: `5`

```bash
grep -c "infra-planner\|infra-applier\|security-reviewer" skills/devops-setup/SKILL.md
```
Expected: `3`

- [ ] **Step 4: Commit**

```bash
git add skills/devops-setup/SKILL.md
git commit -m "feat: add devops-setup skill"
```

---

## Task 2: Create `skills/design-setup/SKILL.md`

**Files:**
- Create: `skills/design-setup/SKILL.md`

**Spec reference:** `docs/superpowers/specs/2026-04-16-new-setups-and-optional-skills-design.md` → section "design-setup Skill"

- [ ] **Step 1: Verify the directory does not exist yet**

```bash
ls skills/design-setup 2>/dev/null && echo "EXISTS" || echo "OK to create"
```
Expected: `OK to create`

- [ ] **Step 2: Create the skill file**

Create `skills/design-setup/SKILL.md` with the following exact content:

```markdown
---
name: design-setup
description: Set up Claude for UI/UX design work — configures your design tool, frontend stack, and accessibility standard so Claude generates production-quality components and avoids generic AI aesthetics.
---

# UI/UX Design Setup

This skill configures Claude for UI/UX design and frontend work.

**Language:** Use `detected_language` from handoff context, or detect from the user's first message and use it throughout.

**Existing CLAUDE.md:** If `existing_claude_md: true` in handoff context, or if CLAUDE.md exists in the filesystem, extend it by appending a new section (`## Claude Onboarding Agent — Design Setup`) rather than overwriting.

## Step 1: Superpowers (Optional)

> "**Superpowers** is a free Claude Code skills library used by 94,000+ people. Its brainstorming skill is particularly useful for exploring design directions and component structures before committing to an implementation.
>
> Would you like to install it?
> **A) Yes — Plugin Marketplace** (one command, recommended)
> **B) Yes — GitHub** (clone from github.com/obra/superpowers)
> **C) Skip for now**"

If A or B: install using the chosen method.

**If Plugin Marketplace:** `/plugin install superpowers@claude-plugins-official`
**If GitHub:** `git clone https://github.com/obra/superpowers ~/.claude/plugins/superpowers`

Verify installation. On failure: warn and set `superpowers_installed: false`. Continue regardless.

## Step 2: Context Questions

Ask one at a time:

1. "Which design tool do you primarily use?
   A) Figma
   B) Sketch
   C) Adobe XD
   D) Other — please specify"

2. "What is your frontend stack?
   A) React + Tailwind CSS
   B) Vue
   C) Vanilla CSS / plain HTML
   D) Other — please specify
   E) None — I work design-only, no code"

3. "What is your primary workflow with Claude?
   A) Hand off designs → have Claude generate the code
   B) Review and improve existing UI code
   C) Both"

4. "Which accessibility standard should Claude enforce?
   A) WCAG AA (standard compliance)
   B) WCAG AAA (strict compliance)
   C) No specific standard"

## Step 3: Optional Community Skills

> "Would you like to install additional community skills?
>
> A) frontend-design (official Anthropic) — avoids AI-generic UI, makes bold design decisions (277k installs, strongly recommended)
> B) web-artifacts-builder — build complex HTML artifacts with React + Tailwind + shadcn/ui
> C) accessibility-skill — automated WCAG audit and remediation guidance
> D) All of the above
> E) None"

For each selected skill, run: `/plugin install <skill>@claude-plugins-official`

On failure: warn and continue. Store successfully installed skills as `optional_skills_installed`.

## Step 4: Generate Artifacts

### CLAUDE.md

```markdown
# Claude Instructions — UI/UX Design

## Design Context
Tool: [Q1 answer] | Stack: [Q2 answer] | Workflow: [Q3 answer] | Accessibility: [Q4 answer]

## Guidelines
- Avoid generic AI aesthetics — no default gray cards, no rounded-everything, no "modern minimal" clichés unless explicitly requested
- Always check [Q4 accessibility standard] compliance for color contrast and interactive elements
- When generating UI code: component-first, no inline styles, use design tokens where available
- When reviewing designs or code: flag accessibility issues before aesthetic feedback
- Prefer existing component library patterns over custom implementations
- For Figma handoff: extract exact spacing, typography, and color tokens from the provided specs — do not approximate
- When given a topic or feature, suggest multiple visual directions before committing to one

[Include ONLY if superpowers_installed is true]
## Superpowers
Superpowers is installed. For design exploration and component planning, use superpowers:brainstorming to compare directions before generating code.
```

Adapt based on Q2 (stack):
- React + Tailwind → add "Prefer Tailwind utility classes over custom CSS. Use shadcn/ui components where applicable."
- Vue → add "Prefer Vue SFC patterns. Use Vuetify or PrimeVue components where applicable."
- None (design-only) → omit code-specific guidelines

### AGENTS.md

```markdown
# Agent Roles

## designer
Generates UI components and layouts from design specs or descriptions. Follows the design system and accessibility standard defined in CLAUDE.md. Never introduces inline styles or undocumented design tokens.

## accessibility-auditor
Reviews UI code and designs for WCAG compliance. Returns a prioritized list of violations with remediation suggestions, ordered by severity.
```

### .claude/settings.json

Build based on Q2 (frontend stack):
- React + Tailwind or Vue → include npm/npx/node:
```json
{
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(npm *)",
      "Bash(npx *)",
      "Bash(node *)"
    ]
  }
}
```
- None (design-only) or Vanilla CSS:
```json
{
  "permissions": {
    "allow": ["Bash(git *)"]
  }
}
```

### .gitignore

```gitignore
# Design files
*.fig
*.sketch

# Frontend build
node_modules/
dist/
.next/

# OS
.DS_Store
Thumbs.db

# Claude local settings
.claude/settings.local.json
```

## Step 5: Completion Summary

```
✓ UI/UX Design setup complete!

Files created:
  CLAUDE.md             — design context, accessibility standard ([Q4]), UI guidelines
  AGENTS.md             — designer and accessibility-auditor role definitions
  .claude/settings.json — tool permissions for [stack]
  .gitignore            — design file and build rules

External skills:
  [✓ Superpowers installed via Plugin Marketplace / GitHub]
  [skipped — install later with: /plugin install superpowers@claude-plugins-official]
  [⚠ Superpowers installation failed — install manually: https://github.com/obra/superpowers]

Optional community skills: [list of installed skills, or "none selected"]

Next steps:
  Start a new Claude session and paste a design description or Figma spec.
  Example: "Build this card component: [description or paste Figma spec]"
  Example: "Review this UI for WCAG AA compliance"
  Example: "Redesign this form — it feels too generic"
```
```

- [ ] **Step 3: Verify required sections exist**

```bash
grep -c "## Step 1\|## Step 2\|## Step 3\|## Step 4\|## Step 5" skills/design-setup/SKILL.md
```
Expected: `5`

```bash
grep -c "designer\|accessibility-auditor" skills/design-setup/SKILL.md
```
Expected: `2`

- [ ] **Step 4: Commit**

```bash
git add skills/design-setup/SKILL.md
git commit -m "feat: add design-setup skill"
```

---

## Task 3: Add Optional Skills Step to `coding-setup`

**Files:**
- Modify: `skills/coding-setup/SKILL.md`

The current file has 5 steps. Step 5 is the Completion Summary. We insert a new Step 5 (Optional Skills) and renumber the old Step 5 to Step 6.

- [ ] **Step 1: Verify current step count**

```bash
grep -c "^## Step" skills/coding-setup/SKILL.md
```
Expected: `5` (Steps 1–4 plus "## Step 5: Completion Summary")

```bash
grep "^## Step" skills/coding-setup/SKILL.md
```
Expected: five lines — Steps 1, 2, 3, 4, and "Step 5: Completion Summary".

- [ ] **Step 2: Insert the Optional Skills step**

In `skills/coding-setup/SKILL.md`, find the line `## Step 5: Completion Summary` and insert the following block immediately before it:

```markdown
## Step 5: Optional Community Skills

> "Would you like to install additional community skills?
>
> A) frontend-design (official Anthropic) — avoids AI-generic UI, bold design decisions (277k installs)
> B) mcp-builder — create MCP servers for external API integrations
> C) webapp-testing — Playwright-based UI testing
> D) security-suite — Trail of Bits CodeQL/Semgrep analysis
> E) All of the above
> F) None
>
> (Multiple selections via comma, e.g. 'A, C')"

For each selected skill, run: `/plugin install <skill>@claude-plugins-official`

On failure for any skill: warn clearly ("⚠ Could not install [skill] — skipping. Install manually later.") and continue. Never block the setup.

Add the list of successfully installed optional skills to the Completion Summary under a new line: `Optional community skills: [list or "none selected"]`

```

Then rename the existing `## Step 5: Completion Summary` heading to `## Step 6: Completion Summary`.

- [ ] **Step 3: Verify the insertion**

```bash
grep "^## Step" skills/coding-setup/SKILL.md
```
Expected: Steps 1, 2, 3, 4, 5 (Optional Community Skills), 6 (Completion Summary)

```bash
grep "frontend-design\|mcp-builder\|webapp-testing\|security-suite" skills/coding-setup/SKILL.md
```
Expected: at least one line per skill name (4 distinct names present in the inserted block).

- [ ] **Step 4: Commit**

```bash
git add skills/coding-setup/SKILL.md
git commit -m "feat: add optional community skills step to coding-setup"
```

---

## Task 4: Add Optional Skills Step to `research-setup`

**Files:**
- Modify: `skills/research-setup/SKILL.md`

The current file has Steps 1-3 plus a Step 4 (Completion Summary). We insert a new Step 4 (Optional Skills) and renumber Completion Summary to Step 5.

- [ ] **Step 1: Verify current structure**

```bash
grep "^## Step" skills/research-setup/SKILL.md
```
Expected: Steps 1, 2, 3, then "Step 4: Completion Summary"

- [ ] **Step 2: Insert the Optional Skills step**

In `skills/research-setup/SKILL.md`, find the line `## Step 4: Completion Summary` and insert the following block immediately before it:

```markdown
## Step 4: Optional Community Skills

> "Would you like to install additional community skills?
>
> A) claude-scientific-skills — NumPy, SciPy, pandas, matplotlib helpers for scientific Python
> B) claude-d3js-skill — data visualization patterns and D3.js helpers
> C) All of the above
> D) None
>
> (Multiple selections via comma, e.g. 'A, B')"

For each selected skill, run: `/plugin install <skill>@claude-plugins-official`

On failure: warn and continue. Add successfully installed skills to the Completion Summary under: `Optional community skills: [list or "none selected"]`

```

Then rename `## Step 4: Completion Summary` to `## Step 5: Completion Summary`.

- [ ] **Step 3: Verify the insertion**

```bash
grep "^## Step" skills/research-setup/SKILL.md
```
Expected: Steps 1, 2, 3, 4 (Optional Community Skills), 5 (Completion Summary)

```bash
grep -c "claude-scientific-skills\|claude-d3js-skill" skills/research-setup/SKILL.md
```
Expected: `2`

- [ ] **Step 4: Commit**

```bash
git add skills/research-setup/SKILL.md
git commit -m "feat: add optional community skills step to research-setup"
```

---

## Task 5: Update `skills/onboarding/SKILL.md`

**Files:**
- Modify: `skills/onboarding/SKILL.md`

Three changes: (A) expand the options list in Step 3, (B) add two questions to the "Not sure" flow in Step 4, (C) add two dispatch routes in Step 5.

**Spec reference:** `docs/superpowers/specs/2026-04-16-new-setups-and-optional-skills-design.md` → section "onboarding/SKILL.md Changes"

- [ ] **Step 1: Verify current Step 3 options count**

```bash
grep -c "^[0-9]\." skills/onboarding/SKILL.md
```
Note the current count (expect ~6 lines with numbered options across Steps 3 and 4).

- [ ] **Step 2: Expand Step 3 options list**

In `skills/onboarding/SKILL.md`, find this block inside Step 3:

```
5. Content Creation — YouTube, social media, newsletters
6. Not sure — help me decide
```

Replace it with:

```
5. Content Creation — YouTube, social media, newsletters
6. DevOps / Cloud Engineering — CI/CD, Kubernetes, Terraform, cloud providers
7. UI/UX Design — component design, Figma handoff, accessibility
8. Not sure — help me decide
```

Also update the example format block above the options (if it shows a numbered list ending at 5 or 6) to match the new numbering.

- [ ] **Step 3: Add two questions to the "Not sure" flow (Step 4)**

Find the end of the existing three "Not sure" questions:

```
3. "Do you mostly work with documents, emails, reports, or presentations?" → yes → recommend Office Setup
```

Add after it:

```
4. "Do you manage infrastructure, CI/CD pipelines, or cloud resources?" → yes → recommend DevOps Setup
5. "Do you primarily work with UI designs, components, or frontend interfaces?" → yes → recommend Design Setup
```

Find the fallback paragraph (currently: "If none match after 3 questions, present all 5 options again...") and update it to:

```
If none match after 5 questions, present all 7 options (1–7, excluding "Not sure") with one-line descriptions and ask the user to pick a number.
```

- [ ] **Step 4: Add dispatch routes in Step 5**

Find the skill routing block:

```
- Content Creator → invoke `content-creator-setup` skill
```

Add after it:

```
- DevOps Setup → invoke `devops-setup` skill
- UI/UX Design Setup → invoke `design-setup` skill
```

- [ ] **Step 5: Verify all changes**

```bash
grep "devops-setup\|design-setup" skills/onboarding/SKILL.md
```
Expected: at least 4 lines — one in option 6/7 in Step 3, one in question 4/5 in Step 4, and two in Step 5 dispatch routing.

```bash
grep -c "DevOps / Cloud Engineering\|UI/UX Design" skills/onboarding/SKILL.md
```
Expected: `2` (one for each new option label in Step 3).

- [ ] **Step 6: Commit**

```bash
git add skills/onboarding/SKILL.md
git commit -m "feat: add devops and design options to onboarding orchestrator"
```

---

## Task 6: Update `.claude-plugin/plugin.json`

**Files:**
- Modify: `.claude-plugin/plugin.json`

- [ ] **Step 1: Add new skills to `skills[]` array**

Note: the existing `skills[]` array uses bare strings (e.g., `"skills/coding-setup"`), not objects. The spec showed objects as an illustrative format — use bare strings to match the existing array convention.

In `.claude-plugin/plugin.json`, find:

```json
    "skills/content-creator-setup"
  ],
```

Replace with:

```json
    "skills/content-creator-setup",
    "skills/devops-setup",
    "skills/design-setup"
  ],
```

- [ ] **Step 2: Add new commands to `commands[]` array**

Find:

```json
    "content-creator-setup"
  ]
```

Replace with:

```json
    "content-creator-setup",
    "devops-setup",
    "design-setup"
  ]
```

- [ ] **Step 3: Verify valid JSON and new entries**

```bash
python3 -c "import json; d=json.load(open('.claude-plugin/plugin.json')); print('skills:', d['skills']); print('commands:', d['commands'])"
```
Expected: lists contain `skills/devops-setup`, `skills/design-setup`, `devops-setup`, `design-setup`

- [ ] **Step 4: Commit**

```bash
git add .claude-plugin/plugin.json
git commit -m "feat: register devops-setup and design-setup in plugin.json"
```

---

## Task 7: Update `README.md`

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Locate the What's Inside table**

```bash
grep -n "content-creator-setup" README.md | head -5
```
Note the line number of the content-creator-setup row.

- [ ] **Step 2: Add two new rows**

Find the line:

```
| `/content-creator-setup` | Configures brand voice, platform preferences, and audience context |
```

Add after it:

```
| `/devops-setup` | Configures cloud provider, IaC tool, and CI/CD platform — generates safe infrastructure workflow guidelines and agent roles |
| `/design-setup` | Configures design tool, frontend stack, and accessibility standard — generates UI guidelines and avoids generic AI aesthetics |
```

- [ ] **Step 3: Verify the table**

```bash
grep -c "devops-setup\|design-setup" README.md
```
Expected: `2`

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: add devops-setup and design-setup to README What's Inside table"
```

---

## Final Verification

- [ ] **Verify all 7 files are changed or created**

```bash
git log --oneline -7
```
Expected: 7 commits covering all tasks above.

- [ ] **Verify new skill directories exist**

```bash
ls skills/
```
Expected: `coding-setup  content-creator-setup  design-setup  devops-setup  knowledge-base-builder  office-setup  onboarding  research-setup`

- [ ] **Verify plugin.json has 8 skills**

```bash
python3 -c "import json; d=json.load(open('.claude-plugin/plugin.json')); print(len(d['skills']), 'skills')"
```
Expected: `8 skills`

- [ ] **Verify onboarding routes to all 7 setups**

```bash
grep "invoke" skills/onboarding/SKILL.md
```
Expected: 7 lines (one per setup skill).
