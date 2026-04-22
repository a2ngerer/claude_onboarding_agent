> Consumed by devops-setup/SKILL.md at Step 4. Do not invoke directly.

# Rule File Templates — DevOps / Cloud Setup

## infra-safety

```markdown
# Infrastructure Safety — Pre-Apply Pause

## Principle
Any command that applies, deploys, or otherwise mutates real infrastructure is a high-impact action. Before Claude runs such a command, it must pause, summarize what will change, and obtain explicit user confirmation. This rule is tool-agnostic: it applies to every IaC tool and every wrapper script that ultimately invokes one.

## What counts as an "infrastructure apply"
An infrastructure apply is any command that sends a change plan to a real environment — cloud, cluster, on-prem, or managed platform. Examples (non-exhaustive):

- `terraform apply`, `terraform destroy`
- `pulumi up`, `pulumi destroy`
- `aws cloudformation deploy`, `aws cloudformation create-stack`, `aws cloudformation update-stack`
- `ansible-playbook <playbook>` (without `--check`)
- `kubectl apply`, `kubectl delete`, `kubectl replace`, `kubectl patch`, `kubectl rollout`
- `helm install`, `helm upgrade`, `helm uninstall`, `helm rollback`
- `az deployment <scope> create`, `az deployment <scope> what-if` followed by a real create
- `bicep deployment create`, `az bicep build` followed by a real deployment
- `cdk deploy`, `cdk destroy`
- `kubectl apply -f` applied via a Crossplane Composition / Claim, `crossplane beta trace`
- Any project-specific wrapper (`make deploy`, `./scripts/apply.sh`, custom Go/Python deployment binaries) that ends in one of the above

If a command is not in this list but its effect is to mutate live infrastructure, treat it as an apply.

## Required procedure before any apply
1. **Identify the tool and the target environment.** State which IaC tool will run and which environment it will touch (account, subscription, cluster, project, stage). If the environment is unclear, ask before running.
2. **Produce or read a plan.** Run the tool's plan / preview / dry-run / what-if / diff equivalent first. Examples: `terraform plan`, `pulumi preview`, `ansible-playbook --check`, `kubectl diff`, `helm diff upgrade`, `aws cloudformation deploy --no-execute-changeset`, `az deployment <scope> what-if`, `cdk diff`. If the tool has no preview mode, say so explicitly instead of skipping the step.
3. **Summarize the planned change.** Write a short summary: what is being created, updated, replaced, or destroyed. Call out resource replacements and deletions explicitly — those are the dangerous cases.
4. **List affected resources.** If the plan output enumerates resources, reproduce the list (or the count plus the destructive subset). If it does not, note that the blast radius cannot be determined from the plan alone.
5. **Request explicit confirmation.** Ask the user to confirm before running the apply command. Wait for an unambiguous "yes", "apply", "proceed", or equivalent. Do not interpret silence or a generic "ok" as consent for a destructive change.
6. **Run the apply.** Only after confirmation. Stream the output; do not swallow errors.
7. **Post-apply check.** After the command finishes, report success or failure, list newly created or destroyed resources when known, and flag any drift, retries, or partial applies.

## Hard rules
- Never run an apply before the pause-and-confirm step, even if the user has confirmed a similar change earlier in the session. Each apply is its own confirmation.
- Never batch multiple applies into one "yes". One apply per confirmation.
- Never bypass the pause by wrapping the apply in a shell pipeline, background job, or `&&` chain.
- Never auto-approve with `-auto-approve`, `--yes`, `--force`, or equivalent flags unless the user explicitly instructs it for this specific run.
- Destructive verbs (`destroy`, `delete`, `replace`, `scale-to-zero`, `drop`, `remove`) always require an extra, explicit confirmation — even if the user pre-approved the session.
- If the plan cannot be produced (network, auth, tool missing), do not fall back to a direct apply. Stop and report the blocker.

## When the user pushes back
If the user asks to skip the pause ("just apply it"), state this rule exists, ask once whether they really want to bypass it, and — only if they confirm — run the apply. Do not make bypass the new default for the rest of the session.
```
