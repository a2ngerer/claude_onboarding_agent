> Consumed by data-science-setup/SKILL.md at Step 4. Do not invoke directly.

# Gitignore — Data Science Setup

Append a delimited block at the end of the user's `.gitignore`. If the marker block already exists, replace it.

```gitignore
# onboarding-agent: data-science — start
# Raw and processed data (only if Q5 = yes)
data/raw/*
!data/raw/.gitkeep
data/interim/*
!data/interim/.gitkeep
data/processed/*
!data/processed/.gitkeep

# Notebook checkpoints and local state
.ipynb_checkpoints/
*.nbconvert.ipynb
.jupyter/

# Experiment artifacts
mlruns/
wandb/
.dvc/cache/
.dvc/tmp/

# Model artifacts (re-generable — keep model cards, not weights)
models/**/*.pt
models/**/*.bin
models/**/*.onnx
models/**/*.joblib
models/**/*.pkl

# Python
__pycache__/
.venv/
*.pyc
dist/
.env

# Claude local settings
.claude/settings.local.json
# onboarding-agent: data-science — end
```
