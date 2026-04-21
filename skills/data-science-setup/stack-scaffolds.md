> Consumed by data-science-setup/SKILL.md at Step 4. Do not invoke directly.

# Stack Scaffolds — Data Science Setup

## pyproject.toml (only if Q1 includes Python and `uv_available: true`)

Emit a minimal scaffold and instruct the user to run the install commands. Do NOT run `uv add` automatically without explicit user consent.

```toml
[project]
name = "your-project"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = []

[tool.uv]
dev-dependencies = []
```

## uv add commands by answer

Print the recommended install commands based on answers:

- Always: `uv add pandas polars numpy pyarrow scikit-learn`
- If Q2 = Jupyter: `uv add jupyterlab ipykernel`
- If Q2 = marimo: `uv add marimo`
- If Q3 = PyTorch: `uv add torch` (remind the user to check https://pytorch.org for the correct CUDA build)
- If Q3 = JAX: `uv add "jax[cpu]"` (or `jax[cuda12]` with extra index URL — link to JAX install docs)
- If Q3 = TensorFlow: `uv add tensorflow`
- If Q4 = MLflow: `uv add mlflow`
- If Q4 = Weights & Biases: `uv add wandb`
- If Q4 = DVC: `uv add dvc`
- If Q6 = yes (notebook hygiene): `uv add --dev nbqa ruff black nbstripout pre-commit`

If `uv_available: false`, print these as a manual checklist instead of executing them.

## .claude/settings.json — base permissions

Create or extend `.claude/settings.json` with stack-appropriate permissions:

```json
{
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(uv *)",
      "Bash(python *)",
      "Bash(pytest *)",
      "Bash(jupyter *)",
      "Bash(nbqa *)",
      "Bash(nbstripout *)",
      "Bash(pre-commit *)"
    ]
  }
}
```

## .claude/settings.json — per-answer adaptations

Adapt based on answers:
- Q2 = marimo → add `"Bash(marimo *)"`
- Q4 = MLflow → add `"Bash(mlflow *)"`
- Q4 = Weights & Biases → add `"Bash(wandb *)"`
- Q4 = DVC → add `"Bash(dvc *)"`
- Q1 = R → add `"Bash(Rscript *)"`, `"Bash(R *)"` instead of the uv/python entries
- Q1 = Julia → add `"Bash(julia *)"` instead

If an existing `settings.json` exists, merge into its `permissions.allow` list (dedupe) rather than overwriting.

## Directory scaffold (only if Q5 = yes)

Create:

```
data/
  raw/.gitkeep
  interim/.gitkeep
  processed/.gitkeep
models/.gitkeep
notebooks/.gitkeep
```

Add a `data/README.md` explaining the three-folder convention (raw = immutable, interim = cleaned, processed = model-ready).
