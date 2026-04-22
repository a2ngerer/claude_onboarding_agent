---
name: devops-setup
description: Set up Claude for DevOps and cloud engineering — configures your cloud provider, IaC tool, and CI/CD platform so Claude helps with infrastructure planning, safe applies, and security reviews.
---

# DevOps / Cloud Engineering Setup

This skill configures Claude for DevOps and infrastructure work.

**Handoff context:** Read `skills/_shared/consume-handoff.md` and run it with the handoff block (if any). The helper guarantees the following locals: `detected_language`, `existing_claude_md`, `inferred_use_case`, `repo_signals`, `graphify_candidate`. Use `detected_language` for all user-facing prose; generated file content stays in English.

**Existing CLAUDE.md:** If `existing_claude_md: true`, DO NOT overwrite it. Append a new delimited section at the end of the file:

```
<!-- onboarding-agent:start setup=devops skill=devops-setup section=claude-md -->
## Claude Onboarding Agent — DevOps Setup
...generated content...
<!-- onboarding-agent:end -->
```

If the delimited block already exists from a previous run, replace only the content between the markers; leave the rest untouched. Wrap generated `.gitignore` entries in `# onboarding-agent: devops — start` / `— end` markers so `/upgrade-setup` can refresh them non-destructively.

## Supporting Files

Read these on-demand at the step that invokes them. Do not read eagerly.

- `skills/_shared/consume-handoff.md` — orchestrator handoff parse + inline fallback (preamble, before Step 1)
- `rule-file-templates.md` — bodies of the `.claude/rules/*.md` files this skill generates (Step 4)

## Step 1: Install Dependencies

Read `skills/_shared/installation-protocol.md` and follow it for each dependency below.

Dependencies:
- Superpowers (optional) — description: "A free Claude Code skills library (94,000+ users). Planning and subagent skills work well for infrastructure tasks that need careful step-by-step execution." — marketplace-id: `superpowers@claude-plugins-official`, github: `https://github.com/obra/superpowers`, name: `superpowers`

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
- Terraform → reference `terraform plan` in guidelines
- Pulumi → reference `pulumi preview`
- CloudFormation → reference `aws cloudformation deploy --change-set` as the preview step
- Ansible → reference `ansible-playbook --check` as the dry-run step
- None → omit plan/preview line entirely

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
- Mixed / Multiple → all three: `"Bash(aws *)"`, `"Bash(gcloud *)"`, `"Bash(az *)"`

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

### .claude/rules/infra-safety.md

Read `rule-file-templates.md` and write its `infra-safety` section to `.claude/rules/infra-safety.md`. Skip the write if the file already exists and log `Skipped .claude/rules/infra-safety.md (already exists)`.

This rule is emitted on every run (not gated behind a question): the pre-apply pause principle applies regardless of which IaC tool — if any — the user selected, and it guards against wrapper scripts and ad-hoc `kubectl`/`helm` commands that are not covered by Q3.

Also add a pointer line under the `## Guidelines` section of the CLAUDE.md block above:

```
- Pre-apply pause rules for any IaC mutation: `.claude/rules/infra-safety.md`
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

## Step 5: Write Upgrade Metadata

Set `setup_slug: devops`, `skill_slug: devops-setup`. Resolve `plugin_version` from the plugin's own `plugin.json`. Then follow `skills/_shared/write-meta.md` to create or merge `./.claude/onboarding-meta.json`.

## Step 6: Render Anchor Sections

Read `skills/_shared/anchor-mapping.md`. Locate the row for `setup_type: devops`. For each anchor slug in that row:

1. Call `skills/_shared/render-anchor-section.md` with:
   - `setup_type: devops`
   - `skill_slug: devops-setup`
   - `anchor_slug: <slug>`
   - `target_file: ./CLAUDE.md`
   - `fallback_content: <embedded fallback from skills/anchors/SKILL.md for that slug>`
2. If a `./AGENTS.md` file was generated earlier in this skill, repeat the call with `target_file: ./AGENTS.md`.

Do not fail if any single `render-anchor-section.md` call returns `placeholder`. Collect rendered / placeholder slugs for the completion summary.

## Step 7: Completion Summary

```
✓ DevOps / Cloud setup complete!

Files created:
  CLAUDE.md                        — infrastructure context + safety guidelines
  AGENTS.md                        — infra-planner, infra-applier, security-reviewer
  .claude/rules/infra-safety.md    — pre-apply pause rules (tool-agnostic) [created | skipped — already existed]
  .claude/settings.json            — tool permissions for [stack summary]
  .gitignore                       — IaC state files and secrets
  .claude/onboarding-meta.json     — setup marker for /upgrade-setup

External skills:
  [✓ Superpowers installed via superpowers_method (superpowers_scope)]
  [skipped — install later with: /plugin install superpowers@claude-plugins-official]
  [⚠ Superpowers installation failed — install manually: https://github.com/obra/superpowers]

Optional community skills: [list of installed skills, or "none selected"]

Next steps:
  Start a new Claude session and describe your infrastructure task.
  Example: "Review this Terraform plan for security issues"
  Example: "Generate a GitHub Actions workflow for this Node.js project"
  Example: "Help me migrate this deployment to Kubernetes"
  - Run `/anchors` any time to refresh the anchor-derived sections. If any section was rendered as a placeholder due to offline mode, re-run `/anchors` once you are back online.
```
