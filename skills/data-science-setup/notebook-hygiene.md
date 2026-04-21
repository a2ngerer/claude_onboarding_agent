> Consumed by data-science-setup/SKILL.md at Step 4. Do not invoke directly.

# Notebook Hygiene — Data Science Setup

## .pre-commit-config.yaml (only if Q6 = yes)

Emit a `.pre-commit-config.yaml` scaffold and instruct the user to run `pre-commit install` once:

```yaml
repos:
  - repo: https://github.com/kynan/nbstripout
    rev: 0.7.1
    hooks:
      - id: nbstripout
  - repo: https://github.com/nbQA-dev/nbQA
    rev: 1.8.5
    hooks:
      - id: nbqa-ruff
      - id: nbqa-black
```

If `pre-commit` is not installed, print: "Run `uv add --dev pre-commit && uv run pre-commit install` to activate the hooks."
