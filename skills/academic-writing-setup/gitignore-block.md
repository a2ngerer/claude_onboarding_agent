> Consumed by academic-writing-setup/SKILL.md at Step 4. Do not invoke directly.

# Gitignore — Academic Writing Setup

Append a delimited block at the end of the user's `.gitignore`. If the marker block already exists, replace only the content between the markers.

```gitignore
# onboarding-agent: academic-writing — start
# LaTeX build artifacts
*.aux
*.bbl
*.bcf
*.blg
*.fdb_latexmk
*.fls
*.log
*.out
*.run.xml
*.synctex.gz
*.toc
*.lof
*.lot
*.nav
*.snm
*.vrb
_minted-*/
pdf-build/

# Typst build artifacts
*.typ.pdf

# Editor / OS noise
.DS_Store
Thumbs.db

# Claude local settings
.claude/settings.local.json
# onboarding-agent: academic-writing — end
```

Note: the compiled manuscript PDF (`main.pdf` / similar) is intentionally NOT ignored by default — many supervisors want the built artifact in git. If the user prefers to ignore it, they can add `main.pdf` manually.
