> Consumed by data-science-setup/SKILL.md at Step 4. Do not invoke directly.

# Gitignore — Data Science Setup

Append a delimited block at the end of the user's `.gitignore`. If the marker block already exists, replace it.

The block is assembled from the data-science-specific lines below plus the canonical Python block from `skills/_shared/gitignore-python.md` and the common block from `skills/_shared/gitignore-common.md`. Do NOT duplicate Python patterns inline — read them from the shared helper.

Data-science-specific lines (inside the marker block):

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

# ... (read skills/_shared/gitignore-python.md and inline its Python block here)
# ... (read skills/_shared/gitignore-common.md and inline its block here)
# onboarding-agent: data-science — end
```
