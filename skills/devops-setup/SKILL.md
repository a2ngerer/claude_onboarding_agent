---
name: devops-setup
description: Set up Claude for DevOps and cloud engineering — configures your cloud provider, IaC tool, and CI/CD platform so Claude helps with infrastructure planning, safe applies, and security reviews.
---

# DevOps / Cloud Engineering Setup

This skill configures Claude for DevOps and infrastructure work.

**Language:** Use `detected_language` from handoff context, or detect from the user's first message and use it throughout.

**Existing CLAUDE.md:** If `existing_claude_md: true` in handoff context, or if CLAUDE.md exists in the filesystem, DO NOT overwrite it. Append a new delimited section at the end of the file:

```
<!-- onboarding-agent:start setup=devops skill=devops-setup section=claude-md -->
## Claude Onboarding Agent — DevOps Setup
...generated content...
<!-- onboarding-agent:end -->
```

If the delimited block already exists from a previous run, replace only the content between the markers; leave the rest untouched. Wrap generated `.gitignore` entries in `# onboarding-agent: devops — start` / `— end` markers so `/upgrade-setup` can refresh them non-destructively.

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

### Optional: plan-before-apply hook

Only ask if Q3 (IaC) ≠ "None". Otherwise skip — there is nothing to guard.

Ask ONCE (adapt to detected language):

> "Install the plan-before-apply guard? This registers a Claude Code PreToolUse hook that intercepts `Bash` tool calls and, if the command is `<iac-tool> apply` / `deploy` without a preceding plan/preview, injects a reminder for Claude to run plan first. It never blocks — it only reminds. (yes / no)"

Default on empty input: `yes`.

On `no`: set `devops_hook_emitted: false` and skip the rest of this subsection.

On `yes`:

1. Write the guard script content into `hook_entries[0].script_source`. The script:
   - Reads the tool-call JSON from stdin.
   - Extracts `.tool_input.command` via `jq`.
   - If the command string matches `terraform apply`, `pulumi up`, `kubectl apply`, `aws cloudformation deploy`, or `az deployment ... create`, emits a JSON object with `hookSpecificOutput.hookEventName = "PreToolUse"` and `hookSpecificOutput.additionalContext` reminding Claude to run the corresponding plan/preview first.
   - Never emits `permissionDecision: deny`. Only `additionalContext`.
   - Silent (exit 0, no output) on any other command.

   Exact script body:

   ```bash
   #!/usr/bin/env bash
   # Generated by claude-onboarding-agent (skill: devops-setup)
   # Purpose: remind Claude to plan/preview before an IaC apply.
   # Safe to delete — Claude Code will continue without the hook.

   set -u

   INPUT=$(cat)
   CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
   [ -z "$CMD" ] && exit 0

   emit() {
     jq -cn --arg ctx "$1" \
       '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $ctx}}'
   }

   case "$CMD" in
     *"terraform apply"*)
       emit "About to run \`terraform apply\`. Confirm you have run \`terraform plan\` against the same config and reviewed the diff. If not, run \`terraform plan\` first and paste the plan summary before applying."
       ;;
     *"pulumi up"*)
       emit "About to run \`pulumi up\`. Confirm you have run \`pulumi preview\` and reviewed the diff. If not, run \`pulumi preview\` first."
       ;;
     *"kubectl apply"*)
       emit "About to run \`kubectl apply\`. Confirm the manifest matches the intended change — consider \`kubectl diff -f <manifest>\` first, especially on production clusters."
       ;;
     *"aws cloudformation deploy"*)
       emit "About to run \`aws cloudformation deploy\`. Confirm a change-set review has happened — consider \`aws cloudformation deploy --no-execute-changeset\` first."
       ;;
     *"az deployment"*"create"*)
       emit "About to run \`az deployment create\`. Consider \`az deployment <scope> what-if\` first to preview the change."
       ;;
   esac

   exit 0
   ```

2. Set the hook spec (the helper writes `"_plugin": "claude-onboarding-agent"` and `"_skill": "devops-setup"` into the emitted entry):

   ```
   hook_entries = [
     {
       event: "PreToolUse",
       matcher: "Bash",
       command: "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/devops-plan-before-apply.sh\"",
       script_name: "devops-plan-before-apply.sh",
       script_source: <the bash block above>
     }
   ]
   skill_slug = "devops-setup"
   ```

3. Read `skills/_shared/emit-hook.md` and follow every step H1–H7 with the inputs above.

4. Capture `hooks_emitted_count`, `hooks_script_files`, `hooks_write_skipped` for the completion summary. Set `devops_hook_emitted: true` on success, `false` on skip or write-skipped.

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
  CLAUDE.md                     — infrastructure context + safety guidelines
  AGENTS.md                     — infra-planner, infra-applier, security-reviewer
  .claude/settings.json         — tool permissions for [stack summary]
  .gitignore                    — IaC state files and secrets
  .claude/onboarding-meta.json  — setup marker for /upgrade-setup

External skills:
  [✓ Superpowers installed via superpowers_method (superpowers_scope)]
  [skipped — install later with: /plugin install superpowers@claude-plugins-official]
  [⚠ Superpowers installation failed — install manually: https://github.com/obra/superpowers]

Optional community skills: [list of installed skills, or "none selected"]

Hooks:
  [✓ plan-before-apply PreToolUse hook written to .claude/settings.json + .claude/hooks/devops-plan-before-apply.sh
   | — skipped per user
   | ⚠ settings.json is corrupt — entries printed above for manual paste
   | — not offered (no IaC tool selected)]

Next steps:
  Start a new Claude session and describe your infrastructure task.
  Example: "Review this Terraform plan for security issues"
  Example: "Generate a GitHub Actions workflow for this Node.js project"
  Example: "Help me migrate this deployment to Kubernetes"
  - Run `/anchors` any time to refresh the anchor-derived sections. If any section was rendered as a placeholder due to offline mode, re-run `/anchors` once you are back online.
```
