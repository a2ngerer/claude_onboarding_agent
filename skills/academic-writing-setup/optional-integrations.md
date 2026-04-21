> Consumed by academic-writing-setup/SKILL.md at Step 4. Do not invoke directly.

# Optional Integrations — Academic Writing Setup

## .pre-commit-config.yaml (chktex + vale)

If `chktex_available` or `vale_available` is true, OR if the user wants these enabled regardless, emit the following scaffold. Do NOT install anything automatically — print it as instructions.

```yaml
# Optional writing-quality hooks. Activate with: pre-commit install
repos:
  - repo: local
    hooks:
      - id: chktex
        name: chktex (LaTeX linter)
        entry: chktex -q -n1 -n3 -n8 -n24 -n25
        language: system
        files: \.tex$
        # Skip if chktex is not installed; the hook will fail loudly rather than silently.
      - id: vale
        name: vale (prose linter)
        entry: vale --minAlertLevel=warning
        language: system
        files: \.(tex|typ|md)$
```

Additionally print:

- If `chktex_available` is false: "⚠ `chktex` not detected — install it via your TeX distribution (it ships with TeX Live and MacTeX)."
- If `vale_available` is false: "⚠ `vale` not detected — install from https://vale.sh/docs/vale-cli/installation/ (Homebrew: `brew install vale`). A minimal `.vale.ini` is not generated here; run `vale sync` after picking a style package such as `write-good` or `Microsoft`."

If any helper ever needs Python (e.g. `pygmentize` for the LaTeX `minted` package), recommend installing via `uv tool run pygmentize` rather than `pip install Pygments`.

## Overleaf + Git bridge (only if Q3 = B)

Print these instructions; do not automate:

```
Overleaf pushes and pulls through a standard Git remote.

1. In Overleaf, open the project → Menu → Git → copy the HTTPS URL.
2. In this repo:
     git remote add overleaf <url>
     git fetch overleaf
     git merge overleaf/master --allow-unrelated-histories
3. Generate an Overleaf Git token (Account Settings → Git Integration) and cache it in your OS keychain.
4. Treat Overleaf as a secondary remote: push to GitHub first, then to Overleaf. Resolve conflicts locally.
5. Keep `bib/references.bib` authoritative on your machine (Better BibTeX auto-export). Do not edit references inside Overleaf.
```

## Template pointer (only if Q2 = A or B)

Add a short note to the completion summary (do not generate a template file):

- Thesis (Q2 = A): "University-specific thesis templates are usually supplied by your institution. Drop the template files into the project root; the generated `sections/` / `bib/` / `figures/` layout is compatible with most templates. Common examples: TUM, ETH, MIT, LaTeX `classicthesis`."
- Paper (Q2 = B): "Common venue templates: IEEE (`IEEEtran.cls`), ACM (`acmart.cls`), Springer (`svjour3.cls`), Elsevier (`elsarticle.cls`). Drop the class file into the project root and replace `\documentclass{article}` in `main.tex` accordingly."

## Knowledge-base bridge

If the user mentions they already ran `knowledge-base-builder` (or a `wiki/` or `notes/` folder exists), tell them: "Claude can read your existing Obsidian vault / wiki notes as research input while drafting — point to them in `.claude/rules/writing-style.md` or by prefixing prompts with the relevant note path."
