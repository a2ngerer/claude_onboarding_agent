# Python .gitignore patterns (shared)

> Consumed by `coding-setup` (Python stack path) and `data-science-setup` (via its own `gitignore-block.md`). Do not invoke directly.

Canonical Python ignore patterns. Every consumer skill that emits a Python
`.gitignore` must source these lines from here instead of re-listing them
inline. Non-Python-specific lines (`.env`, `.DS_Store`, `.claude/settings.local.json`)
live in `gitignore-common.md`.

```gitignore
# Python
__pycache__/
*.pyc
*.pyo
*.pyd
.venv/
venv/
.Python
build/
dist/
*.egg-info/
.pytest_cache/
.mypy_cache/
.ruff_cache/
.coverage
htmlcov/
```
