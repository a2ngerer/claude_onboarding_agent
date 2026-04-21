---
name: python-best-practices
description: Current recommended Python tooling for new and existing projects
last_updated: 2026-04-21
sources:
  - https://docs.astral.sh/uv/
  - https://docs.astral.sh/ruff/
  - https://docs.pytest.org/en/stable/
  - https://docs.python.org/3/
version: 1
---

## Package manager

- **Recommendation:** `uv` (Astral)
- **Install:** `curl -LsSf https://astral.sh/uv/install.sh | sh`
- **Why:** Replaces `pip`, `pip-tools`, `virtualenv`, and `pyenv` with one tool. Orders of magnitude faster installs, reproducible `uv.lock`.

## Linter & formatter

- **Recommendation:** `ruff` (Astral)
- **Install:** `uv add --dev ruff`
- **Why:** Single binary covers linting (replaces flake8, pylint) and formatting (replaces black, isort). ~100x faster.

## Type checker

- **Recommendation:** `ty` (Astral) for new projects; `pyright` for existing/large codebases
- **Install:** `uv add --dev ty` or `uv add --dev pyright`
- **Why:** `ty` is the modern Rust-based checker; `pyright` remains the most mature option for large codebases.

## Test runner

- **Recommendation:** `pytest`
- **Install:** `uv add --dev pytest pytest-cov`
- **Why:** De-facto standard. Parametrization, fixtures, and plugins cover every common need.

## Project layout

- **Recommendation:** `pyproject.toml` + `src/` layout
- **Init:** `uv init --package`
- **Why:** `pyproject.toml` is the standardized project metadata format (PEP 621). The `src/` layout prevents accidental imports of the uninstalled package during tests.

## Python version

- **Recommendation:** Pin with `.python-version` via `uv python pin 3.13`
- **Why:** Pinning makes the interpreter reproducible across contributors and CI.

## CI essentials

- `uv sync --frozen` (install from lockfile, fail on drift)
- `uv run ruff check . && uv run ruff format --check .`
- `uv run pytest`
