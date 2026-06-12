> Consumed by data-science-setup/SKILL.md at Step 4. Do not invoke directly.

# Notebook Hygiene — Data Science Setup

## .pre-commit-config.yaml (only if Q6 = yes)

Emit a `.pre-commit-config.yaml` scaffold and instruct the user to run `pre-commit install` once:

```yaml
repos:
  - repo: https://github.com/kynan/nbstripout
    rev: ""  # run: pre-commit autoupdate, or check https://github.com/kynan/nbstripout/releases
    hooks:
      - id: nbstripout
  - repo: https://github.com/nbQA-dev/nbQA
    rev: ""  # run: pre-commit autoupdate, or check https://github.com/nbQA-dev/nbQA/releases
    hooks:
      - id: nbqa-ruff
      - id: nbqa-black
```

After writing this file, run `pre-commit autoupdate` to populate the `rev` fields with the latest stable tags.

If `pre-commit` is not installed, print: "Run `uv add --dev pre-commit && uv run pre-commit install` to activate the hooks."
